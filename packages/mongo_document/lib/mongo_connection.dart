import 'package:mongo_dart/mongo_dart.dart';

class MongoConnection {
  static Db? _db;
  static late String _uri;

  static Future<void> init(String uri) async {
    _uri = uri;
    await _connect();
  }

  static Future<void> _connect() async {
    if (_uri.startsWith('mongodb+srv://')) {
      _db = await Db.create(_uri);
    } else {
      _db = Db(_uri);
    }
    await _db!.open();
  }

  static Future<Db> getDb() async {
    if (_db == null || _db!.state != State.open) {
      await _connect();
    }
    return _db!;
  }
}
