(bool, List<Map<String, Object>>) toAggregationPipelineWithMap({
  Map<String, String> lookupRef = const {},
  Map<String, dynamic>? projections,
  required Map<String, dynamic> raw,
  (String, int) sort = const ("created_at", -1),
  int limit = 10,
  int? skip,
  required Map<String, dynamic> cleaned,
}) {
  final prefixes = <String>{};
  var lookupsCreated = false;

  scan(lookupRef, prefixes, raw);

  if (projections != null) {
    for (final projKey in projections.keys) {
      if (projKey.contains('.')) {
        final parts = projKey.split('.');
        for (var i = 1; i < parts.length; i++) {
          final prefix = parts.sublist(0, i).join('.');
          if (lookupRef.containsKey(prefix) && lookupRef[prefix]!.isNotEmpty) {
            prefixes.add(prefix);
          }
        }
      }
    }
  }

  var stages = <Map<String, Object>>[];
  stages.add({r'$match': cleaned});
  stages.add({
    r'$sort': {sort.$1: sort.$2},
  });
  if (skip != null) {
    stages.add({r'$skip': skip});
  }
  stages.add({r'$limit': limit});

  for (final prefix in prefixes) {
    lookupsCreated = true;
    stages.add({
      r'$lookup': {
        'from': lookupRef[prefix]!,
        'localField': prefix,
        'foreignField': '_id',
        'as': prefix,
      },
    });
    stages.add({
      r'$unwind': {'path': '\$$prefix', 'preserveNullAndEmptyArrays': true},
    });
  }
  if (projections != null && projections.isNotEmpty) {
    final projectionKeys = projections.keys;
    final refined = <Map<String, Object>>[...stages];
    for (final stage in stages) {
      if (stage.containsKey(r'$lookup')) {
        final asField = (stage[r'$lookup'] as Map)['as'] as String;
        final hasMatch = projectionKeys.any((k) => k.startsWith('$asField.'));
        if (!hasMatch) {
          refined.remove(stage);
          continue;
        }
      }
      if (stage.containsKey(r'$unwind')) {
        final path = (stage[r'$unwind'] as Map)['path'] as String;
        final prefix = path.startsWith(r'$') ? path.substring(1) : path;
        final hasMatch = projectionKeys.any((k) => k.startsWith('$prefix.'));
        if (!hasMatch) {
          refined.remove(stage);
          continue;
        }
      }
    }
    stages = refined;
    final includeProj = <String, Object>{};
    final excludes = <String>[];
    projections.forEach((key, value) {
      if (value == 0 || value == false) {
        excludes.add(key);
      } else {
        includeProj[key] = value;
      }
    });
    if (includeProj.isNotEmpty) {
      stages.add({r'$project': includeProj});
    }
    if (excludes.isNotEmpty) {
      stages.add({r'$unset': excludes.length == 1 ? excludes.first : excludes});
    }
  } else {
    lookupsCreated = false;
  }
  return (lookupsCreated, stages);
}

void scan(Map<String, String> lookupRef, Set<String> prefixes, dynamic node) {
  if (node is Map<String, dynamic>) {
    for (final entry in node.entries) {
      final key = entry.key;
      if (key.contains('.')) {
        final parts = key.split('.');
        for (var i = 1; i < parts.length; i++) {
          final prefix = parts.sublist(0, i).join('.');
          if (lookupRef.containsKey(prefix) && lookupRef[prefix]!.isNotEmpty) {
            prefixes.add(prefix);
          }
        }
      }
      scan(lookupRef, prefixes, entry.value);
    }
  } else if (node is Iterable) {
    for (final item in node) {
      scan(lookupRef, prefixes, item);
    }
  }
}

Map<String, dynamic> sanitizedDocument(Map<String, dynamic> map) {
  final dateFields = {
    'created_at',
    'updated_at',
    'expire_at',
    'expires_at',
    'deleted_at',
    'published_at',
    'scheduled_at',
    'last_login',
    'last_seen',
    'verified_at',
    'confirmed_at',
    'reset_at',
  };

  final dateFieldPattern = RegExp(
    r'.*(_at|_date|_time|Date|Time)$',
    caseSensitive: false,
  );
  final result = <String, dynamic>{};
  map.forEach((key, value) {
    if (value == null) {
      result[key] = value;
      return;
    }
    final shouldBeDateTime =
        dateFields.contains(key) || dateFieldPattern.hasMatch(key);
    if (shouldBeDateTime && value is String) {
      try {
        final parsedDate = DateTime.parse(value);
        result[key] = parsedDate;
      } catch (e) {
        result[key] = value;
      }
    } else if (value is Map<String, dynamic>) {
      result[key] = sanitizedDocument(value);
    } else if (value is List) {
      result[key] =
          value.map((item) {
            if (item is Map<String, dynamic>) {
              return sanitizedDocument(item);
            }
            return item;
          }).toList();
    } else {
      result[key] = value;
    }
  });
  return result;
}

Map<String, dynamic> ensureSpecificDateFields(
  Map<String, dynamic> map,
  List<String> dateFields,
) {
  final result = <String, dynamic>{...map};
  for (final fieldName in dateFields) {
    final value = result[fieldName];
    if (value != null && value is String) {
      try {
        result[fieldName] = DateTime.parse(value);
      } catch (e) {
        //
      }
    }
  }
  return result;
}
