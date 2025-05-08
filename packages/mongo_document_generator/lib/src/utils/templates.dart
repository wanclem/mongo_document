import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/mongo_document_generator.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';



String buildProjectionFlowTemplate(String matchQuery) {
  return '''
final pipeline = <Map<String, Object>>[];
     final projDoc = <String, int>{};
     pipeline.add($matchQuery);
     for (var p in projections) {
        final projectedFields = p.fields;
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (projectedFields != null && projectedFields.isNotEmpty) {
          final selected = <String, int>{};
          for (var f in projectedFields) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
          projDoc.addAll(selected);
        } else {
          projDoc.addAll(allProjections);
        }
        pipeline.add({
          r'\$lookup': {
            'from': foreignColl,
            'localField': localField,
            'foreignField': '_id',
            'as': localField,
          }
        });
        pipeline.add({r'\$unwind': localField});
      }
      pipeline.add({r'\$project': projDoc});
''';
}
