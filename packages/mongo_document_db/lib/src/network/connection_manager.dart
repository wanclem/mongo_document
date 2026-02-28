part of '../../mongo_document_db.dart';

class ConnectionManager {
  final _log = Logger('ConnectionManager');
  final Db db;
  final _connectionPool = <String, Connection>{};
  Connection? _masterConnection;
  bool _lastMasterSupportsOpMsg;
  bool _lastMasterSupportsListCollections;
  bool _lastMasterSupportsListIndexes;
  final Set<String> _recoveringHosts = <String>{};
  Future<void>? _masterRecoveryInProgress;
  bool _closed = false;

  ConnectionManager(this.db,
      {bool lastMasterSupportsOpMsg = false,
      bool lastMasterSupportsListCollections = false,
      bool lastMasterSupportsListIndexes = false})
      : _lastMasterSupportsOpMsg = lastMasterSupportsOpMsg,
        _lastMasterSupportsListCollections = lastMasterSupportsListCollections,
        _lastMasterSupportsListIndexes = lastMasterSupportsListIndexes;

  Connection? get masterConnection => _masterConnection;

  bool get supportsOpMsg =>
      _masterConnection?.serverCapabilities.supportsOpMsg ??
      _lastMasterSupportsOpMsg;

  bool get supportsListCollections =>
      _masterConnection?.serverCapabilities.listCollections ??
      _lastMasterSupportsListCollections;

  bool get supportsListIndexes =>
      _masterConnection?.serverCapabilities.listIndexes ??
      _lastMasterSupportsListIndexes;

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

  Connection get masterConnectionVerified {
    var master = _connectedMaster();
    if (master != null) {
      return master;
    } else {
      throw MongoDartError('No master connection');
    }
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
        _masterConnection = connection;
        _cacheMasterCapabilities(connection);
        MongoModernMessage.maxBsonObjectSize = resultDoc.maxBsonObjectSize;
        MongoModernMessage.maxMessageSizeBytes = resultDoc.maxMessageSizeBytes;
        MongoModernMessage.maxWriteBatchSize = resultDoc.maxWriteBatchSize;
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
      _log.fine(() => documents.first.toString());
      var master = documents.first['ismaster'] == true;
      connection.isMaster = master;
      connection.serverCapabilities.getParamsFromIstMaster(documents.first);
      if (master) {
        if (authenticate) {
          await _authenticateConnection(connection);
        }
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
    for (var connection in _connectionPool.values) {
      tasks.add(() async {
        try {
          await _connect(connection, authenticate: false);
        } catch (e) {
          connectionErrors.add(e);
        }
      }());
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

  Future<void> refreshTopology() async {
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
        _log.fine(() => 'Master refresh failed: $error');
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
    _masterRecoveryInProgress = null;
    _recoveringHosts.clear();
    _masterConnection = null;

    for (var hostUrl in _connectionPool.keys) {
      var connection = _connectionPool[hostUrl];
      _log.fine(() => '$db: ${connection?.serverConfig.hostUrl} closed');
      try {
        await connection?.close();
      } catch (error) {
        _log.fine(() => 'Error closing ${connection?.serverConfig.hostUrl}: '
            '$error');
      }
    }
  }

  void _warmStandbyConnections() {
    for (var connection in _connectionPool.values) {
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
          // Fallback to full reconnect if no connected host can be promoted.
          // ignore: unawaited_futures
          db._reconnect().catchError((error) {
            _log.fine(() => 'Background reconnect failed: $error');
          });
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
    for (var connection in _connectionPool.values) {
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
        _log.fine(() =>
            'Master promotion probe failed for ${connection.serverConfig.hostUrl}: $error');
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
          _log.fine(() => 'Server selection refresh failed: $error');
        }
      }

      master = _connectedMaster();
      if (master != null) {
        return master;
      }
      if (DateTime.now().isAfter(deadline)) {
        return null;
      }

      for (var connection in _connectionPool.values) {
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
    var hostUrl = connection.serverConfig.hostUrl;
    if (_recoveringHosts.contains(hostUrl)) {
      return;
    }
    _recoveringHosts.add(hostUrl);
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
            _log.fine(() =>
                'Background host recovery failed for $hostUrl (attempt $attempt): $error');
            var delayMs = min(100 * (1 << min(attempt, 6)), 5000).toInt();
            var jitterMs = Random().nextInt((delayMs ~/ 2) + 1);
            await Future.delayed(Duration(milliseconds: delayMs + jitterMs));
          }
        }
      } catch (error) {
        _log.fine(
            () => 'Background host recovery aborted for $hostUrl: $error');
      } finally {
        _recoveringHosts.remove(hostUrl);
      }
    }();
  }

  void addConnection(ServerConfig serverConfig) {
    var connection = Connection(this, serverConfig);
    _connectionPool[serverConfig.hostUrl] = connection;
  }

  Connection? removeConnection(Connection connection) {
    unawaited(connection.close());
    if (connection.isMaster) {
      _masterConnection = null;
    }
    return _connectionPool.remove(connection.serverConfig.hostUrl);
  }
}
