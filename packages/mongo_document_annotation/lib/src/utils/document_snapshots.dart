import 'dart:collection';

import 'package:mongo_document_db_driver/mongo_document_db_driver.dart'
    show ObjectId;

import 'map_utils.dart';

final _mongoDocumentSnapshots =
    <String, LinkedHashMap<ObjectId, Map<String, dynamic>>>{};
const _maxSnapshotsPerCollection = 1000;

void rememberMongoDocumentSnapshot(
  String collection,
  Map<String, dynamic> document,
) {
  final documentId = _coerceMongoDocumentId(document['_id']);
  if (documentId == null) return;

  final collectionSnapshots = _mongoDocumentSnapshots.putIfAbsent(
    collection,
    () => LinkedHashMap<ObjectId, Map<String, dynamic>>(),
  );

  collectionSnapshots.remove(documentId);
  collectionSnapshots[documentId] = _cloneMongoMap(document);

  while (collectionSnapshots.length > _maxSnapshotsPerCollection) {
    collectionSnapshots.remove(collectionSnapshots.keys.first);
  }
}

void rememberMongoDocumentSnapshots(
  String collection,
  Iterable<Map<String, dynamic>> documents,
) {
  for (final document in documents) {
    rememberMongoDocumentSnapshot(collection, document);
  }
}

Map<String, dynamic>? mongoDocumentSnapshot(String collection, ObjectId id) {
  final collectionSnapshots = _mongoDocumentSnapshots[collection];
  final snapshot = collectionSnapshots?[id];
  if (snapshot == null) return null;
  if (collectionSnapshots != null) {
    collectionSnapshots.remove(id);
    collectionSnapshots[id] = snapshot;
  }
  return _cloneMongoMap(snapshot);
}

void forgetMongoDocumentSnapshot(String collection, ObjectId id) {
  final collectionSnapshots = _mongoDocumentSnapshots[collection];
  if (collectionSnapshots == null) return;

  collectionSnapshots.remove(id);
  if (collectionSnapshots.isEmpty) {
    _mongoDocumentSnapshots.remove(collection);
  }
}

Map<String, dynamic> buildMongoUpdateMapFromSnapshot({
  required Map<String, dynamic> current,
  Map<String, dynamic>? snapshot,
  required Iterable<String> trackedKeys,
  Iterable<String> ignoredKeys = const <String>[
    '_id',
    'created_at',
    'updated_at',
  ],
}) {
  final previous = snapshot ?? const <String, dynamic>{};
  final ignored = ignoredKeys.toSet();
  final updateMap = <String, dynamic>{};

  for (final key in trackedKeys) {
    if (ignored.contains(key)) continue;

    final hasCurrentValue = current.containsKey(key);
    final currentValue = hasCurrentValue ? current[key] : null;
    final hasPreviousValue = previous.containsKey(key);

    if (!hasPreviousValue) {
      if (hasCurrentValue && currentValue != null) {
        updateMap[key] = currentValue;
      }
      continue;
    }

    if (!mongoValuesEqual(previous[key], currentValue)) {
      updateMap[key] = currentValue;
    }
  }

  return updateMap;
}

ObjectId? _coerceMongoDocumentId(dynamic rawId) {
  if (rawId is ObjectId) return rawId;
  if (rawId is String) return ObjectId.tryParse(rawId);
  return null;
}

Map<String, dynamic> _cloneMongoMap(Map<String, dynamic> source) {
  final clone = <String, dynamic>{};
  source.forEach((key, value) {
    clone[key] = _cloneMongoValue(value);
  });
  return clone;
}

dynamic _cloneMongoValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return _cloneMongoMap(value);
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry(key, _cloneMongoValue(nestedValue)),
    );
  }
  if (value is List) {
    return value.map(_cloneMongoValue).toList();
  }
  return value;
}
