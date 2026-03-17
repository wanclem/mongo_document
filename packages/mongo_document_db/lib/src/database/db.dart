part of '../../mongo_document_db.dart';

/// [WriteConcern] control the acknowledgment of write operations with various paramaters.
class WriteConcern {
  /// Denotes the Write Concern level that takes the following values
  /// ([int] or [String]):
  /// - -1 Disables all acknowledgment of write operations, and suppresses
  /// all errors, including network and socket errors.
  /// - 0: Disables basic acknowledgment of write operations, but returns
  /// information about socket exceptions and networking errors to the
  /// application.
  /// - 1: Provides acknowledgment of write operations on a standalone mongod
  /// or the primary in a replica set.
  /// - A number greater than 1: Guarantees that write operations have
  /// propagated successfully to the specified number of replica set members
  /// including the primary.
  /// - "majority": Confirms that write operations have propagated to the
  /// majority of configured replica set
  /// - A tag set: Fine-grained control over which replica set members must
  /// acknowledge a write operation
  final dynamic w;

  /// Specifies a timeout for this Write Concern in milliseconds,
  /// or infinite if equal to 0.
  final int? wtimeout;

  /// Enables or disable fsync() operation before acknowledgement of
  /// the requested write operation.
  /// If [true], wait for mongod instance to write data to disk before returning.
  final bool fsync;

  /// Enables or disable journaling of the requested write operation before
  /// acknowledgement.
  /// If [true], wait for mongod instance to write data to the on-disk journal
  /// before returning.
  final bool j;

  /// A string value indicating where the write concern originated
  /// (known as write concern provenance). The following table shows the
  /// possible values for this field and their significance:
  ///
  /// **Provenance** -  **Description**
  /// - clientSupplied
  ///   - The write concern was specified in the application.
  /// - customDefault
  ///   - The write concern originated from a custom defined default value. See setDefaultRWConcern.
  /// - getLastErrorDefaults
  ///   - The write concern originated from the replica set’s settings.getLastErrorDefaults field.
  /// - implicitDefault
  ///   - The write concern originated from the server in absence of all other write concern specifications.
  ///
  /// ** NOTE **
  ///
  /// This field is *only* set by the database when the Write concern is
  /// returned in a writeConcernError. It is **NOT** to be sent to the server
  final String? provenance;

  /// Creates a WriteConcern object
  const WriteConcern(
      {this.w,
      this.wtimeout,
      this.fsync = true,
      this.j = true,
      this.provenance});

  WriteConcern.fromMap(Map<String, Object> writeConcernMap)
      : w = writeConcernMap[keyW],
        wtimeout = writeConcernMap[keyWtimeout] as int?,
        fsync = writeConcernMap[keyFsync] as bool? ?? false,
        j = writeConcernMap[keyJ] as bool? ?? false,
        provenance = writeConcernMap[keyProvenance] as String?;

  /// No exceptions are raised, even for network issues.
  @Deprecated('No more used')
  // ignore: constant_identifier_names
  static const ERRORS_IGNORED =
      WriteConcern(w: -1, wtimeout: 0, fsync: false, j: false);

  /// Write operations that use this write concern will return as soon as the
  /// message is written to the socket.
  /// Exceptions are raised for network issues, but not server errors.
  static const unacknowledged =
      WriteConcern(w: 0, wtimeout: 0, fsync: false, j: false);

  @Deprecated('Use unacknowledged instead')
  // ignore: constant_identifier_names
  static const UNACKNOWLEDGED = unacknowledged;

  /// Write operations that use this write concern will wait for
  /// acknowledgement from the primary server before returning.
  /// Exceptions are raised for network issues, and server errors.
  static const acknowledged =
      WriteConcern(w: 1, wtimeout: 0, fsync: false, j: false);

  @Deprecated('Use acknowledged instead')
  // ignore: constant_identifier_names
  static const ACKNOWLEDGED = acknowledged;

  /// Exceptions are raised for network issues, and server errors;
  /// waits for at least 2 servers for the write operation.
  static const replicaAcknowledged =
      WriteConcern(w: 2, wtimeout: 0, fsync: false, j: false);

  @Deprecated('Use replicaAcknowledged instead')
  // ignore: constant_identifier_names
  static const REPLICA_ACKNOWLEDGED = replicaAcknowledged;

  /// Exceptions are raised for network issues, and server errors;
  /// the write operation waits for the server to flush
  /// the data to disk.
  @Deprecated('No more used')
  // ignore: constant_identifier_names
  static const FSYNCED = WriteConcern(w: 1, wtimeout: 0, fsync: true, j: false);

  /// Exceptions are raised for network issues, and server errors; the write
  /// operation waits for the server to
  /// group commit to the journal file on disk.
  static const journaled =
      WriteConcern(w: 1, wtimeout: 0, fsync: false, j: true);

  @Deprecated('Use journaled instead')
  // ignore: constant_identifier_names
  static const JOURNALED = journaled;

  /// Exceptions are raised for network issues, and server errors; waits on a
  /// majority of servers for the write operation.
  static const majority =
      WriteConcern(w: 'majority', wtimeout: 0, fsync: false, j: false);

  @Deprecated('Use majority instead')
  // ignore: constant_identifier_names
  static const MAJORITY = majority;

  /// Gets the getlasterror command for this write concern.
  Map<String, dynamic> get command {
    var map = <String, dynamic>{};
    map['getlasterror'] = 1;
    if (w != null) {
      map[keyW] = w;
    }
    if (wtimeout != null) {
      map[keyWtimeout] = wtimeout;
    }
    if (fsync) {
      map[keyFsync] = fsync;
    }
    if (j) {
      map[keyJ] = j;
    }
    return map;
  }

  /// To be used starting with journaled engines (Only Wired Tiger, Journal Only)
  /// For inMemoryEngine the J option is ignored
  ///
  /// We can use before 4.2 testing if the journal is active
  /// (in this case fsync doesn't make any sense, taken from mongodb Jira:
  /// "fsync means sync using a journal if present otherwise the datafiles")
  /// In 4.0 journal cannot be disabled on wiredTiger engine
  /// In 4.2 only wiredTiger can be used
  Map<String, Object> asMap(ServerStatus serverStatus) {
    var ret = <String, Object>{};
    if (w != null) {
      ret[keyW] = w;
    }
    if (wtimeout != null) {
      ret[keyWtimeout] = wtimeout!;
    }
    if (serverStatus.isPersistent) {
      if (j) {
        ret[keyJ] = j;
      }
      if (!j) {
        if (serverStatus.isJournaled) {
          ret[keyJ] = fsync;
        } else {
          ret[keyFsync] = fsync;
        }
      }
    }
    return ret;
  }
}

class _UriParameters {
  static const authMechanism = 'authMechanism';
  static const authSource = 'authSource';
  static const tls = 'tls';
  static const ssl = 'ssl';
  static const tlsAllowInvalidCertificates = 'tlsAllowInvalidCertificates';
  static const tlsCAFile = 'tlsCAFile';
  static const tlsCertificateKeyFile = 'tlsCertificateKeyFile';
  static const tlsCertificateKeyFilePassword = 'tlsCertificateKeyFilePassword';
  static const appName = 'appname';
  static const loadBalanced = 'loadBalanced';
  static const maxPoolSize = 'maxPoolSize';
  static const minPoolSize = 'minPoolSize';
  static const maxConnecting = 'maxConnecting';
  static const maxInFlightRequests = 'maxInFlightRequests';
  static const waitQueueTimeoutMS = 'waitQueueTimeoutMS';
  static const maxIdleTimeMS = 'maxIdleTimeMS';
  static const maxLifeTimeMS = 'maxLifeTimeMS';
  static const minHeartbeatFrequencyMS = 'minHeartbeatFrequencyMS';
  static const heartbeatFrequencyMS = 'heartbeatFrequencyMS';
  static const connectTimeoutMS = 'connectTimeoutMS';
  static const socketTimeoutMS = 'socketTimeoutMS';
  static const serverSelectionTimeoutMS = 'serverSelectionTimeoutMS';
  static const maxReconnectAttempts = 'maxReconnectAttempts';
  static const prewarmStandbyConnections = 'prewarmStandbyConnections';
}

bool _isServerCommandOk(dynamic okValue) {
  if (okValue is num) {
    return okValue.toDouble() == 1.0;
  }
  if (okValue is bool) {
    return okValue;
  }
  return okValue?.toString() == '1';
}

bool _isServerCommandNotOk(dynamic okValue) => !_isServerCommandOk(okValue);

class Db {
  static const mongoDefaultPort = 27017;
  static const _maxHealthyTopologyReadReplays = 2;
  static final Object _replayDeadlineZoneKey = Object();
  final _log = Logger('Db');
  final List<String> _uriList = <String>[];

  State state = State.init;
  String? databaseName;
  String? _debugInfo;
  Db? authSourceDb;
  ConnectionManager? _connectionManager;

  Connection? get _masterConnection => _connectionManager?._masterConnection;

  Connection get _masterConnectionVerified {
    if (state != State.open) {
      throw MongoDartError('Db is in the wrong state: $state');
    }
    return _masterConnectionVerifiedAnyState;
  }

  Connection get _masterConnectionVerifiedAnyState {
    if (_connectionManager == null) {
      throw MongoDartError('Invalid Connection manager state');
    }
    return _connectionManager!.masterConnectionVerified;
  }

  WriteConcern? _writeConcern;
  AuthenticationScheme? _authenticationScheme;
  ReadPreference readPreference = ReadPreference.primary;
  bool _lastSecure = false;
  bool _lastTlsAllowInvalidCertificates = false;
  String? _lastTlsCAFile;
  String? _lastTlsCertificateKeyFile;
  String? _lastTlsCertificateKeyFilePassword;
  bool _explicitlyClosed = false;
  Future<void>? _reconnectInProgress;
  Future<void>? _openInProgress;
  // Keep startup conservative (single socket boot), then scale out lazily
  // under concurrent load.
  int _maxPoolSize = 20;
  int _minPoolSize = 0;
  int _maxConnecting = 4;
  int _maxInFlightRequests = 1;
  Duration _waitQueueTimeout = const Duration(seconds: 15);
  Duration? _maxConnectionIdleTime;
  Duration? _maxConnectionLifeTime;
  Duration _minHeartbeatInterval = const Duration(milliseconds: 500);
  Duration _heartbeatInterval = const Duration(seconds: 10);
  Duration _serverSelectionTimeout = const Duration(seconds: 30);
  int _maxReconnectAttempts = 8;
  bool _prewarmStandbyConnections = false;
  Timer? _heartbeatTimer;
  bool _heartbeatInProgress = false;

  @override
  String toString() => 'Db($databaseName,$_debugInfo)';

  /// Db constructor expects [valid mongodb URI](https://docs.mongodb.com/manual/reference/connection-string/).
  /// For example next code points to local mongodb server on default mongodb port, database *testdb*
  ///```dart
  ///     var db = new Db('mongodb://127.0.0.1/testdb');
  ///```
  /// And that code direct to MongoLab server on 37637 port, database *testdb*, username *dart*, password *test*
  ///```dart
  ///     var db = new Db('mongodb://dart:test@ds037637-a.mongolab.com:37637/objectory_blog');
  ///```
  Db(String uriString, [this._debugInfo]) {
    if (uriString.contains(',')) {
      _uriList.addAll(splitHosts(uriString));
    } else {
      _uriList.add(uriString);
    }
  }

  Db.pool(List<String> uriList, [this._debugInfo]) {
    _uriList.addAll(uriList);
  }

  Db._authDb(this.databaseName);

  /// This method allow to create a Db object both with the Standard
  /// Connection String Format (`mongodb://`) or with the DNS Seedlist
  /// Connection Format (`mongodb+srv://`).
  /// The former has the format:
  /// mongodb://[username:password@]host1[:port1]
  ///      [,...hostN[:portN]][/[defaultauthdb][?options]]
  /// The latter is available from version 3.6. The format is:
  /// mongodb+srv://[username:password@]host1[:port1]
  ///      [/[databaseName][?options]]
  /// More info are available [here](https://docs.mongodb.com/manual/reference/connection-string/)
  ///
  /// This is an asynchronous constructor.
  /// In order to resolve the Seedlist, a call to a DNS server is needed
  /// If the DNS server is unreachable, the constructor throws an error.
  static Future<Db> create(String uriString, [String? debugInfo]) async {
    if (uriString.startsWith('mongodb://')) {
      return Db(uriString, debugInfo);
    } else if (uriString.startsWith('mongodb+srv://')) {
      var uriList = await decodeDnsSeedlist(Uri.parse(uriString));
      return Db.pool(uriList, debugInfo);
    } else {
      throw MongoDartError(
          'The only valid schemas for Db are: "mongodb" and "mongodb+srv".');
    }
  }

  WriteConcern? get writeConcern => _writeConcern;

  Connection get masterConnection => _masterConnectionVerified;
  Connection get masterConnectionAnyState => _masterConnectionVerifiedAnyState;
  ServerStatus get writeConcernServerStatus {
    var master = _masterConnection;
    if (master != null && master.connected) {
      return master.serverStatus;
    }
    var manager = _connectionManager;
    if (manager != null) {
      for (var hostPool in manager._connectionPool.values) {
        for (var connection in hostPool.connections) {
          if (connection.connected) {
            return connection.serverStatus;
          }
        }
      }
    }
    return ServerStatus();
  }

  bool get supportsOpMsg =>
      _masterConnection?.serverCapabilities.supportsOpMsg ??
      _connectionManager?.supportsOpMsg ??
      false;

  bool get supportsListCollections =>
      _masterConnection?.serverCapabilities.listCollections ??
      _connectionManager?.supportsListCollections ??
      false;

  bool get supportsListIndexes =>
      _masterConnection?.serverCapabilities.listIndexes ??
      _connectionManager?.supportsListIndexes ??
      false;

  List<String> get uriList => _uriList.toList();

  bool get prewarmStandbyConnections => _prewarmStandbyConnections;

  Future<ServerConfig> _parseUri(String uriString,
      {bool? isSecure,
      bool? tlsAllowInvalidCertificates,
      String? tlsCAFile,
      String? tlsCertificateKeyFile,
      String? tlsCertificateKeyFilePassword}) async {
    isSecure ??= false;
    tlsAllowInvalidCertificates ??= false;
    if (tlsAllowInvalidCertificates ||
        tlsCAFile != null ||
        tlsCertificateKeyFile != null) {
      isSecure = true;
    }
    var uri = Uri.parse(uriString);
    var appName = 'mongo_document_db application';
    var loadBalanced = false;
    var connectTimeout = const Duration(seconds: 5);
    Duration? socketTimeout;
    var maxPoolSize = _maxPoolSize;
    var minPoolSize = _minPoolSize;
    var maxConnecting = _maxConnecting;
    var maxInFlightRequests = _maxInFlightRequests;
    var waitQueueTimeout = _waitQueueTimeout;
    var maxConnectionIdleTime = _maxConnectionIdleTime;
    var maxConnectionLifeTime = _maxConnectionLifeTime;
    var prewarmStandbyConnections = _prewarmStandbyConnections;

    if (uri.scheme != 'mongodb') {
      throw MongoDartError('Invalid scheme in uri: $uriString ${uri.scheme}');
    }

    uri.queryParameters.forEach((String queryParam, String value) {
      var normalizedQueryParam = queryParam.toLowerCase();
      var normalizedValue = value.toLowerCase();

      if (normalizedQueryParam == _UriParameters.authMechanism.toLowerCase()) {
        selectAuthenticationMechanism(value);
      }

      if (normalizedQueryParam == _UriParameters.authSource.toLowerCase()) {
        authSourceDb = Db._authDb(value);
      }

      if ((normalizedQueryParam == _UriParameters.tls.toLowerCase() ||
              normalizedQueryParam == _UriParameters.ssl.toLowerCase()) &&
          normalizedValue == 'true') {
        isSecure = true;
      }
      if (normalizedQueryParam ==
              _UriParameters.tlsAllowInvalidCertificates.toLowerCase() &&
          normalizedValue == 'true') {
        tlsAllowInvalidCertificates = true;
        isSecure = true;
      }
      if (normalizedQueryParam == _UriParameters.tlsCAFile.toLowerCase() &&
          value.isNotEmpty) {
        tlsCAFile = value;
        isSecure = true;
      }
      if (normalizedQueryParam ==
              _UriParameters.tlsCertificateKeyFile.toLowerCase() &&
          value.isNotEmpty) {
        tlsCertificateKeyFile = value;
        isSecure = true;
      }
      if (normalizedQueryParam ==
              _UriParameters.tlsCertificateKeyFilePassword.toLowerCase() &&
          value.isNotEmpty) {
        tlsCertificateKeyFilePassword = value;
      }
      if (normalizedQueryParam == _UriParameters.appName.toLowerCase() &&
          value.isNotEmpty) {
        appName = value;
      }
      if (normalizedQueryParam == _UriParameters.loadBalanced.toLowerCase() &&
          normalizedValue == 'true') {
        loadBalanced = true;
      }
      if (normalizedQueryParam == _UriParameters.maxPoolSize.toLowerCase()) {
        var parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) {
          maxPoolSize = min(parsed, 500);
        }
      }
      if (normalizedQueryParam == _UriParameters.minPoolSize.toLowerCase()) {
        var parsed = int.tryParse(value);
        if (parsed != null && parsed >= 0) {
          minPoolSize = min(parsed, 500);
        }
      }
      if (normalizedQueryParam == _UriParameters.maxConnecting.toLowerCase()) {
        var parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) {
          maxConnecting = min(parsed, 50);
        }
      }
      if (normalizedQueryParam ==
          _UriParameters.maxInFlightRequests.toLowerCase()) {
        var parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) {
          maxInFlightRequests = min(parsed, 512);
        }
      }
      if (normalizedQueryParam ==
          _UriParameters.waitQueueTimeoutMS.toLowerCase()) {
        var parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) {
          waitQueueTimeout = Duration(milliseconds: max(parsed, 10).toInt());
        }
      }
      if (normalizedQueryParam == _UriParameters.maxIdleTimeMS.toLowerCase()) {
        var parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) {
          maxConnectionIdleTime =
              Duration(milliseconds: max(parsed, 100).toInt());
        }
      }
      if (normalizedQueryParam == _UriParameters.maxLifeTimeMS.toLowerCase()) {
        var parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) {
          maxConnectionLifeTime =
              Duration(milliseconds: max(parsed, 1000).toInt());
        }
      }
      if (normalizedQueryParam ==
          _UriParameters.minHeartbeatFrequencyMS.toLowerCase()) {
        var minHeartbeatMs = int.tryParse(value);
        if (minHeartbeatMs != null && minHeartbeatMs > 0) {
          _minHeartbeatInterval =
              Duration(milliseconds: max(minHeartbeatMs, 100).toInt());
        }
      }
      if (normalizedQueryParam ==
          _UriParameters.heartbeatFrequencyMS.toLowerCase()) {
        var heartbeatMs = int.tryParse(value);
        if (heartbeatMs != null && heartbeatMs > 0) {
          _heartbeatInterval = Duration(milliseconds: heartbeatMs.toInt());
        }
      }
      if (normalizedQueryParam ==
          _UriParameters.connectTimeoutMS.toLowerCase()) {
        var timeoutMs = int.tryParse(value);
        if (timeoutMs != null && timeoutMs > 0) {
          connectTimeout = Duration(milliseconds: max(timeoutMs, 250).toInt());
        }
      }
      if (normalizedQueryParam ==
          _UriParameters.socketTimeoutMS.toLowerCase()) {
        var timeoutMs = int.tryParse(value);
        if (timeoutMs != null && timeoutMs > 0) {
          socketTimeout = Duration(milliseconds: max(timeoutMs, 100).toInt());
        }
      }
      if (normalizedQueryParam ==
          _UriParameters.serverSelectionTimeoutMS.toLowerCase()) {
        var timeoutMs = int.tryParse(value);
        if (timeoutMs != null && timeoutMs > 0) {
          _serverSelectionTimeout =
              Duration(milliseconds: max(timeoutMs, 500).toInt());
        }
      }
      if (normalizedQueryParam ==
          _UriParameters.maxReconnectAttempts.toLowerCase()) {
        var attempts = int.tryParse(value);
        if (attempts != null && attempts > 0) {
          _maxReconnectAttempts = min(attempts, 50);
        }
      }
      if (normalizedQueryParam ==
          _UriParameters.prewarmStandbyConnections.toLowerCase()) {
        if (normalizedValue == 'true') {
          prewarmStandbyConnections = true;
        }
        if (normalizedValue == 'false') {
          prewarmStandbyConnections = false;
        }
      }
    });

    if (_heartbeatInterval < _minHeartbeatInterval) {
      _heartbeatInterval = _minHeartbeatInterval;
    }
    if (maxPoolSize < 1) {
      maxPoolSize = 1;
    }
    if (minPoolSize < 0) {
      minPoolSize = 0;
    }
    if (minPoolSize > maxPoolSize) {
      minPoolSize = maxPoolSize;
    }
    if (maxConnecting < 1) {
      maxConnecting = 1;
    }
    if (maxInFlightRequests < 1) {
      maxInFlightRequests = 1;
    }

    _maxPoolSize = maxPoolSize;
    _minPoolSize = minPoolSize;
    _maxConnecting = maxConnecting;
    _maxInFlightRequests = maxInFlightRequests;
    _waitQueueTimeout = waitQueueTimeout;
    _maxConnectionIdleTime = maxConnectionIdleTime;
    _maxConnectionLifeTime = maxConnectionLifeTime;
    _prewarmStandbyConnections = prewarmStandbyConnections;

    Uint8List? tlsCAFileContent;
    if (tlsCAFile != null) {
      tlsCAFileContent = await File(tlsCAFile!).readAsBytes();
    }
    Uint8List? tlsCertificateKeyFileContent;
    if (tlsCertificateKeyFile != null) {
      tlsCertificateKeyFileContent =
          await File(tlsCertificateKeyFile!).readAsBytes();
    }
    if (tlsCertificateKeyFilePassword != null &&
        tlsCertificateKeyFile == null) {
      throw MongoDartError('Missing tlsCertificateKeyFile parameter');
    }

    var clientMetadata = ClientMetadata(ApplicationMetadata(appName));
    var serverConfig = ServerConfig(
        host: uri.host,
        port: uri.port,
        isSecure: isSecure,
        connectTimeout: connectTimeout,
        socketTimeout: socketTimeout,
        waitQueueTimeout: waitQueueTimeout,
        maxConnectionIdleTime: maxConnectionIdleTime,
        maxConnectionLifeTime: maxConnectionLifeTime,
        tlsAllowInvalidCertificates: tlsAllowInvalidCertificates,
        tlsCAFileContent: tlsCAFileContent,
        tlsCertificateKeyFileContent: tlsCertificateKeyFileContent,
        tlsCertificateKeyFilePassword: tlsCertificateKeyFilePassword,
        clientMetadata: clientMetadata,
        loadBalanced: loadBalanced,
        maxPoolSize: maxPoolSize,
        minPoolSize: minPoolSize,
        maxConnecting: maxConnecting,
        maxInFlightRequests: maxInFlightRequests);

    if (serverConfig.port == 0) {
      serverConfig.port = mongoDefaultPort;
    }

    if (uri.userInfo.isNotEmpty) {
      var userInfo = uri.userInfo.split(':');

      if (userInfo.length != 2) {
        throw MongoDartError('Invalid format of userInfo field: $uri.userInfo');
      }

      serverConfig.userName = Uri.decodeComponent(userInfo[0]);
      serverConfig.password = Uri.decodeComponent(userInfo[1]);
    }

    if (uri.path.isNotEmpty) {
      databaseName = uri.path.replaceAll('/', '');
    }
    if (unfilled(databaseName)) {
      databaseName = 'test';
      authSourceDb ??= Db._authDb('admin');
    }

    return serverConfig;
  }

  void selectAuthenticationMechanism(String authenticationSchemeName) {
    if (authenticationSchemeName == ScramSha1Authenticator.name) {
      _authenticationScheme = AuthenticationScheme.SCRAM_SHA_1;
    } else if (authenticationSchemeName == ScramSha256Authenticator.name) {
      _authenticationScheme = AuthenticationScheme.SCRAM_SHA_256;
    } else if (authenticationSchemeName == MongoDbCRAuthenticator.name) {
      _authenticationScheme = AuthenticationScheme.MONGODB_CR;
    } else if (authenticationSchemeName == X509Authenticator.name) {
      _authenticationScheme = AuthenticationScheme.X509;
      authSourceDb = Db._authDb(r'$external');
    } else {
      throw MongoDartError('Provided authentication scheme is '
          'not supported : $authenticationSchemeName');
    }
  }

  DbCollection collection(String collectionName) {
    return DbCollection(this, collectionName);
  }

  void _startHeartbeatMonitor() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      // ignore: unawaited_futures
      _runHeartbeat();
    });
  }

  void _stopHeartbeatMonitor() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  bool _hasHealthyMaster() {
    var master = _masterConnection;
    if (master == null || !master.connected || !master.isMaster) {
      return false;
    }
    var authRequired = _authenticationScheme == AuthenticationScheme.X509 ||
        filled(master.serverConfig.userName);
    return !authRequired || master.serverConfig.isAuthenticated;
  }

  Future<bool> _tryWaitForMaster(ConnectionManager manager,
      {int maxMilliseconds = 3000}) async {
    var selected = await manager.waitForMaster(
        timeout:
            _serverSelectionProbeTimeout(maxMilliseconds: maxMilliseconds));
    if (selected == null) {
      return false;
    }
    return _hasHealthyMaster();
  }

  Future<void> _reconnectIfTopologyFullyDown(ConnectionManager? manager) async {
    if (manager != null && manager.hasAnyConnectedServer) {
      return;
    }
    await _reconnect();
  }

  Duration _operationReplayBackoff(int replayAttempt) {
    var delayMs = 50 * (1 << min(replayAttempt - 1, 4));
    return Duration(milliseconds: min(delayMs, 500).toInt());
  }

  Future<void> _recoverAfterOperationError(ConnectionManager? manager,
      {DateTime? replayDeadline}) async {
    if (state == State.open &&
        manager != null &&
        identical(_connectionManager, manager)) {
      var hasConnectedServer = manager.hasAnyConnectedServer;
      try {
        await manager.refreshTopology();
        var refreshWaitTimeout = _serverSelectionProbeTimeout(
            maxMilliseconds: 3000, deadline: replayDeadline);
        if (refreshWaitTimeout > Duration.zero) {
          await manager.waitForMaster(timeout: refreshWaitTimeout);
        }
        if (_hasHealthyMaster()) {
          return;
        }
      } catch (_) {}
      if (hasConnectedServer) {
        try {
          var promotionWaitTimeout = _serverSelectionProbeTimeout(
              maxMilliseconds: 5000, deadline: replayDeadline);
          if (promotionWaitTimeout > Duration.zero) {
            await manager.waitForMaster(timeout: promotionWaitTimeout);
          }
          if (_hasHealthyMaster()) {
            return;
          }
        } catch (_) {}
      }
    }
    if (replayDeadline != null && !DateTime.now().isBefore(replayDeadline)) {
      return;
    }
    var reconnectInProgress = _reconnectInProgress;
    if (state == State.opening && reconnectInProgress != null) {
      await reconnectInProgress;
    } else {
      await _reconnect(deadline: replayDeadline);
    }
  }

  Future<void> _runHeartbeat() async {
    if (_heartbeatInProgress || _explicitlyClosed || state != State.open) {
      return;
    }
    _heartbeatInProgress = true;
    try {
      var manager = _connectionManager;
      // Fast path: keep a healthy primary alive with a lightweight ping.
      // Avoid full topology refresh churn on every heartbeat tick.
      if (_hasHealthyMaster()) {
        if (supportsOpMsg) {
          await _runWithReconnect(() => PingCommand(this).execute(),
              allowReconnect: true);
        }
        return;
      }

      if (manager != null) {
        await manager.refreshTopology();
      }
      if (!_hasHealthyMaster()) {
        if (manager != null && await _tryWaitForMaster(manager)) {
          return;
        }
        await _reconnectIfTopologyFullyDown(manager);
        return;
      }
      if (supportsOpMsg) {
        await _runWithReconnect(() => PingCommand(this).execute(),
            allowReconnect: true);
      }
    } catch (error) {
      _log.fine(() => 'Heartbeat failed: $error');
      if (!_explicitlyClosed) {
        if (_hasHealthyMaster()) {
          return;
        }
        var manager = _connectionManager;
        if (manager != null && await _tryWaitForMaster(manager)) {
          return;
        }
        try {
          await _reconnectIfTopologyFullyDown(manager);
        } catch (reconnectError) {
          _log.fine(() => 'Heartbeat reconnect failed: $reconnectError');
        }
      }
    } finally {
      _heartbeatInProgress = false;
    }
  }

  bool _isRecoverableConnectionError(Object error) {
    if (error is ConnectionException) {
      return true;
    }
    if (error is MongoDartError) {
      var message = error.message;
      var normalized = message.toUpperCase();
      if (RecoverableErrorClassifier.isRetryableServerErrorCode(
          error.mongoCode)) {
        return true;
      }
      if (RecoverableErrorClassifier.isPrimaryRoutingFailureCodeName(
          error.errorCodeName)) {
        return true;
      }
      var master = _masterConnection;
      if ((error.mongoCode == 13 ||
              normalized.contains('NOT ALLOWED TO DO ACTION')) &&
          master != null &&
          master.connected &&
          filled(master.serverConfig.userName) &&
          !master.serverConfig.isAuthenticated) {
        return true;
      }
      return message == 'No master connection' ||
          message == 'Invalid Connection manager state' ||
          RecoverableErrorClassifier.isPrimaryRoutingFailureMessage(
              normalized) ||
          message.contains('Connection already closed') ||
          message.contains('socket has not been created') ||
          normalized.contains('STATE.OPENING') ||
          (!_explicitlyClosed && normalized.contains('STATE.CLOSED')) ||
          normalized.contains('CONNECTION MANAGER CLOSED');
    }
    if (error is Map<String, dynamic>) {
      return RecoverableErrorClassifier.isRecoverableServerErrorDocument(error);
    }
    return false;
  }

  /// Waits for an in-flight reconnect to finish when the db is transiently in
  /// [State.opening]. This avoids surfacing temporary state errors while the
  /// connection manager is being built or rebuilt.
  Future<void> waitForOpenIfReconnecting() async {
    if (_explicitlyClosed || state != State.opening) {
      return;
    }
    var openInProgress = _openInProgress;
    if (openInProgress != null) {
      await openInProgress;
      return;
    }
    var reconnectInProgress = _reconnectInProgress;
    if (reconnectInProgress != null) {
      await reconnectInProgress;
    }
  }

  Future<void> _waitForMasterSelection() async {
    if (_explicitlyClosed || state == State.closed) {
      return;
    }
    var manager = _connectionManager;
    if (manager == null) {
      return;
    }
    if (_hasHealthyMaster()) {
      return;
    }
    await manager.waitForMaster(timeout: _serverSelectionProbeTimeout());
  }

  Duration _serverSelectionProbeTimeout(
      {int maxMilliseconds = 1500, DateTime? deadline}) {
    var timeoutMs = _serverSelectionTimeout.inMilliseconds;
    if (timeoutMs <= 0) {
      timeoutMs = 100;
    }
    timeoutMs = min(timeoutMs, maxMilliseconds);
    if (deadline != null) {
      var remainingMs = deadline.difference(DateTime.now()).inMilliseconds;
      if (remainingMs <= 0) {
        return Duration.zero;
      }
      timeoutMs = min(timeoutMs, remainingMs);
    }
    if (timeoutMs <= 0) {
      return Duration.zero;
    }
    if (deadline == null || timeoutMs >= 100) {
      timeoutMs = max(timeoutMs, 100);
    }
    return Duration(milliseconds: timeoutMs.toInt());
  }

  Future<T> _runWithReconnect<T>(Future<T> Function() operation,
      {required bool allowReconnect,
      bool allowReplayUntilSelectionTimeout = false}) async {
    await waitForOpenIfReconnecting();
    if (allowReconnect) {
      await _waitForMasterSelection();
    }

    final replayRecoverableErrors =
        allowReconnect && allowReplayUntilSelectionTimeout;
    DateTime? replayDeadline = replayRecoverableErrors
        ? DateTime.now().add(_serverSelectionTimeout)
        : null;
    var replayAttempt = 0;
    var healthyTopologyReplayCount = 0;

    try {
      return await _invokeOperationWithReplayBudget(operation, replayDeadline);
    } catch (error, stackTrace) {
      Object currentError = error;
      StackTrace currentStackTrace = stackTrace;
      while (true) {
        var speculativeReadTimeout =
            _isSpeculativeReadTimeoutError(currentError);
        if (!allowReconnect ||
            _explicitlyClosed ||
            !_isRecoverableConnectionError(currentError)) {
          Error.throwWithStackTrace(currentError, currentStackTrace);
        }
        if (speculativeReadTimeout) {
          var speculativeReplayDeadline =
              DateTime.now().add(const Duration(milliseconds: 1200));
          if (replayDeadline == null ||
              speculativeReplayDeadline.isBefore(replayDeadline)) {
            replayDeadline = speculativeReplayDeadline;
          }
        }
        if (replayDeadline != null && DateTime.now().isAfter(replayDeadline)) {
          Error.throwWithStackTrace(currentError, currentStackTrace);
        }
        if (replayRecoverableErrors &&
            healthyTopologyReplayCount >= _maxHealthyTopologyReadReplays &&
            _hasHealthyMaster()) {
          Error.throwWithStackTrace(currentError, currentStackTrace);
        }
        replayAttempt++;
        var hadHealthyMaster = _hasHealthyMaster();
        await _recoverAfterOperationError(_connectionManager,
            replayDeadline: replayDeadline);
        if (replayRecoverableErrors) {
          if (hadHealthyMaster && _hasHealthyMaster()) {
            healthyTopologyReplayCount++;
          } else {
            healthyTopologyReplayCount = 0;
          }
        }
        if (!replayRecoverableErrors) {
          return _invokeOperationWithReplayBudget(operation, replayDeadline);
        }
        if (replayDeadline != null && DateTime.now().isAfter(replayDeadline)) {
          Error.throwWithStackTrace(currentError, currentStackTrace);
        }
        var backoff = speculativeReadTimeout
            ? Duration.zero
            : _operationReplayBackoff(replayAttempt);
        if (replayDeadline != null && backoff > Duration.zero) {
          var remaining = replayDeadline.difference(DateTime.now());
          if (remaining <= Duration.zero) {
            backoff = Duration.zero;
          } else if (backoff > remaining) {
            backoff = remaining;
          }
        }
        if (backoff > Duration.zero) {
          await Future.delayed(backoff);
        }
        try {
          return await _invokeOperationWithReplayBudget(
              operation, replayDeadline);
        } catch (nextError, nextStackTrace) {
          currentError = nextError;
          currentStackTrace = nextStackTrace;
        }
      }
    }
  }

  bool _isSpeculativeReadTimeoutError(Object error) {
    return error is ConnectionException &&
        error.message.contains('Read operation timed out after');
  }

  Future<T> _invokeOperationWithReplayBudget<T>(
      Future<T> Function() operation, DateTime? replayDeadline) {
    if (replayDeadline == null) {
      return operation();
    }
    return runZoned<Future<T>>(operation,
        zoneValues: <Object, Object?>{_replayDeadlineZoneKey: replayDeadline});
  }

  Future<void> _reconnect({DateTime? deadline}) async {
    if (_explicitlyClosed) {
      throw MongoDartError('Db is in the wrong state: $state');
    }
    var reconnectInProgress = _reconnectInProgress;
    if (reconnectInProgress != null) {
      return reconnectInProgress;
    }
    final completer = Completer<void>();
    _reconnectInProgress = completer.future;
    try {
      await _attemptReconnectWithBackoff(deadline: deadline);
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      _reconnectInProgress = null;
    }
  }

  Future<void> _attemptReconnectWithBackoff({DateTime? deadline}) async {
    var delayMs = 100;
    Object? lastError;
    var attempt = 0;
    final reconnectDeadline =
        deadline ?? DateTime.now().add(_serverSelectionTimeout);
    while (attempt < _maxReconnectAttempts &&
        DateTime.now().isBefore(reconnectDeadline)) {
      attempt++;
      if (_explicitlyClosed) {
        throw MongoDartError('Db is in the wrong state: $state');
      }
      try {
        await open(
            writeConcern: _writeConcern ?? WriteConcern.acknowledged,
            secure: _lastSecure,
            tlsAllowInvalidCertificates: _lastTlsAllowInvalidCertificates,
            tlsCAFile: _lastTlsCAFile,
            tlsCertificateKeyFile: _lastTlsCertificateKeyFile,
            tlsCertificateKeyFilePassword: _lastTlsCertificateKeyFilePassword);
        return;
      } catch (error) {
        lastError = error;
        final remainingMs =
            reconnectDeadline.difference(DateTime.now()).inMilliseconds;
        if (attempt >= _maxReconnectAttempts || remainingMs <= 0) {
          rethrow;
        }
        var jitterMs = Random().nextInt((delayMs ~/ 2) + 1);
        var waitMs = min(delayMs + jitterMs, remainingMs);
        if (waitMs > 0) {
          await Future.delayed(Duration(milliseconds: waitMs));
        }
        delayMs = min(delayMs * 2, 2000).toInt();
      }
    }
    throw lastError ?? MongoDartError('Reconnect failed');
  }

  Future<MongoReplyMessage> queryMessage(MongoMessage queryMessage,
      {Connection? connection}) {
    return _runWithReconnect(() async {
      if (state != State.open) {
        throw MongoDartError('Db is in the wrong state: $state');
      }

      var locConnection = connection ??
          _connectionManager!
              .selectOperationalConnection(requireAuthentication: true);

      return _runReadWithSpeculativeTimeout(
          () => locConnection.query(queryMessage),
          connection: locConnection);
    },
        allowReconnect: connection == null,
        allowReplayUntilSelectionTimeout: connection == null);
  }

  void executeMessage(MongoMessage message, WriteConcern? writeConcern,
      {Connection? connection}) {
    if (state != State.open) {
      throw MongoDartError('DB is not open. $state');
    }

    connection ??= _connectionManager!
        .selectOperationalConnection(requireAuthentication: true);

    writeConcern ??= _writeConcern;

    // ignore: deprecated_member_use_from_same_package
    connection.execute(message, writeConcern == WriteConcern.ERRORS_IGNORED);
  }

  Future<Map<String, dynamic>> executeModernMessage(MongoModernMessage message,
      {Connection? connection,
      bool skipStateCheck = false,
      bool replayReadsUntilSelectionTimeout = false,
      bool disableSpeculativeReadTimeout = false}) async {
    return _runWithReconnect(() async {
      var selectedConnection = connection;
      if (skipStateCheck) {
        selectedConnection ??= _masterConnection;
        if (selectedConnection != null &&
            !selectedConnection.serverCapabilities.supportsOpMsg) {
          throw MongoDartError('The "modern message" can only be executed '
              'starting from release 3.6');
        }
      } else {
        if (state != State.open) {
          throw MongoDartError('DB is not open. $state');
        }
        var opConnection = selectedConnection ??
            _connectionManager!
                .selectOperationalConnection(requireAuthentication: true);
        if (!opConnection.serverCapabilities.supportsOpMsg) {
          throw MongoDartError('The "modern message" can only be executed '
              'starting from release 3.6');
        }
        selectedConnection = opConnection;
      }

      var locConnection =
          selectedConnection ?? _masterConnectionVerifiedAnyState;
      var operationDescription = _describeModernMessage(message);

      var response =
          replayReadsUntilSelectionTimeout && !disableSpeculativeReadTimeout
              ? await _runReadWithSpeculativeTimeout(
                  () => locConnection.executeModernMessage(message),
                  connection: locConnection,
                  operationDescription: operationDescription)
              : await locConnection.executeModernMessage(message);

      var section = response.sections.firstWhere((Section section) =>
          section.payloadType == MongoModernMessage.basePayloadType);
      var payload = section.payload.content;
      if (_isAuthenticationStateFailure(payload, locConnection)) {
        _invalidateConnectionAuthentication(
            locConnection, payload[keyErrmsg]?.toString());
        throw ConnectionException(payload[keyErrmsg]?.toString() ??
            'Command requires authentication');
      }
      return payload;
    },
        allowReconnect:
            connection == null && !skipStateCheck && !_explicitlyClosed,
        allowReplayUntilSelectionTimeout: replayReadsUntilSelectionTimeout &&
            connection == null &&
            !skipStateCheck &&
            !_explicitlyClosed);
  }

  Future<T> _runReadWithSpeculativeTimeout<T>(Future<T> Function() operation,
      {required Connection connection, String? operationDescription}) async {
    var timeout = _effectiveSpeculativeReadTimeout(connection);
    if (timeout == null) {
      return operation();
    }
    var timeoutMessage = _formatSpeculativeReadTimeoutMessage(
        timeout, operationDescription: operationDescription);
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      if (!connection._closed && connection.connected) {
        unawaited(connection._closeSocketOnError(
            socketError: timeoutMessage));
      } else if (!connection._closed) {
        unawaited(connection.close());
      }
      throw ConnectionException(timeoutMessage);
    }
  }

  String _formatSpeculativeReadTimeoutMessage(Duration timeout,
      {String? operationDescription}) {
    var message =
        'Read operation timed out after ${timeout.inMilliseconds}ms';
    if (operationDescription == null || operationDescription.isEmpty) {
      return message;
    }
    return '$message ($operationDescription)';
  }

  String? _describeModernMessage(MongoModernMessage message) {
    try {
      var section = message.sections.firstWhere((Section section) =>
          section.payloadType == MongoModernMessage.basePayloadType);
      var payload = section.payload.content;
      if (payload.isEmpty) {
        return null;
      }
      var commandName = payload.keys.first;
      var collectionName = _extractCommandCollectionName(payload, commandName);
      if (collectionName == null || collectionName.isEmpty) {
        return commandName;
      }
      return '$commandName $collectionName';
    } catch (_) {
      return null;
    }
  }

  String? _extractCommandCollectionName(
      Map<String, dynamic> payload, String commandName) {
    var directCollection = payload[commandName];
    if (directCollection is String && directCollection.isNotEmpty) {
      return directCollection;
    }
    var indirectCollection = payload[keyCollection];
    if (indirectCollection is String && indirectCollection.isNotEmpty) {
      return indirectCollection;
    }
    return null;
  }

  Duration? _speculativeReadTimeout(Connection connection) {
    if (connection.serverConfig.socketTimeout != null) {
      return null;
    }
    return const Duration(milliseconds: 3000);
  }

  Duration? _effectiveSpeculativeReadTimeout(Connection connection) {
    var timeout = _speculativeReadTimeout(connection);
    if (timeout == null) {
      return null;
    }
    var replayDeadline = Zone.current[_replayDeadlineZoneKey] as DateTime?;
    if (replayDeadline == null) {
      return timeout;
    }
    var remaining = replayDeadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return Duration.zero;
    }
    return remaining < timeout ? remaining : timeout;
  }

  bool _isAuthenticationStateFailure(
      Map<String, dynamic> response, Connection connection) {
    var authRequired = _authenticationScheme == AuthenticationScheme.X509 ||
        filled(connection.serverConfig.userName);
    return authRequired &&
        RecoverableErrorClassifier.isAuthenticationStateFailureDocument(
            response);
  }

  void _invalidateConnectionAuthentication(
      Connection connection, String? reason) {
    connection.serverConfig.isAuthenticated = false;
    if (connection._closed) {
      return;
    }
    var socketError =
        reason ?? 'Server requires re-authentication for this connection.';
    if (connection.connected) {
      unawaited(connection._closeSocketOnError(socketError: socketError));
    } else {
      unawaited(connection.close());
    }
  }

  Future open(
      {WriteConcern writeConcern = WriteConcern.acknowledged,
      bool secure = false,
      bool tlsAllowInvalidCertificates = false,
      String? tlsCAFile,
      String? tlsCertificateKeyFile,
      String? tlsCertificateKeyFilePassword}) async {
    if (state == State.opening) {
      var openInProgress = _openInProgress;
      if (openInProgress != null) {
        return openInProgress;
      }
      throw MongoDartError('Attempt to open db in state $state');
    }
    if (state == State.open && isConnected) {
      return;
    }

    _explicitlyClosed = false;
    _lastSecure = secure;
    _lastTlsAllowInvalidCertificates = tlsAllowInvalidCertificates;
    _lastTlsCAFile = tlsCAFile;
    _lastTlsCertificateKeyFile = tlsCertificateKeyFile;
    _lastTlsCertificateKeyFilePassword = tlsCertificateKeyFilePassword;
    state = State.opening;
    _writeConcern = writeConcern;
    var openCompleter = Completer<void>();
    _openInProgress = openCompleter.future;

    try {
      var previousManager = _connectionManager;
      var previousSupportsOpMsg = previousManager?.supportsOpMsg ?? false;
      var previousSupportsListCollections =
          previousManager?.supportsListCollections ?? false;
      var previousSupportsListIndexes =
          previousManager?.supportsListIndexes ?? false;
      if (previousManager != null) {
        try {
          await previousManager.close();
        } catch (error) {
          _log.warning('Could not close stale connection manager: $error');
        }
      }

      var newConnectionManager = ConnectionManager(this,
          lastMasterSupportsOpMsg: previousSupportsOpMsg,
          lastMasterSupportsListCollections: previousSupportsListCollections,
          lastMasterSupportsListIndexes: previousSupportsListIndexes);
      _connectionManager = newConnectionManager;

      var serverConfigs = await Future.wait(_uriList.map((uri) => _parseUri(uri,
          isSecure: secure,
          tlsAllowInvalidCertificates: tlsAllowInvalidCertificates,
          tlsCAFile: tlsCAFile,
          tlsCertificateKeyFile: tlsCertificateKeyFile,
          tlsCertificateKeyFilePassword: tlsCertificateKeyFilePassword)));
      for (var config in serverConfigs) {
        newConnectionManager.addConnection(config);
      }
      try {
        await newConnectionManager.open(writeConcern);
        if (_explicitlyClosed ||
            !identical(_connectionManager, newConnectionManager)) {
          _stopHeartbeatMonitor();
          await newConnectionManager.close();
          if (_explicitlyClosed) {
            state = State.closed;
          }
          openCompleter.complete();
          return;
        }
        _startHeartbeatMonitor();
      } catch (e) {
        state = State.init;
        _stopHeartbeatMonitor();
        await newConnectionManager.close();
        if (identical(_connectionManager, newConnectionManager)) {
          _connectionManager = null;
        }
        rethrow;
      }
      openCompleter.complete();
    } catch (error, stackTrace) {
      if (!openCompleter.isCompleted) {
        openCompleter.completeError(error, stackTrace);
      }
      rethrow;
    } finally {
      if (identical(_openInProgress, openCompleter.future)) {
        _openInProgress = null;
      }
    }
  }

  /// Is connected returns true if the database is in state `OPEN`
  /// and at least the primary connection is connected
  ///
  /// Connections can disconect because of network or database server problems.
  bool get isConnected => state == State.open && _hasHealthyMaster();

  Future<Map<String, dynamic>> executeDbCommand(MongoMessage message,
      {Connection? connection,
      bool replayReadsUntilSelectionTimeout = false}) async {
    return _runWithReconnect(() async {
      var locConnection = connection ??
          _connectionManager!
              .selectOperationalConnection(requireAuthentication: true);

      //var result = Completer<Map<String, dynamic>>();

      var replyMessage = await locConnection.query(message);
      if (replyMessage.documents == null || replyMessage.documents!.isEmpty) {
        throw {
          keyOk: 0.0,
          keyErrmsg:
              'Error executing Db command, documents are empty $replyMessage'
        };
      }
      var firstRepliedDocument = replyMessage.documents!.first;
      if (_isAuthenticationStateFailure(firstRepliedDocument, locConnection)) {
        _invalidateConnectionAuthentication(
            locConnection, firstRepliedDocument[keyErrmsg]?.toString());
        throw ConnectionException(firstRepliedDocument[keyErrmsg]?.toString() ??
            'Command requires authentication');
      }
      /*var errorMessage = '';

       if (replyMessage.documents.isEmpty) {
        errorMessage =
            'Error executing Db command, documents are empty $replyMessage';

        print('Error: $errorMessage');

        var m = <String, dynamic>{};
        m['errmsg'] = errorMessage;

        result.completeError(m);
      } else  */
      if (documentIsNotAnError(firstRepliedDocument)) {
        //result.complete(firstRepliedDocument);
        return firstRepliedDocument;
      } //else {

      //result.completeError(firstRepliedDocument);
      throw firstRepliedDocument;
      //}
      //return result.future;
    },
        allowReconnect: connection == null && !_explicitlyClosed,
        allowReplayUntilSelectionTimeout: replayReadsUntilSelectionTimeout &&
            connection == null &&
            !_explicitlyClosed);
  }

  /// Visible for testing: inject a custom connection manager.
  void debugAttachConnectionManager(ConnectionManager manager) {
    _connectionManager = manager;
  }

  bool documentIsNotAnError(dynamic firstRepliedDocument) =>
      _isServerCommandOk(firstRepliedDocument['ok']) &&
      firstRepliedDocument['err'] == null;

  Future<bool> dropCollection(String collectionName) async {
    if (supportsOpMsg) {
      var result = await modernDrop(collectionName);
      return _isServerCommandOk(result[keyOk]);
    }
    var collectionInfos = await getCollectionInfos({'name': collectionName});

    if (collectionInfos.length == 1) {
      return executeDbCommand(
              DbCommand.createDropCollectionCommand(this, collectionName))
          .then((_) => true);
    }

    return true;
  }

  ///   Drop current database
  Future drop() async {
    if (supportsOpMsg) {
      var result = await modernDropDatabase();
      return _isServerCommandOk(result[keyOk]);
    }
    return executeDbCommand(DbCommand.createDropDatabaseCommand(this));
  }

  Future<Map<String, dynamic>> removeFromCollection(String collectionName,
      [Map<String, dynamic> selector = const {},
      WriteConcern? writeConcern]) async {
    if (supportsOpMsg) {
      var collection = this.collection(collectionName);
      var result = await collection.deleteMany(
        selector,
        writeConcern: writeConcern,
      );
      return result.serverResponses.first;
    }
    return Future.sync(() {
      executeMessage(
          MongoRemoveMessage('$databaseName.$collectionName', selector),
          writeConcern);
      return _getAcknowledgement(writeConcern: writeConcern);
    });
  }

  Future<Map<String, dynamic>> getLastError(
      [WriteConcern? writeConcern]) async {
    writeConcern ??= _writeConcern;
    if (supportsOpMsg) {
      return GetLastErrorCommand(this, writeConcern: writeConcern).execute();
    } else {
      return executeDbCommand(
          DbCommand.createGetLastErrorCommand(this, writeConcern));
    }
  }

  @Deprecated('Deprecated since version 4.0.')
  Future<Map<String, dynamic>> getNonce({Connection? connection}) {
    var locConnection = connection ?? masterConnection;
    if (locConnection.serverCapabilities.fcv != null &&
        locConnection.serverCapabilities.fcv!.compareTo('6.0') >= 0) {
      throw MongoDartError('getnonce command not managed in this version');
    }
    return executeDbCommand(DbCommand.createGetNonceCommand(this),
        connection: locConnection);
  }

  Future<Map<String, dynamic>> getBuildInfo({Connection? connection}) {
    return executeDbCommand(DbCommand.createBuildInfoCommand(this),
        connection: connection,
        replayReadsUntilSelectionTimeout: connection == null);
  }

  Future<Map<String, dynamic>> isMaster({Connection? connection}) =>
      executeDbCommand(DbCommand.createIsMasterCommand(this),
          connection: connection,
          replayReadsUntilSelectionTimeout: connection == null);

  Future<Map<String, dynamic>> wait() => getLastError();

  Future close() async {
    _log.fine(() => '$this closed');
    _explicitlyClosed = true;
    _reconnectInProgress = null;
    _stopHeartbeatMonitor();
    state = State.closed;
    var cm = _connectionManager;
    _connectionManager = null;
    return cm?.close();
  }

  /// Analogue to shell's `show dbs`. Helper for `listDatabases` mongodb command.
  Future<List> listDatabases() async {
    Map<String, dynamic> commandResult;
    if (supportsOpMsg) {
      commandResult =
          await DbAdminCommandOperation(this, {'listDatabases': 1}).execute();
    } else {
      commandResult = await executeDbCommand(
          DbCommand.createQueryAdminCommand({'listDatabases': 1}),
          replayReadsUntilSelectionTimeout: true);
    }

    var result = [];

    for (var each in commandResult['databases']) {
      result.add(each['name']);
    }

    return result;
  }

  Stream<Map<String, dynamic>> _listCollectionsCursor(
      [Map<String, dynamic> filter = const {}]) {
    if (supportsListCollections) {
      return ListCollectionsCursor(this, filter).stream;
    } else {
      // Using system collections (pre v3.0 API)
      var selector = <String, dynamic>{};
      // If we are limiting the access to a specific collection name
      if (filter.containsKey('name')) {
        selector['name'] = "$databaseName.${filter['name']}";
      }
      return Cursor(
              this,
              DbCollection(this, DbCommand.SYSTEM_NAMESPACE_COLLECTION),
              selector)
          .stream;
    }
  }

  /// This method uses system collections and therefore do not work on MongoDB v3.0 with and upward
  /// with WiredTiger
  /// Use `getCollectionInfos` instead
  @Deprecated('Use `getCollectionInfos` instead')
  Stream<Map<String, dynamic>> collectionsInfoCursor(
          [String? collectionName]) =>
      _collectionsInfoCursor(collectionName);

  Stream<Map<String, dynamic>> _collectionsInfoCursor(
      [String? collectionName]) {
    var selector = <String, dynamic>{};
    // If we are limiting the access to a specific collection name
    if (collectionName != null) {
      selector['name'] = '$databaseName.$collectionName';
    }
    // Return Cursor
    return Cursor(this,
            DbCollection(this, DbCommand.SYSTEM_NAMESPACE_COLLECTION), selector)
        .stream;
  }

  /// Analogue to shell's `show collections`
  /// This method uses system collections and therefore do not work on MongoDB v3.0 with and upward
  /// with WiredTiger
  /// Use `getCollectionNames` instead
  @Deprecated('Use `getCollectionNames` instead')
  Future<List<String?>> listCollections() async {
    if (supportsOpMsg) {
      var ret = await modernListCollections().toList();

      return [
        for (var element in ret)
          for (var nameKey in element.keys)
            if (nameKey == keyName) element[keyName]
      ];
    }
    return _collectionsInfoCursor()
        .map((map) => map['name']?.toString().split('.'))
        .where((arr) => arr != null && arr.length == 2)
        .map((arr) => arr?.last)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCollectionInfos(
      [Map<String, dynamic> filter = const {}]) async {
    if (supportsOpMsg) {
      return modernListCollections(filter: filter).toList();
    }
    return _listCollectionsCursor(filter).toList();
  }

  Future<List<String?>> getCollectionNames(
      [Map<String, dynamic> filter = const {}]) async {
    if (supportsOpMsg) {
      var ret = await modernListCollections().toList();

      return [
        for (var element in ret)
          for (var nameKey in element.keys)
            if (nameKey == keyName) element[keyName]
      ];
    }
    return _listCollectionsCursor(filter)
        .map((map) => map['name']?.toString())
        .toList();
  }

  /// Method for authentication with X509 certificate.
  /// In the conection parameters you have not to set
  /// X509 if you want to use this delayed auth function.
  Future<bool> authenticateX509({Connection? connection}) async =>
      authenticate(null, null,
          connection: connection,
          authScheme: AuthenticationScheme.X509,
          authDb: r'$external');

  Future<bool> authenticate(String? userName, String? password,
      {Connection? connection,
      AuthenticationScheme? authScheme,
      String? authDb}) async {
    var credential = UsernamePasswordCredential()
      ..username = userName
      ..password = password;

    (connection ?? masterConnection).serverConfig.userName ??= userName;
    (connection ?? masterConnection).serverConfig.password ??= password;

    if (authScheme != null) {
      _authenticationScheme = authScheme;
    }
    if (authDb != null) {
      authSourceDb = Db._authDb(authDb);
    }

    if (_authenticationScheme == null) {
      throw MongoDartError('Authentication scheme not specified');
    }
    var authenticator =
        Authenticator.create(_authenticationScheme!, this, credential);

    await authenticator.authenticate(connection ?? masterConnection);

    (connection ?? masterConnection).serverConfig.isAuthenticated = true;
    return true;
  }

  /// This method uses system collections and therefore do not work on MongoDB v3.0 with and upward
  /// with WiredTiger
  /// Use `DbCollection.getIndexes()` instead
  @Deprecated('Use `DbCollection.getIndexes()` instead')
  Future<List> indexInformation([String? collectionName]) {
    var selector = {};

    if (collectionName != null) {
      selector['ns'] = '$databaseName.$collectionName';
    }

    return Cursor(this, DbCollection(this, DbCommand.SYSTEM_INDEX_COLLECTION),
            selector)
        .stream
        .toList();
  }

  String _createIndexName(Map<String, dynamic> keys) {
    var name = '';

    keys.forEach((key, value) {
      if (name.isEmpty) {
        name = '${key}_$value';
      } else {
        name = '${name}_${key}_$value';
      }
    });

    return name;
  }

  Future<Map<String, dynamic>> createIndex(String collectionName,
      {String? key,
      Map<String, dynamic>? keys,
      bool? unique,
      bool? sparse,
      bool? background,
      bool? dropDups,
      Map<String, dynamic>? partialFilterExpression,
      String? name}) {
    if (supportsOpMsg) {
      return collection(collectionName).createIndex(
          key: key,
          keys: keys,
          unique: unique,
          sparse: sparse,
          background: background,
          dropDups: dropDups,
          partialFilterExpression: partialFilterExpression,
          name: name);
    }
    return Future.sync(() async {
      var selector = <String, dynamic>{};
      selector['ns'] = '$databaseName.$collectionName';
      keys = _setKeys(key, keys);
      selector['key'] = keys;

      if (unique == true) {
        selector['unique'] = true;
      } else {
        selector['unique'] = false;
      }
      if (sparse == true) {
        selector['sparse'] = true;
      }
      if (background == true) {
        selector['background'] = true;
      }
      if (dropDups == true) {
        selector['dropDups'] = true;
      }
      if (partialFilterExpression != null) {
        selector['partialFilterExpression'] = partialFilterExpression;
      }
      name ??= _createIndexName(keys!);
      selector['name'] = name;
      var insertMessage = MongoInsertMessage(
          '$databaseName.${DbCommand.SYSTEM_INDEX_COLLECTION}', [selector]);
      executeMessage(insertMessage, _writeConcern);
      return getLastError();
    });
  }

  Map<String, dynamic> _setKeys(String? key, Map<String, dynamic>? keys) {
    if (key != null && keys != null) {
      throw ArgumentError('Only one parameter must be set: key or keys');
    }

    if (key != null) {
      keys = {};
      keys[key] = 1;
    }

    if (keys == null) {
      throw ArgumentError('key or keys parameter must be set');
    }

    return keys;
  }

  Future ensureIndex(String collectionName,
      {String? key,
      Map<String, dynamic>? keys,
      bool? unique,
      bool? sparse,
      bool? background,
      bool? dropDups,
      Map<String, dynamic>? partialFilterExpression,
      String? name}) async {
    keys = _setKeys(key, keys);
    var indexInfos = await collection(collectionName).getIndexes();

    name ??= _createIndexName(keys);

    if (indexInfos.any((info) => info['name'] == name) ||
        // For compatibility reasons, old indexes where created with
        // a leading underscore
        indexInfos.any((info) => info['name'] == '_$name')) {
      return {'ok': 1.0, 'result': 'index preexists'};
    }

    var createdIndex = await createIndex(collectionName,
        keys: keys,
        unique: unique,
        sparse: sparse,
        background: background,
        dropDups: dropDups,
        partialFilterExpression: partialFilterExpression,
        name: name);

    return createdIndex;
  }

  Future<Map<String, dynamic>> _getAcknowledgement(
      {WriteConcern? writeConcern}) {
    writeConcern ??= _writeConcern;

    // ignore: deprecated_member_use_from_same_package
    if (writeConcern == WriteConcern.ERRORS_IGNORED) {
      return Future.value({'ok': 1.0});
    } else {
      return getLastError(writeConcern);
    }
  }

  // **********************************************************+
  // ************** OP_MSG_COMMANDS ****************************
  // ***********************************************************

  /// This method drops the current DB
  Future<Map<String, dynamic>> modernDropDatabase(
      {DropDatabaseOptions? dropOptions,
      Map<String, Object>? rawOptions}) async {
    var command = DropDatabaseCommand(this,
        dropDatabaseOptions: dropOptions, rawOptions: rawOptions);
    return command.execute();
  }

  /// This method return the status information on the
  /// connection.
  ///
  /// Only works from version 3.6
  Future<Map<String, dynamic>> serverStatus(
      {Map<String, Object>? options}) async {
    if (!supportsOpMsg) {
      return <String, Object>{};
    }
    var operation = ServerStatusCommand(this,
        serverStatusOptions: ServerStatusOptions.instance);
    return operation.execute();
  }

  /// This method explicitly creates a collection
  Future<Map<String, dynamic>> createCollection(String name,
      {CreateCollectionOptions? createCollectionOptions,
      Map<String, Object>? rawOptions}) async {
    var command = CreateCollectionCommand(this, name,
        createCollectionOptions: createCollectionOptions,
        rawOptions: rawOptions);
    return command.execute();
  }

  /// This method retuns a cursor to get a list of the collections
  /// for this DB.
  ///
  Stream<Map<String, dynamic>> modernListCollections(
      {SelectorBuilder? selector,
      Map<String, dynamic>? filter,
      ListCollectionsOptions? findOptions,
      Map<String, Object>? rawOptions}) {
    var command = ListCollectionsCommand(this,
        filter:
            filter ?? (selector?.map == null ? null : selector!.map[key$Query]),
        listCollectionsOptions: findOptions,
        rawOptions: rawOptions);

    return ModernCursor(command).stream;
  }

  /// This method creates a view
  Future<Map<String, dynamic>> createView(
      String view, String source, List pipeline,
      {CreateViewOptions? createViewOptions,
      Map<String, Object>? rawOptions}) async {
    var command = CreateViewCommand(this, view, source, pipeline,
        createViewOptions: createViewOptions, rawOptions: rawOptions);
    return command.execute();
  }

  /// This method drops a collection
  Future<Map<String, dynamic>> modernDrop(String collectionNAme,
      {DropOptions? dropOptions, Map<String, Object>? rawOptions}) async {
    var command = DropCommand(this, collectionNAme,
        dropOptions: dropOptions, rawOptions: rawOptions);
    return command.execute();
  }

  /// Runs a specified admin/diagnostic pipeline which does not require an
  /// underlying collection. For aggregations on collection data,
  /// see `dbcollection.modernAggregate()`.
  Stream<Map<String, dynamic>> aggregate(List<Map<String, Object>> pipeline,
      {bool? explain,
      Map<String, Object>? cursor,
      String? hint,
      Map<String, Object>? hintDocument,
      AggregateOptions? aggregateOptions,
      Map<String, Object>? rawOptions}) {
    if (!supportsOpMsg) {
      throw MongoDartError('At least MongoDb version 3.6 is required '
          'to run the aggregate operation');
    }
    return ModernCursor(AggregateOperation(pipeline,
            db: this,
            explain: explain,
            cursor: cursor,
            hint: hint,
            hintDocument: hintDocument,
            aggregateOptions: aggregateOptions,
            rawOptions: rawOptions))
        .stream;
  }

  /// Runs a command
  Future<Map<String, dynamic>> runCommand(Map<String, Object>? command) =>
      CommandOperation(this, <String, Object>{}, command: command).execute();

  /// Ping command
  Future<Map<String, dynamic>> pingCommand() => PingCommand(this).execute();
}
