import 'package:mongo_document_db/mongo_document_db.dart';
import 'package:test/test.dart';

void main() {
  test('server config exposes pool settings with safe defaults', () {
    var config = ServerConfig();

    expect(config.maxPoolSize, equals(4));
    expect(config.minPoolSize, equals(1));
    expect(config.maxConnecting, equals(2));
    expect(config.waitQueueTimeout, isNull);
    expect(config.maxConnectionIdleTime, isNull);
    expect(config.maxConnectionLifeTime, isNull);
  });

  test('server config clone copies pool and transport settings', () {
    var source = ServerConfig(
      host: 'mongo.local',
      port: 27018,
      isSecure: true,
      connectTimeout: const Duration(seconds: 7),
      socketTimeout: const Duration(seconds: 3),
      waitQueueTimeout: const Duration(seconds: 4),
      maxConnectionIdleTime: const Duration(minutes: 2),
      maxConnectionLifeTime: const Duration(minutes: 5),
      maxPoolSize: 12,
      minPoolSize: 3,
      maxConnecting: 4,
    )
      ..userName = 'user'
      ..password = 'pass';

    var clone = ServerConfig.clone(source);

    expect(clone.host, equals(source.host));
    expect(clone.port, equals(source.port));
    expect(clone.isSecure, isTrue);
    expect(clone.connectTimeout, equals(source.connectTimeout));
    expect(clone.socketTimeout, equals(source.socketTimeout));
    expect(clone.waitQueueTimeout, equals(source.waitQueueTimeout));
    expect(clone.maxConnectionIdleTime, equals(source.maxConnectionIdleTime));
    expect(clone.maxConnectionLifeTime, equals(source.maxConnectionLifeTime));
    expect(clone.maxPoolSize, equals(12));
    expect(clone.minPoolSize, equals(3));
    expect(clone.maxConnecting, equals(4));
    expect(clone.userName, equals('user'));
    expect(clone.password, equals('pass'));
    expect(clone.isAuthenticated, isFalse);
  });
}
