import 'package:mongo_document_annotation/mongo_document_annotation.dart';

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
