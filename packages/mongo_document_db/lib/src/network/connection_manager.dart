part of '../../mongo_document_db.dart';

class ConnectionManager {
  final _log = Logger('ConnectionManager');
  final Db db;
  final _connectionPool = <String, _HostConnectionPool>{};
  Connection? _masterConnection;
  bool _lastMasterSupportsOpMsg;
  bool _lastMasterSupportsListCollections;
  bool _lastMasterSupportsListIndexes;
  final Set<Connection> _recoveringConnections = <Connection>{};
  final Map<String, Future<void>> _authInProgressByHost =
      <String, Future<void>>{};
  Future<void>? _masterRecoveryInProgress;
  Future<void>? _topologyRefreshInProgress;
  bool _closed = false;

  ConnectionManager(this.db,
      {bool lastMasterSupportsOpMsg = false,
      bool lastMasterSupportsListCollections = false,
      bool lastMasterSupportsListIndexes = false})
      : _lastMasterSupportsOpMsg = lastMasterSupportsOpMsg,
        _lastMasterSupportsListCollections = lastMasterSupportsListCollections,
        _lastMasterSupportsListIndexes = lastMasterSupportsListIndexes;

  Connection? get masterConnection => _masterConnection;

  Iterable<Connection> get _allConnections sync* {
    for (var hostPool in _connectionPool.values) {
      yield* hostPool.connections;
    }
  }

  bool get supportsOpMsg =>
      _masterConnection?.serverCapabilities.supportsOpMsg ??
      _lastMasterSupportsOpMsg;

  bool get supportsListCollections =>
      _masterConnection?.serverCapabilities.listCollections ??
      _lastMasterSupportsListCollections;

  bool get supportsListIndexes =>
      _masterConnection?.serverCapabilities.listIndexes ??
      _lastMasterSupportsListIndexes;

  /// Indicates whether at least one pooled host still has an open socket.
  /// This mirrors the Java driver SDAM approach: keep monitoring/promotion
  /// active before tearing down the whole topology.
  bool get hasAnyConnectedServer {
    for (var connection in _allConnections) {
      if (!connection._closed && connection.connected) {
        return true;
      }
    }
    return false;
  }

  bool get hasAnyReadyServer {
    for (var connection in _allConnections) {
      if (_isConnectionReadyForOperations(connection)) {
        return true;
      }
    }
    return false;
  }

  bool _requiresAuthentication(Connection connection) {
    if (db._authenticationScheme == AuthenticationScheme.X509) {
      return true;
    }
    return filled(connection.serverConfig.userName);
  }

  bool _isConnectionReadyForOperations(Connection connection) {
    if (connection._closed || !connection.connected) {
      return false;
    }
    if (!_requiresAuthentication(connection)) {
      return true;
    }
    return connection.serverConfig.isAuthenticated;
  }

  Connection? _connectedMaster() {
    var master = _masterConnection;
    if (master != null && _isConnectionReadyForOperations(master)) {
      return master;
    }
    return null;
  }

  bool _shouldUseLegacyIsMasterFallback(Object source) {
    int? code;
    String message;
    if (source is MongoDartError) {
      code = source.mongoCode;
      message = source.message;
    } else if (source is Map<String, dynamic>) {
      code = (source[keyCode] as num?)?.toInt();
      message = source[keyErrmsg]?.toString() ?? '';
    } else if (source is ConnectionException) {
      return false;
    } else {
      message = source.toString();
    }
    var normalized = message.toLowerCase();
    if (code == 59) {
      // CommandNotFound: mostly pre-3.6 servers where OP_MSG/hello is missing.
      return true;
    }
    return (normalized.contains('no such command') &&
            normalized.contains('hello')) ||
        (normalized.contains('no such cmd') && normalized.contains('hello')) ||
        (normalized.contains('unsupported') &&
            (normalized.contains('op_msg') ||
                normalized.contains('opmsg') ||
                normalized.contains('hello')));
  }

  bool _isExpectedConnectionChurn(Object error) {
    if (error is ConnectionException) {
      var message = error.message.toLowerCase();
      return message.contains('connection closed') ||
          message.contains('already closed') ||
          message.contains('socket closed by remote host');
    }
    if (error is MongoDartError) {
      var message = error.message.toLowerCase();
      if (error.mongoCode == 91 || error.mongoCode == 189) {
        return true;
      }
      return message.contains('connection closed') ||
          message.contains('already closed') ||
          message.contains('socket closed by remote host');
    }
    return false;
  }

  Connection get masterConnectionVerified {
    var master = _connectedMaster();
    if (master != null) {
      return master;
    } else {
      throw MongoDartError('No master connection');
    }
  }

  /// Selects an authenticated, connected socket from the current primary host.
  /// This provides per-host operation distribution while preserving primary
  /// routing semantics.
  Connection selectOperationalConnection({bool requireAuthentication = true}) {
    var master = masterConnectionVerified;
    var hostPool = _connectionPool[master.serverConfig.hostUrl];
    if (hostPool == null) {
      return master;
    }
    var selected = hostPool.selectLeastBusyConnection(
        requireAuthentication: requireAuthentication);
    if (selected != null) {
      return selected;
    }
    return master;
  }

  Future<bool> _connect(Connection connection,
      {bool authenticate = true}) async {
    await connection.connect();
    var result = <String, dynamic>{keyOk: 0.0};
    Object? helloError;
    StackTrace? helloStackTrace;
    // As I couldn't set-up a pre 3.6 environment, I check not only for
    // a {ok: 0.0} but also for any other error
    try {
      var helloCommand = HelloCommand(db,
          username: connection.serverConfig.userName,
          clientMetadata: connection.serverConfig.clientMetadata,
          connection: connection);
      result = await helloCommand.execute(skipStateCheck: true);
    } catch (error, stackTrace) {
      helloError = error;
      helloStackTrace = stackTrace;
    }
    if (_isServerCommandOk(result[keyOk])) {
      var resultDoc = HelloResult(result);
      if (connection.serverConfig.loadBalanced == true &&
          !resultDoc.isLoadBalanced) {
        throw MongoDartError('The server is not in Load Balanced mode');
      }
      var master = resultDoc.isWritablePrimary;
      connection.isMaster = master;
      connection.serverCapabilities.getParamsFromHello(resultDoc);
      if (master) {
        if (authenticate) {
          await _authenticateConnection(connection);
        }
        var currentMaster = _masterConnection;
        if (authenticate ||
            currentMaster == null ||
            !_isConnectionReadyForOperations(currentMaster)) {
          _masterConnection = connection;
          _cacheMasterCapabilities(connection);
          MongoModernMessage.maxBsonObjectSize = resultDoc.maxBsonObjectSize;
          MongoModernMessage.maxMessageSizeBytes =
              resultDoc.maxMessageSizeBytes;
          MongoModernMessage.maxWriteBatchSize = resultDoc.maxWriteBatchSize;
        }
      }
      if (db._authenticationScheme == null &&
          resultDoc.saslSupportedMechs != null) {
        if (resultDoc.saslSupportedMechs!.contains('SCRAM-SHA-256')) {
          db._authenticationScheme = AuthenticationScheme.SCRAM_SHA_256;
        } else if (resultDoc.saslSupportedMechs!.contains('SCRAM-SHA-1')) {
          db._authenticationScheme = AuthenticationScheme.SCRAM_SHA_1;
        }
      }
    } else {
      if (helloError != null && !_shouldUseLegacyIsMasterFallback(helloError)) {
        Error.throwWithStackTrace(helloError, helloStackTrace!);
      }
      if (!_isServerCommandOk(result[keyOk]) &&
          result.containsKey(keyErrmsg) &&
          !_shouldUseLegacyIsMasterFallback(result)) {
        throw MongoDartError(result[keyErrmsg]?.toString() ?? 'Hello failed',
            mongoCode: (result[keyCode] as num?)?.toInt(),
            errorCodeName: result[keyCodeName]?.toString());
      }
      if (connection._closed) {
        connection._closed = false;
        await connection.connect();
        result = <String, dynamic>{keyOk: 0.0};
      }
      var isMasterCommand = DbCommand.createIsMasterCommand(db);
      var replyMessage = await connection.query(isMasterCommand);
      if (replyMessage.documents == null || replyMessage.documents!.isEmpty) {
        throw MongoDartError('Empty reply message received');
      }
      var documents = replyMessage.documents!;
      if (_isServerCommandNotOk(documents.first[keyOk])) {
        var errorMessage = documents.first[keyErrmsg]?.toString() ??
            'Legacy isMaster command failed';
        if (errorMessage.contains('OP_QUERY is no longer supported') &&
            helloError != null) {
          Error.throwWithStackTrace(helloError, helloStackTrace!);
        }
        throw MongoDartError(documents.first[keyErrmsg]);
      }
      _log.finer(() => documents.first.toString());
      var master = documents.first['ismaster'] == true;
      connection.isMaster = master;
      connection.serverCapabilities.getParamsFromIstMaster(documents.first);
      if (master) {
        if (authenticate) {
          await _authenticateConnection(connection);
        }
        var currentMaster = _masterConnection;
        if (authenticate ||
            currentMaster == null ||
            !_isConnectionReadyForOperations(currentMaster)) {
          _masterConnection = connection;
          _cacheMasterCapabilities(connection);
          MongoModernMessage.maxBsonObjectSize =
              documents.first[keyMaxBsonObjectSize];
          MongoModernMessage.maxMessageSizeBytes =
              documents.first[keyMaxMessageSizeBytes];
          MongoModernMessage.maxWriteBatchSize =
              documents.first[keyMaxWriteBatchSize];
        }
      }
    }

    if (db._authenticationScheme == null) {
      if ((connection.serverCapabilities.fcv?.compareTo('4.0') ?? -1) > -1) {
        db._authenticationScheme = AuthenticationScheme.SCRAM_SHA_256;
      } else if (connection.serverCapabilities.maxWireVersion >= 3) {
        db._authenticationScheme = AuthenticationScheme.SCRAM_SHA_1;
      } else {
        db._authenticationScheme = AuthenticationScheme.MONGODB_CR;
      }
    }
    if (!authenticate) {
      _log.fine(() => '$db: ${connection.serverConfig.hostUrl} '
          'topology connected');
      return true;
    }
    if (!connection.serverConfig.isAuthenticated) {
      await _authenticateConnection(connection);
    }
    return true;
  }

  Future<void> _authenticateConnection(Connection connection) async {
    var hostUrl = connection.serverConfig.hostUrl;
    while (true) {
      if (connection._closed || !connection.connected) {
        throw const ConnectionException('Connection is not available');
      }
      if (connection.serverConfig.isAuthenticated) {
        return;
      }
      var authInProgress = _authInProgressByHost[hostUrl];
      if (authInProgress == null) {
        break;
      }
      await authInProgress;
    }

    var authFuture = () async {
      if (connection._closed || !connection.connected) {
        throw const ConnectionException('Connection is not available');
      }
      if (connection.serverConfig.isAuthenticated) {
        return;
      }
      if (connection.serverConfig.userName == null &&
          db._authenticationScheme != AuthenticationScheme.X509) {
        _log.fine(() => '$db: ${connection.serverConfig.hostUrl} connected');
        return;
      }
      try {
        await db.authenticate(
            connection.serverConfig.userName, connection.serverConfig.password,
            connection: connection);
        _log.fine(() => '$db: ${connection.serverConfig.hostUrl} connected');
      } catch (e) {
        /// Atlas does not currently support SHA_256
        if (e is MongoDartError &&
            e.mongoCode == 8000 &&
            e.errorCodeName == 'AtlasError' &&
            e.message.contains('SCRAM-SHA-256') &&
            db._authenticationScheme == AuthenticationScheme.SCRAM_SHA_256) {
          _log.warning(() => 'Atlas connection: SCRAM_SHA_256 not available, '
              'downgrading to SCRAM_SHA_1');
          db._authenticationScheme = AuthenticationScheme.SCRAM_SHA_1;
          await db.authenticate(connection.serverConfig.userName!,
              connection.serverConfig.password ?? '',
              connection: connection);
          _log.fine(() => '$db: ${connection.serverConfig.hostUrl} connected');
          return;
        }
        if (connection == _masterConnection) {
          _masterConnection = null;
        }
        await connection.close();
        rethrow;
      }
    }();
    _authInProgressByHost[hostUrl] = authFuture;
    try {
      await authFuture;
    } finally {
      if (identical(_authInProgressByHost[hostUrl], authFuture)) {
        var removed = _authInProgressByHost.remove(hostUrl);
        assert(identical(removed, authFuture));
      }
    }
  }

  void _cacheMasterCapabilities(Connection connection) {
    _lastMasterSupportsOpMsg = connection.serverCapabilities.supportsOpMsg;
    _lastMasterSupportsListCollections =
        connection.serverCapabilities.listCollections;
    _lastMasterSupportsListIndexes = connection.serverCapabilities.listIndexes;
  }

  Future<void> open(WriteConcern writeConcern) async {
    _closed = false;
    _masterConnection = null;
    var connectionErrors = <Object>[];
    var tasks = <Future<void>>[];
    for (var hostPool in _connectionPool.values) {
      // Keep startup conservative: connect one socket per host first.
      // Additional sockets are intentionally not pre-opened to avoid
      // connection storms during service boot.
      tasks.add(_connectHostPool(hostPool, connectionErrors));
    }
    await Future.wait(tasks);

    var masterConnection = _masterConnection;
    if (masterConnection == null) {
      if (connectionErrors.isNotEmpty) {
        for (var error in connectionErrors) {
          _log.severe('$error');
        }
        // Simply returns the first exception to be more compatible
        // with previous error management.
        throw connectionErrors.first;
      }
      throw MongoDartError('No Primary found');
    }

    await _authenticateConnection(masterConnection);

    if (connectionErrors.isNotEmpty) {
      for (var error in connectionErrors) {
        _log.warning('$error');
      }
    }
    if (unfilled(db.databaseName)) {
      throw MongoDartError('Database name not specified');
    }
    db.state = State.open;

    if (_masterConnection!.serverCapabilities.supportsOpMsg) {
      await ServerStatusCommand(db,
              serverStatusOptions: ServerStatusOptions.instance)
          .updateServerStatus(db.masterConnection);
    }

    // Pre-warm authenticated standby connections without blocking startup.
    _warmStandbyConnections();
  }

  Future<void> _connectHostPool(
      _HostConnectionPool hostPool, List<Object> connectionErrors) async {
    var queue = Queue<Connection>.from(hostPool.connections);
    var workers = <Future<void>>[];
    for (var i = 0; i < hostPool.maxConnecting; i++) {
      workers.add(() async {
        while (queue.isNotEmpty) {
          var connection = queue.removeFirst();
          try {
            await _connect(connection, authenticate: false);
          } catch (e) {
            connectionErrors.add(e);
          }
        }
      }());
    }
    await Future.wait(workers);
  }

  Future<void> refreshTopology() async {
    var inProgress = _topologyRefreshInProgress;
    if (inProgress != null) {
      await inProgress;
      return;
    }
    final completer = Completer<void>();
    _topologyRefreshInProgress = completer.future;
    try {
      await _refreshTopologyInternal();
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      if (identical(_topologyRefreshInProgress, completer.future)) {
        _topologyRefreshInProgress = null;
      }
    }
  }

  Future<void> _refreshTopologyInternal() async {
    if (_closed || !identical(db._connectionManager, this)) {
      return;
    }

    var currentMaster = _masterConnection;
    if (currentMaster != null &&
        !currentMaster._closed &&
        currentMaster.connected) {
      try {
        var stillMaster = await _refreshConnectionRole(currentMaster,
            authenticateIfMaster: true);
        if (stillMaster) {
          _warmStandbyConnections();
          return;
        }
      } catch (error) {
        _log.finer(() => 'Master refresh failed: $error');
      }
    }

    _masterConnection = null;
    var promoted = await _tryPromoteConnectedMaster();
    if (!promoted) {
      _ensureMasterRecovery();
    } else {
      _warmStandbyConnections();
    }
  }

  Future<void> handleSocketError(
      Connection failedConnection, ConnectionException exception) async {
    if (_closed || !identical(db._connectionManager, this)) {
      return;
    }
    if (identical(failedConnection, _masterConnection)) {
      _masterConnection = null;
      _ensureMasterRecovery(excluding: failedConnection);
    }
    _recoverConnectionInBackground(failedConnection);
  }

  Future close({Object? error}) async {
    _closed = true;
    _authInProgressByHost.clear();
    _masterRecoveryInProgress = null;
    _topologyRefreshInProgress = null;
    _recoveringConnections.clear();
    _masterConnection = null;

    for (var hostPool in _connectionPool.values) {
      for (var connection in hostPool.connections) {
        _log.finer(() => '$db: ${connection.serverConfig.hostUrl} closed');
        try {
          await connection.close();
        } catch (error) {
          _log.warning(
              () => 'Error closing ${connection.serverConfig.hostUrl}: '
                  '$error');
        }
      }
    }
  }

  void _warmStandbyConnections() {
    if (!db.prewarmStandbyConnections) {
      return;
    }
    for (var connection in _allConnections) {
      if (!identical(connection, _masterConnection)) {
        _recoverConnectionInBackground(connection);
      }
    }
  }

  void _ensureMasterRecovery({Connection? excluding}) {
    if (_closed ||
        db._explicitlyClosed ||
        !identical(db._connectionManager, this) ||
        _masterRecoveryInProgress != null) {
      return;
    }
    final completer = Completer<void>();
    _masterRecoveryInProgress = completer.future;
    () async {
      try {
        var promoted = await _tryPromoteConnectedMaster(excluding: excluding);
        if (!promoted &&
            !_closed &&
            !db._explicitlyClosed &&
            identical(db._connectionManager, this)) {
          // Keep SDAM-style recovery in-process while any host is still
          // connected. A full reconnect is reserved for total connectivity loss.
          if (!hasAnyConnectedServer) {
            // ignore: unawaited_futures
            db._reconnect().catchError((error) {
              _log.warning(() => 'Background reconnect failed: $error');
            });
          } else {
            _log.finer(() => 'Master recovery waiting for election; '
                'connected hosts available, skipping full reconnect.');
          }
        }
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        if (identical(_masterRecoveryInProgress, completer.future)) {
          _masterRecoveryInProgress = null;
        }
      }
    }();
  }

  Future<bool> _tryPromoteConnectedMaster({Connection? excluding}) async {
    for (var connection in _allConnections) {
      if (identical(connection, excluding) ||
          connection._closed ||
          !connection.connected) {
        continue;
      }
      try {
        var isMaster = await _refreshConnectionRole(connection,
            authenticateIfMaster: true);
        if (isMaster) {
          return true;
        }
      } catch (error) {
        if (!_closed &&
            identical(db._connectionManager, this) &&
            !_isExpectedConnectionChurn(error)) {
          _log.finer(() =>
              'Master promotion probe failed for ${connection.serverConfig.hostUrl}: $error');
        }
      }
    }
    return false;
  }

  Future<bool> _refreshConnectionRole(Connection connection,
      {bool authenticateIfMaster = false}) async {
    if (_closed ||
        !identical(db._connectionManager, this) ||
        connection._closed ||
        !connection.connected) {
      return false;
    }
    var helloCommand = HelloCommand(db,
        username: connection.serverConfig.userName,
        clientMetadata: connection.serverConfig.clientMetadata,
        connection: connection);
    var result = await helloCommand.execute(skipStateCheck: true);
    if (_isServerCommandNotOk(result[keyOk])) {
      return false;
    }
    var resultDoc = HelloResult(result);
    var master = resultDoc.isWritablePrimary;
    connection.isMaster = master;
    connection.serverCapabilities.getParamsFromHello(resultDoc);
    if (!master) {
      return false;
    }
    if (authenticateIfMaster) {
      await _authenticateConnection(connection);
    }
    _masterConnection = connection;
    _cacheMasterCapabilities(connection);
    MongoModernMessage.maxBsonObjectSize = resultDoc.maxBsonObjectSize;
    MongoModernMessage.maxMessageSizeBytes = resultDoc.maxMessageSizeBytes;
    MongoModernMessage.maxWriteBatchSize = resultDoc.maxWriteBatchSize;
    return true;
  }

  Future<Connection?> waitForMaster({required Duration timeout}) async {
    if (_closed ||
        db._explicitlyClosed ||
        !identical(db._connectionManager, this)) {
      return null;
    }
    var master = _connectedMaster();
    if (master != null) {
      return master;
    }

    final deadline = DateTime.now().add(timeout);
    var topologyRefreshed = false;
    while (!_closed &&
        !db._explicitlyClosed &&
        identical(db._connectionManager, this)) {
      master = _connectedMaster();
      if (master != null) {
        return master;
      }

      if (!topologyRefreshed) {
        topologyRefreshed = true;
        try {
          await refreshTopology();
        } catch (error) {
          _log.finer(() => 'Server selection refresh failed: $error');
        }
      }

      master = _connectedMaster();
      if (master != null) {
        return master;
      }
      if (DateTime.now().isAfter(deadline)) {
        return null;
      }

      for (var connection in _allConnections) {
        _recoverConnectionInBackground(connection);
      }
      _ensureMasterRecovery();

      var remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        return null;
      }
      var pauseDuration = remaining < const Duration(milliseconds: 100)
          ? remaining
          : const Duration(milliseconds: 100);
      var recoveryFuture = _masterRecoveryInProgress;
      if (recoveryFuture != null) {
        try {
          await Future.any<void>(<Future<void>>[
            recoveryFuture,
            Future<void>.delayed(pauseDuration)
          ]);
        } catch (_) {
          await Future<void>.delayed(pauseDuration);
        }
      } else {
        await Future<void>.delayed(pauseDuration);
      }
    }
    return null;
  }

  void _recoverConnectionInBackground(Connection connection) {
    if (_closed ||
        db._explicitlyClosed ||
        !identical(db._connectionManager, this)) {
      return;
    }
    if (_recoveringConnections.contains(connection)) {
      return;
    }
    _recoveringConnections.add(connection);
    () async {
      var attempt = 0;
      try {
        while (!_closed &&
            !db._explicitlyClosed &&
            identical(db._connectionManager, this)) {
          try {
            attempt++;
            if (connection._closed || !connection.connected) {
              await _connect(connection, authenticate: false);
            } else {
              await _refreshConnectionRole(connection,
                  authenticateIfMaster: false);
            }
            // Pre-auth healthy sockets in the background to reduce failover latency.
            await _authenticateConnection(connection);
            return;
          } catch (error) {
            if (_closed ||
                db._explicitlyClosed ||
                !identical(db._connectionManager, this)) {
              return;
            }
            if (!_isExpectedConnectionChurn(error)) {
              _log.warning(() =>
                  'Background host recovery failed for ${connection.serverConfig.hostUrl} (attempt $attempt): $error');
            }
            var delayMs = min(100 * (1 << min(attempt, 6)), 5000).toInt();
            var jitterMs = Random().nextInt((delayMs ~/ 2) + 1);
            await Future.delayed(Duration(milliseconds: delayMs + jitterMs));
          }
        }
      } catch (error) {
        if (!_closed &&
            identical(db._connectionManager, this) &&
            !_isExpectedConnectionChurn(error)) {
          _log.warning(() =>
              'Background host recovery aborted for ${connection.serverConfig.hostUrl}: $error');
        }
      } finally {
        _recoveringConnections.remove(connection);
      }
    }();
  }

  Connection addConnection(ServerConfig serverConfig) {
    var hostPool = _HostConnectionPool(this, serverConfig);
    _connectionPool[serverConfig.hostUrl] = hostPool;
    return hostPool.ensureOneConnection();
  }

  Connection? removeConnection(Connection connection) {
    unawaited(connection.close());
    if (connection.isMaster) {
      _masterConnection = null;
    }
    var hostPool = _connectionPool[connection.serverConfig.hostUrl];
    if (hostPool == null) {
      return null;
    }
    hostPool.remove(connection);
    if (hostPool.isEmpty) {
      _connectionPool.remove(connection.serverConfig.hostUrl);
    }
    return connection;
  }

  /// Visible for testing: seeds a specific connection into the host pool.
  void debugAddConnection(Connection connection) {
    var hostPool = _connectionPool.putIfAbsent(connection.serverConfig.hostUrl,
        () => _HostConnectionPool(this, connection.serverConfig));
    if (!hostPool._connections.contains(connection)) {
      hostPool._connections.add(connection);
    }
  }

  /// Visible for testing: overrides the current primary connection.
  void debugSetMasterConnection(Connection? connection) {
    _masterConnection = connection;
  }

  /// Visible for testing: reports pooled connection count for a host.
  int debugConnectionCountForHost(String hostUrl) {
    return _connectionPool[hostUrl]?._connections.length ?? 0;
  }
}

class _HostConnectionPool {
  final ConnectionManager manager;
  final ServerConfig _prototypeConfig;
  final List<Connection> _connections = <Connection>[];
  static const Duration _provisionThrottleWindow = Duration(milliseconds: 100);
  int _provisioningConnections = 0;
  DateTime? _lastProvisionStartedAt;

  _HostConnectionPool(this.manager, ServerConfig serverConfig)
      : _prototypeConfig = ServerConfig.clone(serverConfig);

  int get _maxPoolSize => max(1, _prototypeConfig.maxPoolSize);

  int get maxConnecting =>
      min(_maxPoolSize, max(1, _prototypeConfig.maxConnecting));

  Iterable<Connection> get connections => _connections;

  bool get isEmpty => _connections.isEmpty;

  Connection ensureOneConnection() {
    if (_connections.isEmpty) {
      _connections.add(_newConnection());
    }
    return _connections.first;
  }

  void ensureMaxConnections() {
    while (_connections.length < _maxPoolSize) {
      _connections.add(_newConnection());
    }
  }

  void remove(Connection connection) {
    _connections.remove(connection);
  }

  Connection? selectLeastBusyConnection({required bool requireAuthentication}) {
    Connection? selected;
    var selectedPendingCount = 1 << 30;
    for (var connection in _connections) {
      if (connection._closed || !connection.connected) {
        continue;
      }
      if (requireAuthentication &&
          manager._requiresAuthentication(connection) &&
          !connection.serverConfig.isAuthenticated) {
        continue;
      }
      var pendingCount = connection.pendingRequestCount;
      if (selected == null || pendingCount < selectedPendingCount) {
        selected = connection;
        selectedPendingCount = pendingCount;
      }
    }
    _maybeProvisionConnection(
        selected: selected,
        selectedPendingCount: selectedPendingCount,
        requireAuthentication: requireAuthentication);
    return selected;
  }

  void _maybeProvisionConnection(
      {required Connection? selected,
      required int selectedPendingCount,
      required bool requireAuthentication}) {
    if (_connections.length + _provisioningConnections >= _maxPoolSize) {
      return;
    }
    if (_provisioningConnections >= maxConnecting) {
      return;
    }
    var scaleThreshold = max(1, _prototypeConfig.maxInFlightRequests ~/ 16);
    var shouldScale =
        selected == null || selectedPendingCount >= scaleThreshold;
    if (!shouldScale) {
      return;
    }
    var now = DateTime.now();
    var lastProvisionStartedAt = _lastProvisionStartedAt;
    if (lastProvisionStartedAt != null &&
        now.difference(lastProvisionStartedAt) < _provisionThrottleWindow) {
      return;
    }
    _lastProvisionStartedAt = now;
    _provisioningConnections++;
    var newConnection = _newConnection();
    _connections.add(newConnection);
    unawaited(() async {
      try {
        await manager._connect(newConnection, authenticate: false);
        if (requireAuthentication &&
            manager._requiresAuthentication(newConnection)) {
          await manager._authenticateConnection(newConnection);
        }
      } catch (_) {
        manager._recoverConnectionInBackground(newConnection);
      } finally {
        _provisioningConnections = max(0, _provisioningConnections - 1);
      }
    }());
  }

  Connection _newConnection() {
    return Connection(manager, ServerConfig.clone(_prototypeConfig));
  }
}
