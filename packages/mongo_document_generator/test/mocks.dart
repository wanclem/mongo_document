import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mockito/annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:mongo_document/src/checkers/annotation_checker.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

@GenerateNiceMocks([
  MockSpec<ClassElement>(),
  MockSpec<ConstantReader>(),
  MockSpec<DartObject>(),
  MockSpec<BuildStep>(),
  MockSpec<FormalParameterElement>(),
  MockSpec<ConstructorElement>(),
  MockSpec<DartType>(),
  MockSpec<ElementAnnotation>(),
  MockSpec<AnnotationChecker>(),
])
void main() {}
