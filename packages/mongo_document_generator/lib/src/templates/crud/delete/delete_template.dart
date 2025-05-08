class DeleteTemplates {
  static delete(String className) {
    return '''
Future<bool> delete() async {
    if (id == null) return false;
    final res = await (await MongoConnection.getDb())
      .collection(_collection)
      .deleteOne(where.eq(r'_id', id));
    return res.isSuccess;
  }
''';
  }
}
