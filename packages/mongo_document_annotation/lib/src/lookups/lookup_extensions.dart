import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Map<String, dynamic> buildProjectionDoc(List<BaseProjections> projections) {
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
      final toExclude =
          exc.map((f) => p.fieldMappings[(f as Enum).name]!).toSet();
      for (var key in all.keys) {
        proj[key] = toExclude.contains(key) ? 0 : 1;
      }
    }
    if (inc.isEmpty && exc.isEmpty) {
      all.forEach((k, v) => proj[k] = v);
    }
  }
  return proj;
}
