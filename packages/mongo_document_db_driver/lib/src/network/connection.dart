part of '../../mongo_document_db_driver.dart';

const noSecureRequestError = 'The socket connection has been reset by peer.'
    '\nPossible causes:'
    '\n- Trying to connect to an ssl/tls encrypted database without specifying'
    '\n  either the query parm tls=true '
    'or the secure=true parameter in db.open()'
    '\n- The server requires a key certificate from the client, '
    'but no certificate has been sent'
    '\n- Others';

class ServerCapabilities {
  int minWireVersion = 0;
  int maxWireVersion = 0;
  bool aggregationCursor = false;
  bool writeCommands = false;
  bool authCommands = false;
  bool listCollections = false;
  bool listIndexes = false;
  int maxNumberOfDocsInBatch = 1000;
  bool supportsOpMsg = false;
  String? replicaSetName;
  List<String>? replicaSetHosts;
  bool get isReplicaSet => replicaSetName != null;
  int get replicaSetHostsNum => replicaSetHosts?.length ?? 0;
  bool get isSingleServerReplicaSet => isReplicaSet && replicaSetHostsNum == 1;
  bool isShardedCluster = false;
  bool isStandalone = false;
  String? fcv;

  void getParamsFromIstMaster(Map<String, dynamic> isMaster) {
    if (isMaster.containsKey('maxWireVersion')) {
      maxWireVersion = isMaster['maxWireVersion'] as int;
    }
    if (maxWireVersion >= 1) {
      aggregationCursor = true;
      authCommands = true;
    }
    if (maxWireVersion >= 2) {
      writeCommands = true;
    }
    if (maxWireVersion >= 3) {
      listCollections = true;
      listIndexes = true;
    }
    if (maxWireVersion >= 6) {
      supportsOpMsg = true;
    }
    if (isMaster.containsKey(keyMsg)) {
      isShardedCluster = true;
    } else if (isMaster.containsKey(keySetName)) {
      replicaSetName = isMaster[keySetName];
      replicaSetHosts = <String>[...isMaster[keyHosts]];
    } else {
      isStandalone = true;
    }
    if (maxWireVersion >= 13) {
      fcv = '5.0';
    } else if (isMaster.containsKey(keyTopologyVersion)) {
      fcv = '4.4';
    } else if (isMaster.containsKey(keyConnectionId)) {
      fcv = '4.2';
    } else if (maxWireVersion > 6) {
      // approximated
      fcv = '4.0';
    } else if (maxWireVersion > 5) {
      fcv = '3.6';
    } else if (maxWireVersion > 4) {
      fcv = '3.4';
    } else {
      fcv = '3.2';
    }
  }

  void getParamsFromHello(HelloResult result) {
    minWireVersion = result.minWireVersion;

    maxWireVersion = result.maxWireVersion;

    if (maxWireVersion >= 1) {
      aggregationCursor = true;
      authCommands = true;
    }
    if (maxWireVersion >= 2) {
      writeCommands = true;
    }
    if (maxWireVersion >= 3) {
      listCollections = true;
      listIndexes = true;
    }
    if (maxWireVersion >= 6) {
      supportsOpMsg = true;
    }
    if (filled(result.msg)) {
      isShardedCluster = true;
    } else if (filled(result.setName)) {
      replicaSetName = result.setName;
      replicaSetHosts = <String>[...?result.hosts];
    } else {
      isStandalone = true;
    }

    if (maxWireVersion >= 17) {
      fcv = '6.0';
    } else if (maxWireVersion >= 13) {
      fcv = '5.0';
    } else if (maxWireVersion >= 9) {
      fcv = '4.4';
    } else if (maxWireVersion >= 8) {
      fcv = '4.2';
    } else if (maxWireVersion > 6) {
      // approximated
      fcv = '4.0';
    } else if (maxWireVersion > 5) {
      fcv = '3.6';
    } else if (maxWireVersion > 4) {
      fcv = '3.4';
    } else {
      fcv = '3.2';
    }
  }
}

class Connection {
  static bool _caCertificateAlreadyInHash = false;
  final Logger _log = Logger('Connection');
  final ConnectionManager _manager;
  ServerConfig serverConfig;
  Socket? socket;
  final Set _pendingQueries = <int>{};
  final Map<int, Completer<MongoResponseMessage>> _replyCompleters = {};
  final Queue<_QueuedMessage> _sendQueue = Queue<_QueuedMessage>();
  final Map<int, Timer> _queueTimers = {};
  final Map<int, Timer> _responseTimers = {};
  int _inFlightRequests = 0;
  StreamSubscription<MongoResponseMessage>? _repliesSubscription;

  StreamSubscription<MongoResponseMessage>? get repliesSubscription =>
      _repliesSubscription;

  bool connected = false;
  bool _closed = false;
  bool isMaster = false;
  final ServerCapabilities serverCapabilities = ServerCapabilities();
  final ServerStatus serverStatus = ServerStatus();

  Connection(this._manager, [ServerConfig? serverConfig])
      : serverConfig = serverConfig ?? ServerConfig();

  bool get isAuthenticated => serverConfig.isAuthenticated;
  int get pendingRequestCount => _pendingQueries.length + _sendQueue.length;

  Future<bool> connect() async {
    _closed = false;
    connected = false;
    isMaster = false;
    serverConfig.isAuthenticated = false;
    Socket locSocket;
    try {
      if (serverConfig.isSecure) {
        var securityContext = SecurityContext.defaultContext;
        if (serverConfig.tlsCAFileContent != null &&
            !_caCertificateAlreadyInHash) {
          securityContext
              .setTrustedCertificatesBytes(serverConfig.tlsCAFileContent!);
        }
        if (serverConfig.tlsCertificateKeyFileContent != null) {
          securityContext
            ..useCertificateChainBytes(
                serverConfig.tlsCertificateKeyFileContent!)
            ..usePrivateKeyBytes(serverConfig.tlsCertificateKeyFileContent!,
                password: serverConfig.tlsCertificateKeyFilePassword);
        }

        locSocket = await SecureSocket.connect(
            serverConfig.host, serverConfig.port,
            timeout: serverConfig.connectTimeout,
            context: securityContext, onBadCertificate: (certificate) {
          // couldn't find here if the cause is an hostname mismatch
          return serverConfig.tlsAllowInvalidCertificates;
        });
      } else {
        locSocket = await Socket.connect(serverConfig.host, serverConfig.port,
            timeout: serverConfig.connectTimeout);
      }
    } on TlsException catch (err) {
      if (err.osError?.message
              .contains('CERT_ALREADY_IN_HASH_TABLE(x509_lu.c:356)') ??
          false) {
        _caCertificateAlreadyInHash = true;
        return connect();
      }
      _closed = true;
      connected = false;
      var ex = ConnectionException(
          'Could not connect to ${serverConfig.hostUrl}\n- $err');
      throw ex;
    } catch (e) {
      _closed = true;
      connected = false;
      var ex = ConnectionException(
          'Could not connect to ${serverConfig.hostUrl}\n- $e');
      throw ex;
    }

    _configureSocket(locSocket);
    // ignore: unawaited_futures
    locSocket.done.catchError((error) async {
      _log.info('Socket closed with error: $error');
      if (!_closed) {
        await _closeSocketOnError(socketError: error);
      }
    });
    socket = locSocket;

    _repliesSubscription = socket!
        .transform<MongoResponseMessage>(MongoMessageHandler().transformer)
        .listen(_receiveReply,
            onError: (err, st) async {
              _log.severe('Socket error $err $st');
              if (!_closed) {
                await _closeSocketOnError(socketError: err);
              }
            },
            cancelOnError: true,
            // onDone is not called in any case after onData or OnError,
            // it is called when the socket closes, i.e. it is an error.
            // Possible causes:
            // * Trying to connect to a tls encrypted Database
            //   without specifing tls=true in the query parms or setting
            //   the secure parameter to true in db.open()
            onDone: () async {
              if (!_closed) {
                await _closeSocketOnError(
                    socketError: serverConfig.isSecure
                        ? 'Socket closed by remote host.'
                        : noSecureRequestError);
              }
            });
    connected = true;
    return true;
  }

  void _configureSocket(Socket currentSocket) {
    try {
      currentSocket.setOption(SocketOption.tcpNoDelay, true);
    } catch (error) {
      _log.finer(() => 'Could not enable tcpNoDelay: $error');
    }
    try {
      // SO_KEEPALIVE option id differs on Linux vs BSD/Windows stacks.
      var keepAliveOption = Platform.isLinux ? 9 : 0x0008;
      currentSocket.setRawOption(RawSocketOption.fromBool(
          RawSocketOption.levelSocket, keepAliveOption, true));
    } catch (error) {
      _log.finer(() => 'Could not enable TCP keepalive: $error');
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    connected = false;
    isMaster = false;
    serverConfig.isAuthenticated = false;
    _inFlightRequests = 0;
    _failPendingQueries(const ConnectionException('Connection closed.'));
    await _repliesSubscription?.cancel();
    _repliesSubscription = null;
    await socket?.close();
    socket = null;
    return;
  }

  void _sendBuffer() {
    _log.finer(() =>
        '_sendBuffer hasQueue=${_sendQueue.isNotEmpty} inFlight=$_inFlightRequests');
    if (_sendQueue.isEmpty) {
      return;
    }
    if (socket == null) {
      throw ConnectionException('The socket has not been created yet');
    }
    // Batch multiple queued messages into one socket write. This preserves
    // single-connection semantics while reducing per-message syscall overhead.
    var buffer = BytesBuilder(copy: false);
    while (_sendQueue.isNotEmpty) {
      var queuedMessage = _sendQueue.first;
      var mongoMessage = queuedMessage.message;
      var expectsReply = _replyCompleters.containsKey(mongoMessage.requestId);
      if (expectsReply &&
          _inFlightRequests >= serverConfig.maxInFlightRequests) {
        break;
      }
      _sendQueue.removeFirst();
      _cancelQueueTimer(mongoMessage.requestId);
      if (expectsReply) {
        _inFlightRequests++;
        _startResponseTimer(mongoMessage.requestId);
      }
      buffer.add(mongoMessage.serialize().byteList);
      if (buffer.length >= (256 * 1024)) {
        break;
      }
    }
    if (buffer.length > 0) {
      socket!.add(buffer.takeBytes());
    }
  }

  Future<MongoReplyMessage> query(MongoMessage queryMessage) {
    var completer = Completer<MongoReplyMessage>();
    if (!_closed) {
      _replyCompleters[queryMessage.requestId] = completer;
      _pendingQueries.add(queryMessage.requestId);
      _log.finer(() => 'Query $queryMessage');
      _sendQueue.addLast(_QueuedMessage(queryMessage));
      _startQueueTimer(queryMessage.requestId);
      try {
        _sendBuffer();
      } catch (error) {
        _removeQueuedMessage(queryMessage.requestId);
        _cancelQueueTimer(queryMessage.requestId);
        _cancelResponseTimer(queryMessage.requestId);
        _replyCompleters.remove(queryMessage.requestId);
        _pendingQueries.remove(queryMessage.requestId);
        completer
            .completeError(ConnectionException('Error sending query: $error'));
      }
    } else {
      completer.completeError(const ConnectionException(
          'Invalid state: Connection already closed.'));
    }
    return completer.future;
  }

  ///   If runImmediately is set to false, the message is joined into one packet with
  ///   other messages that follows. This is used for joining insert, update and remove commands with
  ///   getLastError query (according to MongoDB docs, for some reason, these should
  ///   be sent 'together')

  void execute(MongoMessage mongoMessage, bool runImmediately) {
    if (_closed) {
      throw const ConnectionException(
          'Invalid state: Connection already closed.');
    }
    _log.finer(() => 'Execute $mongoMessage');
    _sendQueue.addLast(_QueuedMessage(mongoMessage));
    if (runImmediately) {
      _sendBuffer();
    }
  }

  Future<MongoModernMessage> executeModernMessage(
      MongoModernMessage modernMessage) {
    var completer = Completer<MongoModernMessage>();
    if (_closed) {
      completer.completeError(const ConnectionException(
          'Invalid state: Connection already closed.'));
    } else {
      _executeMessage(completer, modernMessage);
      /*
      if (!_closed) {
        _replyCompleters[modernMessage.requestId] = completer;
        _pendingQueries.add(modernMessage.requestId);
        _log.finer(() => 'Message $modernMessage');
        _sendQueue.addLast(modernMessage);
        _sendBuffer();
      } else {
        completer.completeError(const ConnectionException(
            'Invalid state: Connection already closed.'));
      }*/
    }

    return completer.future;
  }

  void _executeMessage(Completer<MongoResponseMessage> completer,
      MongoModernMessage modernMessage) {
    if (!_closed) {
      _replyCompleters[modernMessage.requestId] = completer;
      _pendingQueries.add(modernMessage.requestId);
      _log.finer(() => 'Message $modernMessage');
      _sendQueue.addLast(_QueuedMessage(modernMessage));
      _startQueueTimer(modernMessage.requestId);
      try {
        _sendBuffer();
      } catch (error) {
        _removeQueuedMessage(modernMessage.requestId);
        _cancelQueueTimer(modernMessage.requestId);
        _cancelResponseTimer(modernMessage.requestId);
        _replyCompleters.remove(modernMessage.requestId);
        _pendingQueries.remove(modernMessage.requestId);
        completer.completeError(
            ConnectionException('Error sending message: $error'));
      }
    } else {
      completer.completeError(const ConnectionException(
          'Invalid state: Connection already closed.'));
    }
  }

  void _receiveReply(MongoResponseMessage reply) {
    _log.finer(() => reply.toString());
    _cancelResponseTimer(reply.responseTo);
    var completer = _replyCompleters.remove(reply.responseTo);
    _pendingQueries.remove(reply.responseTo);
    if (_inFlightRequests > 0) {
      _inFlightRequests--;
    }
    if (completer != null) {
      _log.finer(() => 'Completing $reply');
      completer.complete(reply);
    } else {
      if (!_closed) {
        _log.info(() => 'Unexpected respondTo: ${reply.responseTo} $reply');
      }
    }
    if (!_closed) {
      _sendBuffer();
    }
  }

  Future<void> _closeSocketOnError({dynamic socketError}) async {
    if (_closed) {
      return;
    }
    _closed = true;
    connected = false;
    isMaster = false;
    serverConfig.isAuthenticated = false;
    _inFlightRequests = 0;
    var ex = ConnectionException(
        'connection closed${socketError == null ? '.' : ': $socketError'}');
    _failPendingQueries(ex);
    await _repliesSubscription?.cancel();
    _repliesSubscription = null;
    var currentSocket = socket;
    socket = null;
    try {
      await currentSocket?.close();
    } catch (_) {}
    await _manager.handleSocketError(this, ex);
  }

  void _failPendingQueries(ConnectionException ex) {
    for (var timer in _queueTimers.values) {
      timer.cancel();
    }
    _queueTimers.clear();
    for (var timer in _responseTimers.values) {
      timer.cancel();
    }
    _responseTimers.clear();
    for (var completer in _replyCompleters.values) {
      if (!completer.isCompleted) {
        completer.completeError(ex);
      }
    }
    _replyCompleters.clear();
    _pendingQueries.clear();
    _sendQueue.clear();
    _inFlightRequests = 0;
  }

  void _startQueueTimer(int requestId) {
    var timeout = serverConfig.waitQueueTimeout;
    if (timeout == null || timeout <= Duration.zero) {
      return;
    }
    _cancelQueueTimer(requestId);
    _queueTimers[requestId] = Timer(timeout, () {
      var removed = _removeQueuedMessage(requestId);
      if (!removed) {
        _queueTimers.remove(requestId);
        return;
      }
      _queueTimers.remove(requestId);
      var completer = _replyCompleters.remove(requestId);
      _pendingQueries.remove(requestId);
      if (completer != null && !completer.isCompleted) {
        completer.completeError(ConnectionException(
            'Operation wait queue timed out after ${timeout.inMilliseconds}ms'));
      }
      if (!_closed) {
        try {
          _sendBuffer();
        } catch (_) {}
      }
    });
  }

  void _cancelQueueTimer(int requestId) {
    _queueTimers.remove(requestId)?.cancel();
  }

  void _startResponseTimer(int requestId) {
    var timeout = serverConfig.socketTimeout;
    if (timeout == null || timeout <= Duration.zero) {
      return;
    }
    _cancelResponseTimer(requestId);
    _responseTimers[requestId] = Timer(timeout, () async {
      var completer = _replyCompleters.remove(requestId);
      _pendingQueries.remove(requestId);
      if (_inFlightRequests > 0) {
        _inFlightRequests--;
      }
      if (completer != null && !completer.isCompleted) {
        completer.completeError(ConnectionException(
            'Operation timed out after ${timeout.inMilliseconds}ms'));
      }
      if (!_closed) {
        await _closeSocketOnError(
            socketError:
                'Operation timed out after ${timeout.inMilliseconds}ms');
      }
    });
  }

  void _cancelResponseTimer(int requestId) {
    _responseTimers.remove(requestId)?.cancel();
  }

  bool _removeQueuedMessage(int requestId) {
    var originalLength = _sendQueue.length;
    _sendQueue.removeWhere(
        (queuedMessage) => queuedMessage.message.requestId == requestId);
    return _sendQueue.length != originalLength;
  }
}

class ConnectionException implements Exception {
  final String message;

  const ConnectionException([this.message = '']);

  @override
  String toString() => 'MongoDB ConnectionException: $message';
}

class _QueuedMessage {
  final MongoMessage message;

  const _QueuedMessage(this.message);
}
