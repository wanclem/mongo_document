import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/mongo_document_generator.dart';
import 'package:mongo_document/src/templates/crud/create/create_template.dart';
import 'package:mongo_document/src/templates/crud/delete/delete_template.dart';
import 'package:mongo_document/src/templates/crud/read/read_templates.dart';
import 'package:mongo_document/src/templates/crud/update/update_templates.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'mocks.mocks.dart';

void main() {
  group('template regressions', () {
    test(
      'save emits snapshot-backed partial updates and safe nested ObjectId parsing',
      () async {
        final output = await _saveTemplate();

        expect(output, contains('Future<Post?> save({Db? db}) async {'));
        expect(
          output,
          contains('final persistedPostMap = _postNormalizePersistedDocument('),
        );
        expect(output, contains("var snapshot = _postSnapshotFor(id!);"));
        expect(
          output,
          contains(
            "snapshot ??= await coll.modernFindOne(filter: {'_id': id});",
          ),
        );
        expect(output, contains('buildMongoUpdateMapFromSnapshot('));
        expect(output, contains('trackedKeys: _postTrackedPersistedKeys,'));
        expect(output, isNot(contains('Post? previous')));
        expect(
          output,
          contains("coll.modernFindOne(filter: {'_id': result.id})"),
        );
        expect(
          output,
          contains("final res = await coll.updateOne({'_id': id}, parentMod);"),
        );
        expect(
          output,
          contains(
            "final savedDoc = await coll.modernFindOne(filter: {'_id': id});",
          ),
        );
      },
    );

    test(
      'saveChanges delegates to save without caller-managed previous state',
      () async {
        final output = await _saveTemplate();

        expect(output, contains('Future<Post?> saveChanges({Db? db}) async {'));
        expect(output, contains('return save(db: db);'));
      },
    );

    test(
      'persistence helpers are schema-aware for refs and plain ObjectId fields',
      () async {
        final output = await _schemaAwarePersistenceTemplate();

        expect(output, contains("const _postRefFields = <String>{'author'};"));
        expect(
          output,
          contains("const _postObjectIdFields = <String>{'owner_id'};"),
        );
        expect(
          output,
          contains(
            "return Post.fromJson(\n    document.withRefs(\n      refFields: _postRefFields,\n      objectIdFields: _postObjectIdFields,",
          ),
        );
        expect(output, contains("for (final key in _postObjectIdFields) {"));
      },
    );

    test('saveMany diffs updates and preserves caller order', () {
      final output = CreateTemplates.saveMany('Post');

      expect(output, contains('_postNormalizePersistedDocument('));
      expect(output, contains('final item = posts[index];'));
      expect(output, contains('final orderedIds = List<dynamic>.filled('));
      expect(output, contains('final insertPositions = <int>[];'));
      expect(output, contains('final missingSnapshotIds = <ObjectId>[];'));
      expect(
        output,
        contains(
          "modernFind(filter: {'_id': {r'\$in': uniqueMissingSnapshotIds}})",
        ),
      );
      expect(output, contains('rememberMongoDocumentSnapshots('));
      expect(output, contains('buildMongoUpdateMapFromSnapshot('));
      expect(
        output,
        contains(
          "final updateDoc = Map<String, dynamic>.from(doc)..remove('_id');",
        ),
      );
      expect(output, contains('if (updateMap.isEmpty) {'));
      expect(output, contains('orderedIds[position] = docId;'));
      expect(output, contains('if (updateResult.isSuccess) {'));
      expect(
        output,
        contains("modernFind(filter: {'_id': {r'\$in': uniqueIds}})"),
      );
      expect(output, contains('final docsById = {'));
      expect(output, contains('orderedIds'));
      expect(output, contains('_postCoerceDocumentId('));
      expect(
        output,
        contains('doc == null ? null : _postDeserializeDocument(doc)'),
      );
    });

    test('saveMany avoids loop-variable collisions for i-prefixed models', () {
      final output = CreateTemplates.saveMany('InBoundBuffer');

      expect(output, contains('for (int index = 0; index < inBoundBuffers.length; index++) {'));
      expect(output, contains('final item = inBoundBuffers[index];'));
      expect(output, isNot(contains('final i = inBoundBuffers[i];')));
    });

    test('findById validates ids and uses modern reads', () {
      final output = ReadTemplates.findById('Post');

      expect(output, contains('ObjectId.tryParse(id)'));
      expect(
        output,
        contains(r"throw ArgumentError('Invalid id value: $id');"),
      );
      expect(output, contains('toAggregationPipelineWithMap('));
      expect(output, contains('lookups: normalizedLookups,'));
      expect(output, contains("raw: {'_id': id},"));
      expect(output, contains("cleaned: {'_id': id},"));
      expect(output, contains('projectionDocSupportsDirectFind(projDoc)'));
      expect(
        output,
        contains(
          "projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,",
        ),
      );
      expect(
        output,
        contains('''
    final post = await coll.modernFindOne(
      filter: {'_id': id},
      projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );'''),
      );
      expect(output, isNot(contains('toSelectorBuilder()')));
    });

    test('findOne and findMany use modern fallback reads', () {
      final findOneOutput = ReadTemplates.findOne('Post');
      final findManyOutput = ReadTemplates.findMany('Post');

      expect(findOneOutput, contains('coll.modernFindOne('));
      expect(
        findOneOutput,
        contains(
          'final normalizedLookups = remapLookups(lookups, _postFieldMappings);',
        ),
      );
      expect(findOneOutput, contains('lookups: normalizedLookups,'));
      expect(
        findOneOutput,
        contains('projectionDocSupportsDirectFind(projDoc)'),
      );
      expect(
        findOneOutput,
        isNot(contains('await coll.findOne(selectorMap.cleaned())')),
      );
      expect(findManyOutput, contains('.modernFind('));
      expect(
        findManyOutput,
        contains(
          'final normalizedLookups = remapLookups(lookups, _postFieldMappings);',
        ),
      );
      expect(findManyOutput, contains('lookups: normalizedLookups,'));
      expect(
        findManyOutput,
        contains('projectionDocSupportsDirectFind(projDoc)'),
      );
      expect(findManyOutput, contains('sort: {sort.\$1: sort.\$2},'));
      expect(
        findManyOutput,
        contains('''
final posts = await coll
        .modernFind(
          filter: selectorMap.cleaned(),
          sort: {sort.\$1: sort.\$2},
          projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
          skip: skip,
          limit: limit,
        )
        .toList();'''),
      );
      expect(
        findManyOutput,
        isNot(contains("await coll.find(selectorMap.cleaned()).toList()")),
      );
      expect(
        findOneOutput,
        contains('''
    final postResult = await coll.modernFindOne(
      filter: selectorMap.cleaned(),
      projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );'''),
      );
    });

    test(
      'findOneByNamed and findManyByNamed share the lookup/projection path',
      () async {
        final outputs = await _namedReadTemplates();
        final findOneByNamedOutput = outputs.$1;
        final findManyByNamedOutput = outputs.$2;

        expect(findOneByNamedOutput, contains('toAggregationPipelineWithMap('));
        expect(findOneByNamedOutput, contains('lookups: normalizedLookups,'));
        expect(findOneByNamedOutput, contains('projections: projDoc,'));
        expect(
          findOneByNamedOutput,
          contains('projectionDocSupportsDirectFind(projDoc)'),
        );
        expect(
          findOneByNamedOutput,
          contains("sort: selector.isEmpty ? ('created_at', -1) : null,"),
        );
        expect(findOneByNamedOutput, contains('raw: selector,'));
        expect(findOneByNamedOutput, contains('cleaned: selector.cleaned(),'));
        expect(
          findOneByNamedOutput,
          isNot(contains('buildAggregationPipeline([')),
        );
        expect(
          findOneByNamedOutput,
          contains('''
    final postResult = await coll.modernFindOne(
      filter: selector.cleaned(),
      sort: selector.isEmpty ? {'created_at': -1} : null,
      projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );'''),
        );

        expect(
          findManyByNamedOutput,
          contains('toAggregationPipelineWithMap('),
        );
        expect(findManyByNamedOutput, contains('lookups: normalizedLookups,'));
        expect(findManyByNamedOutput, contains('projections: projDoc,'));
        expect(
          findManyByNamedOutput,
          contains('projectionDocSupportsDirectFind(projDoc)'),
        );
        expect(
          findManyByNamedOutput,
          contains('sort: firstEntryToTuple(sort),'),
        );
        expect(findManyByNamedOutput, contains('raw: selector,'));
        expect(findManyByNamedOutput, contains('cleaned: selector.cleaned(),'));
        expect(
          findManyByNamedOutput,
          isNot(contains('buildAggregationPipeline([')),
        );
        expect(
          findManyByNamedOutput,
          contains('''
    final posts = await coll
        .modernFind(
          filter: selector.cleaned(),
          projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
          limit: limit,
          skip: skip,
          sort: sort,
        )
        .toList();'''),
        );
      },
    );

    test('buildModifier strips _id and delete uses direct _id map', () {
      final modifierOutput = UpdateTemplates.buildModifier();
      final deleteOutput = DeleteTemplates.delete('Post');

      expect(modifierOutput, contains("..remove('_id');"));
      expect(
        deleteOutput,
        contains("final res = await coll.deleteOne({'_id': id});"),
      );
    });

    test('updateOneFromMap applies schema-aware ObjectId normalization', () {
      final output = UpdateTemplates.updateOneFromMap('Post');

      expect(
        output,
        contains('''
        updateMap.withValidObjectReferences(
          refFields: _postRefFields,
          objectIdFields: _postObjectIdFields,
        ),'''),
      );
    });

    test('count uses cleaned filters for direct counts', () {
      final output = ReadTemplates.count('Post');

      expect(output, contains('toAggregationPipelineWithMap('));
      expect(output, contains('raw: selectorMap.raw(),'));
      expect(output, contains('cleaned: selectorMap.cleaned()'));
      expect(output, contains('return await coll.count(selectorMap.cleaned());'));
    });
  });

  test('generator emits the hardened CRUD helpers', () async {
    final source = r'''
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'post.mongo_document.dart';

@MongoDocument(collection: 'posts')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Post {
  Post({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.body,
    this.status,
  });

  final ObjectId? id;
  final String? body;
  final String? status;

  factory Post.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
  Map<String, dynamic> toJson() => throw UnimplementedError();
}
''';

    final output = await resolveSource<String>(
      source,
      (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('mongo_document', 'lib/post.dart'),
        );
        final postClass = library.classes.singleWhere(
          (element) => element.name == 'Post',
        );
        final annotation = TypeChecker.typeNamed(
          MongoDocument,
          inPackage: 'mongo_document_annotation',
        ).firstAnnotationOf(postClass);

        expect(annotation, isNotNull);

        return MongoDocumentGenerator().generateForAnnotatedElement(
          postClass,
          ConstantReader(annotation),
          MockBuildStep(),
        );
      },
      inputId: AssetId('mongo_document', 'lib/post.dart'),
      readAllSourcesFromFilesystem: true,
    );

    expect(output, contains("const _postCollection = 'posts';"));
    expect(output, contains("const _postFieldMappings = <String, String>{"));
    expect(output, contains("'id': '_id'"));
    expect(output, contains("'body': 'body'"));
    expect(output, contains("'status': 'status'"));
    expect(output, contains('const _postTrackedPersistedKeys = <String>['));
    expect(
      output,
      contains('void _rememberPostSnapshot(Map<String, dynamic> document) {'),
    );
    expect(output, contains('ObjectId? _postCoerceDocumentId(dynamic rawId) {'));
    expect(output, contains('Future<Post?> save({Db? db}) async {'));
    expect(output, contains('buildMongoUpdateMapFromSnapshot('));
    expect(output, contains('Future<Post?> saveChanges({Db? db}) async {'));
    expect(output, contains('return save(db: db);'));
    expect(output, contains("..remove('_id');"));
    expect(output, contains("final retrieved = await coll.modernFindOne("));
    expect(output, contains("final retrieved = await coll.modernFind("));
    expect(output, contains("projection: {'_id': 1},"));
    expect(
      output,
      contains('final normalizedProjections = normalizeProjectionList('),
    );
    expect(
      output,
      contains(
        'final normalizedLookups = remapLookups(lookups, _postFieldMappings);',
      ),
    );
    expect(output, contains('toAggregationPipelineWithMap('));
    expect(output, contains('buildProjectionDoc(normalizedProjections)'));
    expect(output, contains(r"throw ArgumentError('Invalid id value: $id');"));
    expect(
      output,
      contains(
        "final updateDoc = Map<String, dynamic>.from(doc)..remove('_id');",
      ),
    );
    expect(output, contains(r"'_id': {r'$in': ids}"));
    expect(output, contains("final res = await coll.deleteOne({'_id': id});"));
    expect(output, contains('sort: firstEntryToTuple(sort),'));
    expect(output, contains('skip: skip,'));
    expect(
      output,
      isNot(contains("final retrieved = await findOne(predicate);")),
    );
    expect(
      output,
      isNot(contains("final retrieved = await findMany(predicate);")),
    );
    expect(
      output,
      isNot(contains("await coll.find(selectorMap.cleaned()).toList();")),
    );
    expect(output, isNot(contains('buildAggregationPipeline([')));
  });
}

Future<String> _saveTemplate() async {
  const source = r'''
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

@MongoDocument(collection: 'posts')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Post {
  Post({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.body,
    this.status,
  });

  final ObjectId? id;
  final String? body;
  final String? status;

  factory Post.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
  Map<String, dynamic> toJson() => throw UnimplementedError();
}
''';

  return resolveSource<String>(
    source,
    (resolver) async {
      return CreateTemplates.save('Post');
    },
    inputId: AssetId('mongo_document', 'lib/save_template_post.dart'),
    readAllSourcesFromFilesystem: true,
  );
}

Future<String> _schemaAwarePersistenceTemplate() async {
  const source = r'''
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

@MongoDocument(collection: 'users')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class User {
  User({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.name,
  });

  final ObjectId? id;
  final String? name;

  factory User.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
  Map<String, dynamic> toJson() => throw UnimplementedError();
}

@MongoDocument(collection: 'posts')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Post {
  Post({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.author,
    @ObjectIdConverter() this.ownerId,
  });

  final ObjectId? id;
  final User? author;
  final ObjectId? ownerId;

  factory Post.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
  Map<String, dynamic> toJson() => throw UnimplementedError();
}
''';

  return resolveSource<String>(
    source,
    (resolver) async {
      final library = await resolver.libraryFor(
        AssetId('mongo_document', 'lib/schema_post.dart'),
      );
      final postClass = library.classes.singleWhere(
        (element) => element.name == 'Post',
      );
      return MongoDocumentGenerator().generateForAnnotatedElement(
        postClass,
        ConstantReader(
          TypeChecker.typeNamed(
            MongoDocument,
            inPackage: 'mongo_document_annotation',
          ).firstAnnotationOf(postClass),
        ),
        MockBuildStep(),
      );
    },
    inputId: AssetId('mongo_document', 'lib/schema_post.dart'),
    readAllSourcesFromFilesystem: true,
  );
}

Future<(String, String)> _namedReadTemplates() async {
  const source = r'''
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

@MongoDocument(collection: 'posts')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Post {
  Post({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.author,
    this.status,
  });

  final ObjectId? id;
  final User? author;
  final String? status;

  factory Post.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
  Map<String, dynamic> toJson() => throw UnimplementedError();
}

class User {
  const User({this.id});

  final ObjectId? id;
}
''';

  return resolveSource<(String, String)>(
    source,
    (resolver) async {
      final library = await resolver.libraryFor(
        AssetId('mongo_document', 'lib/named_read_template_post.dart'),
      );
      final postClass = library.classes.singleWhere(
        (element) => element.name == 'Post',
      );
      final params = postClass.constructors.first.formalParameters;
      final nestedCollectionMap = {'author': 'accounts'};
      final typeChecker = TypeChecker.typeNamed(
        JsonKey,
        inPackage: 'json_annotation',
      );

      return (
        ReadTemplates.findOneByNamed(
          typeChecker,
          FieldRename.snake,
          params,
          'Post',
          nestedCollectionMap,
        ),
        ReadTemplates.findManyByNamed(
          typeChecker,
          FieldRename.snake,
          params,
          'Post',
          nestedCollectionMap,
        ),
      );
    },
    inputId: AssetId('mongo_document', 'lib/named_read_template_post.dart'),
    readAllSourcesFromFilesystem: true,
  );
}
