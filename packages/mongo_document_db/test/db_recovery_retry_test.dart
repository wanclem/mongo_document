import 'dart:async';

import 'package:mongo_document_db/mongo_document_db.dart';
import 'package:mongo_document_db/src/database/commands/base/command_operation.dart';
import 'package:mongo_document_db/src/database/commands/base/operation_base.dart';
import 'package:mongo_document_db/src/database/message/mongo_modern_message.dart';
import 'package:test/test.dart';

void main() {
  group('Db recovery retries', () {
    late Db db;
    late _ScriptedConnectionManager manager;

    setUp(() {
      db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      db.databaseName = 'test-mongo-dart';
      db.state = State.open;
      manager = _ScriptedConnectionManager(db);
      db.debugAttachConnectionManager(manager);
    });

    test('queryMessage keeps retrying recoverable read failures', () async {
      var connection = _ScriptedConnection(manager, queryFailuresRemaining: 2);
      manager.bind(connection);

      var reply = await db.queryMessage(DbCommand.createIsMasterCommand(db));

      expect(reply.documents, isNotNull);
      expect(reply.documents!.single['ok'], equals(1.0));
      expect(connection.queryAttempts, equals(3));
      expect(manager.refreshTopologyCount, equals(2));
      expect(manager.waitForMasterCount, equals(2));
    });

    test('read command operations keep retrying until recovery succeeds',
        () async {
      var connection = _ScriptedConnection(manager, modernFailuresRemaining: 2);
      manager.bind(connection);

      var result = await CommandOperation(
        db,
        <String, Object>{},
        command: <String, Object>{'ping': 1},
      ).execute();

      expect(result['ok'], equals(1.0));
      expect(connection.modernAttempts, equals(3));
      expect(manager.refreshTopologyCount, equals(2));
      expect(manager.waitForMasterCount, equals(2));
    });

    test('read retries stay bounded when topology remains healthy', () async {
      var connection = _ScriptedConnection(manager, modernFailuresRemaining: 5);
      manager.bind(connection);

      await expectLater(
        CommandOperation(
          db,
          <String, Object>{},
          command: <String, Object>{'ping': 1},
        ).execute(),
        throwsA(isA<ConnectionException>()),
      );

      expect(connection.modernAttempts, equals(3));
      expect(manager.refreshTopologyCount, equals(2));
      expect(manager.waitForMasterCount, equals(2));
    });

    test('write command operations keep conservative single replay behavior',
        () async {
      var connection = _ScriptedConnection(manager, modernFailuresRemaining: 2);
      manager.bind(connection);

      var operation = CommandOperation(
        db,
        <String, Object>{},
        command: <String, Object>{
          'insert': 'widgets',
          'documents': <Map<String, dynamic>>[
            <String, dynamic>{'_id': 1}
          ],
        },
        aspect: Aspect.writeOperation,
      );

      await expectLater(
        operation.execute(),
        throwsA(isA<ConnectionException>()),
      );

      expect(connection.modernAttempts, equals(2));
      expect(manager.refreshTopologyCount, equals(1));
      expect(manager.waitForMasterCount, equals(1));
    });
  });

  group('ConnectionManager provisioning throttle', () {
    test('throttles rapid-fire provisioning on a busy host', () async {
      var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      var manager = ConnectionManager(db);
      addTearDown(() async {
        await manager.close();
      });

      var connection = _ScriptedConnection(
        manager,
        pendingRequestCount: 16,
        config: ServerConfig(
          host: '127.0.0.1',
          port: 1,
          connectTimeout: const Duration(milliseconds: 5),
          maxPoolSize: 4,
          maxConnecting: 4,
          maxInFlightRequests: 16,
        ),
      );
      connection.serverConfig.userName = 'test-user';
      connection.serverConfig.isAuthenticated = true;
      connection.connected = true;

      manager.debugAddConnection(connection);
      manager.debugSetMasterConnection(connection);

      expect(
        manager.debugConnectionCountForHost(connection.serverConfig.hostUrl),
        equals(1),
      );

      manager.selectOperationalConnection(requireAuthentication: true);
      manager.selectOperationalConnection(requireAuthentication: true);

      expect(
        manager.debugConnectionCountForHost(connection.serverConfig.hostUrl),
        equals(2),
      );

      await Future<void>.delayed(const Duration(milliseconds: 140));
      manager.selectOperationalConnection(requireAuthentication: true);

      expect(
        manager.debugConnectionCountForHost(connection.serverConfig.hostUrl),
        equals(3),
      );
    });
  });
}

class _ScriptedConnectionManager extends ConnectionManager {
  _ScriptedConnectionManager(super.db);

  late Connection operationalConnection;
  int refreshTopologyCount = 0;
  int waitForMasterCount = 0;

  void bind(Connection connection) {
    operationalConnection = connection;
    debugSetMasterConnection(connection);
  }

  @override
  bool get hasAnyConnectedServer => true;

  @override
  Connection selectOperationalConnection({bool requireAuthentication = true}) {
    return operationalConnection;
  }

  @override
  Future<void> refreshTopology() async {
    refreshTopologyCount++;
  }

  @override
  Future<Connection?> waitForMaster({required Duration timeout}) async {
    waitForMasterCount++;
    return operationalConnection;
  }
}

class _ScriptedConnection extends Connection {
  _ScriptedConnection(ConnectionManager manager,
      {this.queryFailuresRemaining = 0,
      this.modernFailuresRemaining = 0,
      int pendingRequestCount = 0,
      ServerConfig? config})
      : _pendingRequestCount = pendingRequestCount,
        super(
          manager,
          config ??
              ServerConfig(
                host: '127.0.0.1',
                port: 27017,
                maxPoolSize: 6,
                maxConnecting: 4,
                maxInFlightRequests: 16,
              ),
        ) {
    connected = true;
    serverConfig.userName = 'test-user';
    serverConfig.isAuthenticated = true;
    serverCapabilities.supportsOpMsg = true;
  }

  int queryFailuresRemaining;
  int modernFailuresRemaining;
  int queryAttempts = 0;
  int modernAttempts = 0;
  final int _pendingRequestCount;

  @override
  int get pendingRequestCount => _pendingRequestCount;

  @override
  Future<MongoReplyMessage> query(MongoMessage queryMessage) async {
    queryAttempts++;
    if (queryFailuresRemaining > 0) {
      queryFailuresRemaining--;
      throw const ConnectionException(
        'connection closed: Socket closed by remote host.',
      );
    }
    return MongoReplyMessage()
      ..documents = <Map<String, dynamic>>[
        <String, dynamic>{'ok': 1.0}
      ]
      ..numberReturned = 1;
  }

  @override
  Future<MongoModernMessage> executeModernMessage(
      MongoModernMessage modernMessage) async {
    modernAttempts++;
    if (modernFailuresRemaining > 0) {
      modernFailuresRemaining--;
      throw const ConnectionException(
        'connection closed: Socket closed by remote host.',
      );
    }
    return MongoModernMessage(<String, Object>{'ok': 1.0});
  }
}
