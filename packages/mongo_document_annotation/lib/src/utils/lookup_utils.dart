import '../../mongo_document_annotation.dart';

List<Lookup> remapLookups(
  List<Lookup> lookups,
  Map<String, String> fieldMappings,
) {
  if (lookups.isEmpty || fieldMappings.isEmpty) {
    return lookups;
  }

  return lookups
      .map((lookup) => _remapLookup(lookup, fieldMappings))
      .toList(growable: false);
}

Lookup _remapLookup(Lookup lookup, Map<String, String> fieldMappings) {
  return Lookup(
    from: lookup.from,
    localField:
        lookup.localField == null
            ? null
            : _remapFieldPath(lookup.localField!, fieldMappings),
    foreignField: lookup.foreignField,
    as: _remapFieldPath(lookup.as, fieldMappings),
    limit: lookup.limit,
    sort: lookup.sort,
    where: lookup.where,
    resultType: lookup.resultType,
    nestedLookups:
        lookup.nestedLookups == null
            ? null
            : remapLookups(lookup.nestedLookups!, fieldMappings),
    unsetFields: lookup.unsetFields,
  );
}

String _remapFieldPath(String path, Map<String, String> fieldMappings) {
  if (path.isEmpty) {
    return path;
  }

  final parts = path.split('.');
  final first = parts.first;
  final mappedFirst = fieldMappings[first] ?? first;
  if (parts.length == 1) {
    return mappedFirst;
  }
  return [mappedFirst, ...parts.skip(1)].join('.');
}

(bool, List<Map<String, Object>>) mergeLookups({
  required List<Lookup> lookups,
  List<Map<String, Object>>? existingPipeline,
  Map<String, dynamic>? queryMap,
  (String, Object)? sort,
  int? skip,
  int? limit,
}) {
  if (lookups.isEmpty) {
    if (existingPipeline != null && existingPipeline.isNotEmpty) {
      return (true, existingPipeline);
    }
    return (false, []);
  }

  final pipeline = <Map<String, Object>>[];

  if (existingPipeline != null && existingPipeline.isNotEmpty) {
    pipeline.addAll(existingPipeline);
  } else if (queryMap != null && queryMap.isNotEmpty) {
    pipeline.add({'\$match': queryMap});

    if (sort != null) {
      pipeline.add({
        '\$sort': {sort.$1: sort.$2},
      });
    }

    if (skip != null && skip > 0) {
      pipeline.add({'\$skip': skip});
    }

    if (limit != null && limit > 0) {
      pipeline.add({'\$limit': limit});
    }
  }

  for (final lookup in lookups) {
    final genericLookupIndex = _findGenericLookupIndex(pipeline, lookup.as);
    if (genericLookupIndex == null) {
      continue;
    }

    pipeline.removeAt(genericLookupIndex);
    if (genericLookupIndex < pipeline.length) {
      final nextStage = pipeline[genericLookupIndex];
      if (_isImplicitUnwindFor(nextStage, lookup.as)) {
        pipeline.removeAt(genericLookupIndex);
      }
    }
    pipeline.insertAll(genericLookupIndex, lookup.buildPipeline());
  }

  final existingLookupFields = <String>{};
  for (final stage in pipeline) {
    if (stage.containsKey('\$lookup')) {
      final lookupData = stage['\$lookup'] as Map<String, Object>;
      if (lookupData.containsKey('as')) {
        existingLookupFields.add(lookupData['as'] as String);
      }
    }
  }

  final lookupsToAdd =
      lookups.where((lookup) {
        return !existingLookupFields.contains(lookup.as);
      }).toList();

  if (lookupsToAdd.isEmpty) {
    return (true, pipeline);
  }

  int insertPosition = pipeline.length;
  for (int i = 0; i < pipeline.length; i++) {
    if (pipeline[i].containsKey('\$project')) {
      insertPosition = i;
      break;
    }
  }

  final masterProjectMap = <String, Object>{};

  for (int i = pipeline.length - 1; i >= insertPosition; i--) {
    final stage = pipeline[i];
    if (stage.containsKey('\$project')) {
      final projectFields = stage['\$project'] as Map<String, Object>;
      projectFields.forEach((key, value) {
        masterProjectMap.putIfAbsent(key, () => value);
      });
      pipeline.removeAt(i);
    }
  }

  final lookupAsFields = lookupsToAdd.map((l) => l.as).toSet();

  final List<Map<String, Object>> stagesToInsert = [];
  for (final lookup in lookupsToAdd) {
    final lookupStages = lookup.buildPipeline();

    for (final stage in lookupStages) {
      if (stage.containsKey('\$project')) {
        final lookupProjectMap = stage['\$project'] as Map<String, Object>;

        lookupProjectMap.forEach((key, value) {
          masterProjectMap.putIfAbsent(key, () => value);
        });
      } else {
        stagesToInsert.add(stage);
      }
    }
  }

  pipeline.insertAll(insertPosition, stagesToInsert);

  if (masterProjectMap.isNotEmpty) {
    bool isInclusionProject = masterProjectMap.values.any((v) => v == 1);

    if (isInclusionProject) {
      for (final asField in lookupAsFields) {
        bool hasSubProjection = masterProjectMap.keys.any(
          (key) => key.startsWith('$asField.') && key.length > asField.length,
        );

        if (!hasSubProjection) {
          masterProjectMap.putIfAbsent(asField, () => 1);
        }
      }
    }
  }

  if (masterProjectMap.isNotEmpty) {
    pipeline.add({'\$project': masterProjectMap});
  }

  return (true, pipeline);
}

int? _findGenericLookupIndex(
  List<Map<String, Object>> pipeline,
  String asField,
) {
  for (var index = 0; index < pipeline.length; index++) {
    final stage = pipeline[index];
    if (!stage.containsKey('\$lookup')) {
      continue;
    }
    final lookupData = stage['\$lookup'] as Map<String, Object>;
    if (lookupData['as'] != asField) {
      continue;
    }
    final isImplicitLookup =
        lookupData.containsKey('localField') &&
        lookupData.containsKey('foreignField') &&
        !lookupData.containsKey('pipeline') &&
        !lookupData.containsKey('let');
    if (isImplicitLookup) {
      return index;
    }
  }
  return null;
}

bool _isImplicitUnwindFor(Map<String, Object> stage, String asField) {
  if (!stage.containsKey('\$unwind')) {
    return false;
  }
  final unwindData = stage['\$unwind'] as Map<String, Object>;
  return unwindData['path'] == '\$$asField';
}
