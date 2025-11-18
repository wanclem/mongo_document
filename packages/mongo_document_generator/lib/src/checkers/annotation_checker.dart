import 'package:analyzer/dart/element/element.dart';

abstract class AnnotationChecker {
  bool hasObjectIdConverter(FormalParameterElement element);
  bool hasJsonKeyWithId(FormalParameterElement element);
}
