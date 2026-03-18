import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'package:test/test.dart';

void main() {
  test('addConnection returns the pooled connection instance', () {
    var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
    var manager = ConnectionManager(db);

    var connection =
        manager.addConnection(ServerConfig(host: '127.0.0.1', port: 27017));

    expect(connection.serverConfig.host, equals('127.0.0.1'));
    expect(connection.serverConfig.port, equals(27017));
    expect(manager.hasAnyConnectedServer, isFalse);
  });

  test('connected and ready host signals track auth state', () {
    var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
    var manager = ConnectionManager(db);
    var connection =
        manager.addConnection(ServerConfig(host: '127.0.0.1', port: 27017));

    expect(manager.hasAnyConnectedServer, isFalse);
    expect(manager.hasAnyReadyServer, isFalse);

    connection.connected = true;
    expect(manager.hasAnyConnectedServer, isTrue);
    expect(manager.hasAnyReadyServer, isTrue);

    connection.serverConfig.userName = 'test-user';
    connection.serverConfig.isAuthenticated = false;
    expect(manager.hasAnyReadyServer, isFalse);

    connection.serverConfig.isAuthenticated = true;
    expect(manager.hasAnyReadyServer, isTrue);
  });
}
