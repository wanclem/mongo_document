import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';

class MongoDbConnection {
  static Db? _instance;

  MongoDbConnection._();

  static Future<Db> get instance async {
    if (_instance == null) {
      throw Exception(
        "Database not initialized. Please call initialize() first.",
      );
    }
    if (!_instance!.isConnected) {
      await _instance!.open(secure: true);
    }
    return _instance!;
  }

  static Future<void> initialize(String? databaseUri) async {
    try {
      if (databaseUri == null) {
        throw Exception("Database URI is not set");
      }
      if (_instance != null) {
        throw Exception("Database already initialized.");
      }
      _instance = databaseUri.startsWith('mongodb+srv://')
          ? await Db.create(databaseUri)
          : Db(databaseUri);
      await _instance?.open(secure: true);
    } catch (e) {
      print("Db Error $e");
      exit(0);
    }
  }

  static Future<void> shutdownDb() async {
    var db = await MongoDbConnection.instance;
    await db.close();
  }

  static Future<DbCollection> getCollection(String collectionName) async {
    var db = await MongoDbConnection.instance;
    return db.collection(collectionName);
  }
}
