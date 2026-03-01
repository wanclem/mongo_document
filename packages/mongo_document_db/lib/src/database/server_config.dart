part of '../../mongo_document_db.dart';

class ServerConfig {
  String host;
  int port;
  bool isSecure;
  Duration connectTimeout;
  Duration? socketTimeout;
  Duration? waitQueueTimeout;
  Duration? maxConnectionIdleTime;
  Duration? maxConnectionLifeTime;
  bool tlsAllowInvalidCertificates;
  Uint8List? tlsCAFileContent;
  Uint8List? tlsCertificateKeyFileContent;
  String? tlsCertificateKeyFilePassword;

  String? userName;
  String? password;

  bool isAuthenticated = false;
  ClientMetadata? clientMetadata;
  bool loadBalanced;
  int maxPoolSize;
  int minPoolSize;
  int maxConnecting;

  ServerConfig(
      {this.host = '127.0.0.1',
      this.port = Db.mongoDefaultPort,
      bool? isSecure,
      Duration? connectTimeout,
      this.socketTimeout,
      this.waitQueueTimeout,
      this.maxConnectionIdleTime,
      this.maxConnectionLifeTime,
      bool? tlsAllowInvalidCertificates,
      this.tlsCAFileContent,
      this.tlsCertificateKeyFileContent,
      this.tlsCertificateKeyFilePassword,
      this.clientMetadata,
      this.loadBalanced = false,
      this.maxPoolSize = 4,
      this.minPoolSize = 1,
      this.maxConnecting = 2})
      : isSecure = isSecure ?? false,
        connectTimeout = connectTimeout ?? const Duration(seconds: 5),
        tlsAllowInvalidCertificates = tlsAllowInvalidCertificates ?? false;

  ServerConfig.clone(ServerConfig other)
      : host = other.host,
        port = other.port,
        isSecure = other.isSecure,
        connectTimeout = other.connectTimeout,
        socketTimeout = other.socketTimeout,
        waitQueueTimeout = other.waitQueueTimeout,
        maxConnectionIdleTime = other.maxConnectionIdleTime,
        maxConnectionLifeTime = other.maxConnectionLifeTime,
        tlsAllowInvalidCertificates = other.tlsAllowInvalidCertificates,
        tlsCAFileContent = other.tlsCAFileContent,
        tlsCertificateKeyFileContent = other.tlsCertificateKeyFileContent,
        tlsCertificateKeyFilePassword = other.tlsCertificateKeyFilePassword,
        userName = other.userName,
        password = other.password,
        clientMetadata = other.clientMetadata,
        loadBalanced = other.loadBalanced,
        maxPoolSize = other.maxPoolSize,
        minPoolSize = other.minPoolSize,
        maxConnecting = other.maxConnecting;
  String get hostUrl => '$host:${port.toString()}';
}
