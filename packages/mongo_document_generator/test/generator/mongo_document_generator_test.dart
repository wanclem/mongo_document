import 'package:mongo_document/mongo_document_generator.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

import '../mocks.mocks.dart';

void main() {
  group('MongoDocumentGenerator', () {
    late MongoDocumentGenerator generator;
    late MockClassElement classElement;
    late MockConstantReader annotation;
    late MockBuildStep buildStep;
    late MockDartObject dartObject;
    late MockConstructorElement ctor;
    late MockParameterElement idParam;
    late MockDartType idType;
    late MockAnnotationChecker mockChecker;

    setUp(() {
      mockChecker = MockAnnotationChecker();
      generator = MongoDocumentGenerator(checker: mockChecker);

      classElement = MockClassElement();
      annotation = MockConstantReader();
      buildStep = MockBuildStep();
      dartObject = MockDartObject();
      ctor = MockConstructorElement();
      idParam = MockParameterElement();
      idType = MockDartType();

      when(idParam.name).thenReturn('id');
      when(idParam.type).thenReturn(idType);
      when(idType.getDisplayString(
              withNullability: anyNamed('withNullability')))
          .thenReturn('ObjectId?');

      when(ctor.parameters).thenReturn([idParam]);
      when(classElement.unnamedConstructor).thenReturn(ctor);
      when(classElement.name).thenReturn('TestClass');

      when(annotation.peek('collection'))
          .thenReturn(ConstantReader(dartObject));
      when(dartObject.isNull).thenReturn(false);
      when(dartObject.toStringValue()).thenReturn('test_collection');

      when(mockChecker.hasObjectIdConverter(idParam)).thenReturn(true);
      when(mockChecker.hasJsonKeyWithId(idParam)).thenReturn(true);
    });

    test('returns empty string when not a ClassElement', () async {
      final result = await generator.generateForAnnotatedElement(
        FakeElement(),
        annotation,
        buildStep,
      );
      expect(result, '');
    });

    test('extracts collection name from annotation', () async {
      final result = await generator.generateForAnnotatedElement(
        classElement,
        annotation,
        buildStep,
      );
      expect(result,
          contains("static String get _collection => 'test_collection';"));
    });
  });
}

class FakeElement implements Element {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
