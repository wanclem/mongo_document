import 'package:analyzer/dart/element/element.dart';

abstract class AnnotationChecker {
  bool hasObjectIdConverter(ParameterElement element);
  bool hasJsonKeyWithId(ParameterElement element);
}
