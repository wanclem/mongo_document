import '../../mongo_document_annotation.dart';

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
    if (pipeline[i].containsKey('\$project') ||
        pipeline[i].containsKey('\$skip') ||
        pipeline[i].containsKey('\$limit')) {
      insertPosition = i;
      break;
    }
  }

  final List<Map<String, Object>> savedTerminalStages = [];

  final masterProjectMap = <String, Object>{};

  for (int i = pipeline.length - 1; i >= insertPosition; i--) {
    final stage = pipeline[i];
    if (stage.containsKey('\$project')) {
      final projectFields = stage['\$project'] as Map<String, Object>;
      projectFields.forEach((key, value) {
        masterProjectMap.putIfAbsent(key, () => value);
      });
      pipeline.removeAt(i);
    } else if (stage.containsKey('\$limit') || stage.containsKey('\$skip')) {
      savedTerminalStages.insert(0, pipeline.removeAt(i));
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

  pipeline.addAll(savedTerminalStages);

  return (true, pipeline);
}
