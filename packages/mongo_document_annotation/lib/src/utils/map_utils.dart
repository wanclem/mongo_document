(bool, List<Map<String, Object>>) toAggregationPipelineWithMap({
  Map<String, String> lookupRef = const {},
  Map<String, dynamic>? projections,
  required Map<String, dynamic> raw,
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

  final stages = <Map<String, Object>>[];
  stages.add({r'$match': cleaned});

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
      r'$unwind': {
        'path': '\$$prefix',
        'preserveNullAndEmptyArrays': true,
      },
    });
  }

  if (projections != null && projections.isNotEmpty) {
    stages.add({r'$project': projections});
  }

  return (lookupsCreated, stages);
}

void scan(
  Map<String, String> lookupRef,
  Set<String> prefixes,
  dynamic node,
) {
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
