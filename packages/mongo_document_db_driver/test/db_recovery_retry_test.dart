import 'dart:async';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'package:mongo_document_db_driver/src/database/commands/base/command_operation.dart';
import 'package:mongo_document_db_driver/src/database/commands/base/operation_base.dart';
import 'package:mongo_document_db_driver/src/database/cursor/modern_cursor.dart';
import 'package:mongo_document_db_driver/src/database/message/mongo_modern_message.dart';
import 'package:test/test.dart';

void main() {
  group('Db recovery retries', () {
    late Db db;
    late _ScriptedConnectionManager manager;

    setUp(() {
      db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      db.databaseName = 'test-mongo-dart';
      db.debugSetState(State.open);
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

    test(
      'read command operations keep retrying until recovery succeeds',
      () async {
        var connection = _ScriptedConnection(
          manager,
          modernFailuresRemaining: 2,
        );
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
      },
    );

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

    test('moderately slow CRUD reads are allowed up to 3 seconds', () async {
      var connection = _ScriptedConnection(
        manager,
        modernDelay: const Duration(milliseconds: 1600),
      );
      manager.bind(connection);

      var result = await CommandOperation(
        db,
        <String, Object>{},
        command: <String, Object>{'ping': 1},
      ).execute();

      expect(result['ok'], equals(1.0));
      expect(connection.modernAttempts, equals(1));
    });

    test(
      'modern reads recover when a pooled socket loses authentication',
      () async {
        var staleConnection = _ScriptedConnection(
          manager,
          modernAuthRequiredFailuresRemaining: 1,
        );
        var recoveredConnection = _ScriptedConnection(manager)..isMaster = true;
        manager.bind(staleConnection);
        manager.promotedConnection = recoveredConnection;
        manager.promoteOnRefreshTopology = true;

        var result = await CommandOperation(
          db,
          <String, Object>{},
          command: <String, Object>{'ping': 1},
        ).execute();

        expect(result['ok'], equals(1.0));
        expect(staleConnection.connected, isFalse);
        expect(staleConnection.serverConfig.isAuthenticated, isFalse);
        expect(staleConnection.modernAttempts, equals(1));
        expect(recoveredConnection.modernAttempts, equals(1));
        expect(manager.refreshTopologyCount, equals(1));
      },
    );

    test(
      'write command operations keep conservative single replay behavior',
      () async {
        var connection = _ScriptedConnection(
          manager,
          modernFailuresRemaining: 2,
        );
        manager.bind(connection);

        var operation = CommandOperation(
          db,
          <String, Object>{},
          command: <String, Object>{
            'insert': 'widgets',
            'documents': <Map<String, dynamic>>[
              <String, dynamic>{'_id': 1},
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
      },
    );

    test('stale stepped-down primary is not reused for legacy reads', () async {
      var stalePrimary = _ScriptedConnection(manager);
      var promotedPrimary = _ScriptedConnection(manager)..isMaster = true;
      manager.bind(stalePrimary);
      stalePrimary.isMaster = false;
      manager.promotedConnection = promotedPrimary;
      manager.promoteOnWaitForMaster = true;

      expect(db.isConnected, isFalse);

      var reply = await db.queryMessage(DbCommand.createIsMasterCommand(db));

      expect(reply.documents, isNotNull);
      expect(reply.documents!.single['ok'], equals(1.0));
      expect(manager.waitForMasterCount, equals(1));
      expect(stalePrimary.queryAttempts, equals(0));
      expect(promotedPrimary.queryAttempts, equals(1));
    });

    test(
      'stale stepped-down primary is not reused for modern commands',
      () async {
        var stalePrimary = _ScriptedConnection(manager);
        var promotedPrimary = _ScriptedConnection(manager)..isMaster = true;
        manager.bind(stalePrimary);
        stalePrimary.isMaster = false;
        manager.promotedConnection = promotedPrimary;
        manager.promoteOnWaitForMaster = true;

        var result = await CommandOperation(
          db,
          <String, Object>{},
          command: <String, Object>{'ping': 1},
        ).execute();

        expect(result['ok'], equals(1.0));
        expect(manager.waitForMasterCount, equals(1));
        expect(stalePrimary.modernAttempts, equals(0));
        expect(promotedPrimary.modernAttempts, equals(1));
      },
    );
  });

  group('ConnectionManager pool hardening', () {
    test('addConnection seeds the pool up to minPoolSize', () async {
      var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      var manager = ConnectionManager(db);
      addTearDown(() async {
        await manager.close();
      });

      var connection = manager.addConnection(
        ServerConfig(
          host: '127.0.0.1',
          port: 1,
          maxPoolSize: 5,
          minPoolSize: 3,
          maxConnecting: 4,
        ),
      );

      expect(
        manager.debugConnectionCountForHost(connection.serverConfig.hostUrl),
        equals(3),
      );
    });

    test('replaces failed pool slots instead of shrinking capacity', () async {
      var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      var manager = ConnectionManager(db);
      db.debugAttachConnectionManager(manager);
      addTearDown(() async {
        await manager.close();
      });

      var connection = _ScriptedConnection(
        manager,
        config: ServerConfig(
          host: '127.0.0.1',
          port: 1,
          maxPoolSize: 4,
          minPoolSize: 1,
          maxConnecting: 4,
        ),
      );
      manager.debugAddConnection(connection);

      expect(manager.debugHostContainsConnection(connection), isTrue);

      await manager.handleSocketError(
        connection,
        const ConnectionException(
          'connection closed: Socket closed by remote host.',
        ),
      );

      expect(manager.debugHostContainsConnection(connection), isFalse);
      expect(
        manager.debugConnectionCountForHost(connection.serverConfig.hostUrl),
        equals(1),
      );
    });

    test(
      'scales a busy host to maxPoolSize without artificial throttling',
      () async {
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
        manager.selectOperationalConnection(requireAuthentication: true);

        expect(
          manager.debugConnectionCountForHost(connection.serverConfig.hostUrl),
          equals(4),
        );
      },
    );

    test(
      'keeps multiple authenticated primary sockets warm by default',
      () async {
        var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
        var manager = ConnectionManager(db);
        addTearDown(() async {
          await manager.close();
        });

        var connection = _ScriptedConnection(
          manager,
          config: ServerConfig(
            host: '127.0.0.1',
            port: 1,
            connectTimeout: const Duration(milliseconds: 5),
            maxPoolSize: 4,
            maxConnecting: 4,
            maxInFlightRequests: 1,
          ),
        );
        manager.debugAddConnection(connection);
        manager.debugSetMasterConnection(connection);

        expect(
          manager.debugConnectionCountForHost(connection.serverConfig.hostUrl),
          equals(1),
        );

        manager.selectOperationalConnection(requireAuthentication: true);

        expect(
          manager.debugConnectionCountForHost(connection.serverConfig.hostUrl),
          equals(3),
        );
      },
    );

    test(
      'rotates across equally idle primary sockets instead of pinning one',
      () async {
        var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
        var manager = ConnectionManager(db);
        addTearDown(() async {
          await manager.close();
        });

        var first = _ScriptedConnection(
          manager,
          config: ServerConfig(
            host: '127.0.0.1',
            port: 1,
            maxPoolSize: 2,
            maxConnecting: 2,
            maxInFlightRequests: 1,
          ),
        );
        var second = _ScriptedConnection(
          manager,
          config: ServerConfig(
            host: '127.0.0.1',
            port: 1,
            maxPoolSize: 2,
            maxConnecting: 2,
            maxInFlightRequests: 1,
          ),
        );

        manager.debugAddConnection(first);
        manager.debugAddConnection(second);
        manager.debugSetMasterConnection(first);

        expect(
          manager.selectOperationalConnection(requireAuthentication: true),
          same(first),
        );
        expect(
          manager.selectOperationalConnection(requireAuthentication: true),
          same(second),
        );
        expect(
          manager.selectOperationalConnection(requireAuthentication: true),
          same(first),
        );
      },
    );
  });

  group('Connection wait queue timeout', () {
    test('queued operations fail fast before socket timeout elapses', () async {
      var serverSocket = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      Socket? serverSideSocket;
      final serverSideReady = Completer<void>();
      serverSocket.listen((socket) {
        serverSideSocket = socket;
        socket.listen((_) {});
        if (!serverSideReady.isCompleted) {
          serverSideReady.complete();
        }
      });

      late Socket clientSocket;
      Connection? connection;
      addTearDown(() async {
        try {
          await connection?.close();
        } catch (_) {}
        await serverSideSocket?.close();
        await serverSocket.close();
      });

      clientSocket = await Socket.connect(
        serverSocket.address,
        serverSocket.port,
      );
      await serverSideReady.future;

      var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      var manager = ConnectionManager(db);
      connection =
          Connection(
              manager,
              ServerConfig(
                host: '127.0.0.1',
                port: serverSocket.port,
                maxInFlightRequests: 1,
                waitQueueTimeout: const Duration(milliseconds: 50),
                socketTimeout: const Duration(seconds: 1),
              ),
            )
            ..socket = clientSocket
            ..connected = true
            ..serverConfig.isAuthenticated = true;

      var inFlightQuery = connection.query(DbCommand.createIsMasterCommand(db));

      await expectLater(
        connection.query(DbCommand.createIsMasterCommand(db)),
        throwsA(
          isA<ConnectionException>().having(
            (error) => error.message,
            'message',
            contains('wait queue timed out'),
          ),
        ),
      );
      var inFlightFailure = expectLater(
        inFlightQuery,
        throwsA(isA<ConnectionException>()),
      );
      await connection.close();
      await inFlightFailure;
    });
  });

  group('ConnectionManager open startup', () {
    test('open returns once the primary is ready', () async {
      var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      db.databaseName = 'test-mongo-dart';
      var manager = ConnectionManager(db);
      db.debugAttachConnectionManager(manager);
      addTearDown(() async {
        await manager.close();
      });

      var primary = _OpenProbeConnection(
        manager,
        isPrimaryOnHello: true,
        connectDelay: const Duration(milliseconds: 15),
        helloDelay: const Duration(milliseconds: 15),
        serverStatusDelay: const Duration(milliseconds: 250),
        config: ServerConfig(
          host: 'primary.example.test',
          port: 27017,
          maxPoolSize: 1,
          minPoolSize: 1,
          maxConnecting: 1,
        ),
      );
      var secondary = _OpenProbeConnection(
        manager,
        isPrimaryOnHello: false,
        connectDelay: const Duration(milliseconds: 250),
        helloDelay: const Duration(milliseconds: 15),
        config: ServerConfig(
          host: 'secondary.example.test',
          port: 27018,
          maxPoolSize: 1,
          minPoolSize: 1,
          maxConnecting: 1,
        ),
      );
      manager.debugAddConnection(primary);
      manager.debugAddConnection(secondary);

      var stopwatch = Stopwatch()..start();
      await manager.open(WriteConcern.acknowledged);
      stopwatch.stop();

      expect(db.state, equals(State.open));
      expect(manager.masterConnection, same(primary));
      expect(stopwatch.elapsedMilliseconds, lessThan(180));
      expect(primary.serverStatusRequests, equals(0));
      expect(secondary.helloRequests, equals(0));

      await Future.delayed(const Duration(milliseconds: 450));

      expect(primary.serverStatusRequests, equals(1));
      expect(secondary.connectCalls, greaterThanOrEqualTo(1));
      expect(secondary.helloRequests, greaterThanOrEqualTo(1));
    });

    test('slow background serverStatus does not evict the primary', () async {
      var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      db.databaseName = 'test-mongo-dart';
      var manager = ConnectionManager(db);
      db.debugAttachConnectionManager(manager);
      addTearDown(() async {
        await manager.close();
      });

      var primary = _OpenProbeConnection(
        manager,
        isPrimaryOnHello: true,
        connectDelay: const Duration(milliseconds: 15),
        helloDelay: const Duration(milliseconds: 15),
        serverStatusDelay: const Duration(milliseconds: 3500),
        config: ServerConfig(
          host: 'primary.example.test',
          port: 27017,
          maxPoolSize: 1,
          minPoolSize: 1,
          maxConnecting: 1,
        ),
      );
      manager.debugAddConnection(primary);

      await manager.open(WriteConcern.acknowledged);
      await Future.delayed(const Duration(milliseconds: 3200));

      expect(db.state, equals(State.open));
      expect(manager.masterConnection, same(primary));
      expect(primary.connected, isTrue);
      expect(primary.serverStatusRequests, equals(1));
    });
  });

  group('Long-lived cursor reads', () {
    late Db db;
    late _ScriptedConnectionManager manager;

    setUp(() {
      db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      db.databaseName = 'test-mongo-dart';
      db.debugSetState(State.open);
      manager = _ScriptedConnectionManager(db);
      db.debugAttachConnectionManager(manager);
    });

    test(
      'awaitData getMore is not force-closed by speculative timeout',
      () async {
        var connection = _ScriptedConnection(
          manager,
          getMoreDelay: const Duration(milliseconds: 1600),
          getMoreCursorId: Int64(42),
        );
        manager.bind(connection);

        var cursor = ModernCursor.fromOpenId(
          db.collection('accounts'),
          Int64(42),
          tailable: true,
          awaitData: true,
        );

        var result = await cursor.nextObject();

        expect(result, isNull);
        expect(connection.modernAttempts, equals(1));
      },
    );
  });
}

class _ScriptedConnectionManager extends ConnectionManager {
  _ScriptedConnectionManager(super.db);

  late Connection operationalConnection;
  int refreshTopologyCount = 0;
  int waitForMasterCount = 0;
  Connection? promotedConnection;
  bool promoteOnWaitForMaster = false;
  bool promoteOnRefreshTopology = false;

  void bind(Connection connection) {
    connection.isMaster = true;
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
    if (promoteOnRefreshTopology && promotedConnection != null) {
      operationalConnection = promotedConnection!;
      debugSetMasterConnection(promotedConnection);
    }
  }

  @override
  Future<Connection?> waitForMaster({required Duration timeout}) async {
    waitForMasterCount++;
    if (promoteOnWaitForMaster && promotedConnection != null) {
      operationalConnection = promotedConnection!;
      debugSetMasterConnection(promotedConnection);
    }
    return operationalConnection;
  }
}

class _ScriptedConnection extends Connection {
  _ScriptedConnection(
    ConnectionManager manager, {
    this.queryFailuresRemaining = 0,
    this.modernFailuresRemaining = 0,
    this.modernAuthRequiredFailuresRemaining = 0,
    this.modernDelay = Duration.zero,
    this.getMoreDelay = Duration.zero,
    this.getMoreCursorId,
    int pendingRequestCount = 0,
    ServerConfig? config,
  }) : _pendingRequestCount = pendingRequestCount,
       _databaseName = manager.db.databaseName ?? 'test-mongo-dart',
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
    isMaster = true;
    serverConfig.userName = 'test-user';
    serverConfig.isAuthenticated = true;
    serverCapabilities.supportsOpMsg = true;
  }

  int queryFailuresRemaining;
  int modernFailuresRemaining;
  int modernAuthRequiredFailuresRemaining;
  final Duration modernDelay;
  final Duration getMoreDelay;
  final Int64? getMoreCursorId;
  int queryAttempts = 0;
  int modernAttempts = 0;
  final int _pendingRequestCount;
  final String _databaseName;

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
        <String, dynamic>{'ok': 1.0},
      ]
      ..numberReturned = 1;
  }

  @override
  Future<MongoModernMessage> executeModernMessage(
    MongoModernMessage modernMessage,
  ) async {
    modernAttempts++;
    var command = modernMessage.sections
        .firstWhere(
          (section) =>
              section.payloadType == MongoModernMessage.basePayloadType,
        )
        .payload
        .content;
    if (command.containsKey('getMore') && getMoreCursorId != null) {
      if (getMoreDelay > Duration.zero) {
        await Future.delayed(getMoreDelay);
      }
      return MongoModernMessage(<String, Object>{
        'ok': 1.0,
        'cursor': <String, Object>{
          'id': getMoreCursorId!,
          'ns': '$_databaseName.accounts',
          'nextBatch': <Map<String, dynamic>>[],
        },
      });
    }
    if (modernAuthRequiredFailuresRemaining > 0) {
      modernAuthRequiredFailuresRemaining--;
      return MongoModernMessage(<String, Object>{
        'ok': 0.0,
        'errmsg': 'Command find requires authentication',
        'code': 13,
        'codeName': 'Unauthorized',
      });
    }
    if (modernDelay > Duration.zero) {
      await Future.delayed(modernDelay);
    }
    if (modernFailuresRemaining > 0) {
      modernFailuresRemaining--;
      throw const ConnectionException(
        'connection closed: Socket closed by remote host.',
      );
    }
    return MongoModernMessage(<String, Object>{'ok': 1.0});
  }
}

class _OpenProbeConnection extends Connection {
  _OpenProbeConnection(
    ConnectionManager manager, {
    required this.isPrimaryOnHello,
    this.connectDelay = Duration.zero,
    this.helloDelay = Duration.zero,
    this.serverStatusDelay = Duration.zero,
    ServerConfig? config,
  }) : super(
         manager,
         config ??
             ServerConfig(
               host: '127.0.0.1',
               port: 27017,
               maxPoolSize: 1,
               minPoolSize: 1,
               maxConnecting: 1,
             ),
       );

  final bool isPrimaryOnHello;
  final Duration connectDelay;
  final Duration helloDelay;
  final Duration serverStatusDelay;
  int connectCalls = 0;
  int helloRequests = 0;
  int serverStatusRequests = 0;

  @override
  Future<bool> connect() async {
    connectCalls++;
    if (connectDelay > Duration.zero) {
      await Future.delayed(connectDelay);
    }
    connected = true;
    isMaster = false;
    serverConfig.isAuthenticated = false;
    return true;
  }

  @override
  Future<MongoModernMessage> executeModernMessage(
    MongoModernMessage modernMessage,
  ) async {
    var command = modernMessage.sections
        .firstWhere(
          (section) =>
              section.payloadType == MongoModernMessage.basePayloadType,
        )
        .payload
        .content;
    if (command.containsKey('hello')) {
      helloRequests++;
      if (helloDelay > Duration.zero) {
        await Future.delayed(helloDelay);
      }
      return MongoModernMessage(_helloResponse(isPrimary: isPrimaryOnHello));
    }
    if (command.containsKey('serverStatus')) {
      serverStatusRequests++;
      if (serverStatusDelay > Duration.zero) {
        await Future.delayed(serverStatusDelay);
      }
      return MongoModernMessage(<String, Object>{
        'ok': 1.0,
        'version': '6.0.0',
        'process': 'mongod',
        'host': serverConfig.hostUrl,
      });
    }
    return MongoModernMessage(<String, Object>{'ok': 1.0});
  }

  Map<String, Object> _helloResponse({required bool isPrimary}) {
    return <String, Object>{
      'ok': 1.0,
      'isWritablePrimary': isPrimary,
      'secondary': !isPrimary,
      'localTime': DateTime.utc(2026, 1, 1),
      'logicalSessionTimeoutMinutes': 30,
      'minWireVersion': 0,
      'maxWireVersion': 17,
      'maxBsonObjectSize': 16 * 1024 * 1024,
      'maxMessageSizeBytes': 48000000,
      'maxWriteBatchSize': 100000,
    };
  }
}
