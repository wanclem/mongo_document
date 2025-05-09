import 'package:mongo_document_annotation/mongo_document_annotation.dart';

extension MongoLookupExtension on Map<String, dynamic> {
  (bool, List<Map<String, Object>>) toAggregationPipelineWithMap({
    Map<String, String> lookupRef = const {},
    Map<String, dynamic>? projections,
  }) {
    final prefixes = <String>{};
    var lookupsCreated = false;
    void scan(dynamic node) {
      if (node is Map<String, dynamic>) {
        for (final entry in node.entries) {
          final key = entry.key;
          if (key.contains('.')) {
            final parts = key.split('.');
            for (var i = 1; i < parts.length; i++) {
              final prefix = parts.sublist(0, i).join('.');
              if (lookupRef.containsKey(prefix) &&
                  lookupRef[prefix]!.isNotEmpty) {
                prefixes.add(prefix);
              }
            }
          }
          scan(entry.value);
        }
      } else if (node is Iterable) {
        for (final item in node) {
          scan(item);
        }
      }
    }

    scan(this);

    final stages = <Map<String, Object>>[];
    for (final prefix in prefixes) {
      lookupsCreated = true;
      stages.add({
        r'$lookup': {
          'from': lookupRef[prefix]!,
          'localField': prefix,
          'foreignField': '_id',
          'as': prefix,
        }
      });
      stages.add({
        r'$unwind': {
          'path': '\$$prefix',
          'preserveNullAndEmptyArrays': true,
        }
      });
    }

    stages.add({r'$match': this});
    if (projections != null && projections.isNotEmpty) {
      stages.add({r'$project': projections});
    }
    return (lookupsCreated, stages);
  }
}

Map<String, dynamic> buildProjectionDoc(
  List<BaseProjections> projections,
) {
  final proj = <String, int>{};
  for (var p in projections) {
    final inc = p.inclusions ?? <Object>[];
    final exc = p.exclusions ?? <Object>[];
    final all = p.toProjection();
    if (inc.isNotEmpty) {
      for (var f in inc) {
        final key = p.fieldMappings[(f as Enum).name]!;
        proj[key] = 1;
      }
    }
    if (exc.isNotEmpty) {
      for (var f in exc) {
        final key = p.fieldMappings[(f as Enum).name]!;
        proj[key] = 0;
      }
    }
    if (inc.isEmpty && exc.isEmpty) {
      all.forEach((k, v) => proj[k] = v);
    }
  }
  return proj;
}
