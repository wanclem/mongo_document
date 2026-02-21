part of '../../mongo_document_db.dart';

class _Statics {
  static int? _requestId;
  static const _maxRequestId = 0x7ffffffe;
  static int get nextRequestId {
    if (_requestId == null ||
        _requestId! <= 0 ||
        _requestId! >= _maxRequestId) {
      _requestId = Random().nextInt(_maxRequestId - 1) + 1;
    } else {
      _requestId = _requestId! + 1;
    }
    return _requestId!;
  }
}

class MongoMessage {
  static final reply = 1;
  static final message = 1000;
  static final update = 2001;
  static final insert = 2002;
  static final query = 2004;
  static final getMore = 2005;
  static final delete = 2006;
  static final killCursors = 2007;
  static final modernMessage = 2013;

  int? _requestId;
  int _messageLength = 0;

  int get messageLength => _messageLength;

  int get requestId {
    _requestId ??= _Statics.nextRequestId;

    return _requestId!;
  }

  int responseTo = 0;
  int opcode = MongoMessage.reply;

  BsonBinary serialize() => throw MongoDartError('Must be implemented');

/*  void deserialize(BsonBinary buffer) {
    throw MongoDartError('Must be implemented');
  }*/

  void readMessageHeaderFrom(BsonBinary buffer) {
    _messageLength = buffer.readInt32();
    _requestId = buffer.readInt32();
    responseTo = buffer.readInt32();
    var opcodeFromWire = buffer.readInt32();
    if (opcodeFromWire != opcode) {
      throw MongoDartError(
          'Expected $opcode in Message header. Got $opcodeFromWire');
    }
  }

  void writeMessageHeaderTo(BsonBinary buffer) {
    buffer.writeInt(messageLength); // messageLength will be backpatched later
    buffer.writeInt(requestId);
    buffer.writeInt(0); // responseTo not used in requests sent by client
    buffer.writeInt(opcode);
    if (messageLength < 0) {
      throw MongoDartError('Error in message length');
    }
  }

  @override
  String toString() => throw MongoDartError('must be implemented');
}
