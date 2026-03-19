import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:test/test.dart';

enum _PostField { id, body, status }

enum _PostWorkspaceField { name, slug }

class _PostProjections implements BaseProjections<_PostField> {
  const _PostProjections({this.inclusions, this.exclusions});

  @override
  final List<_PostField>? inclusions;

  @override
  final List<_PostField>? exclusions;

  @override
  final Map<String, dynamic> fieldMappings = const {
    'id': '_id',
    'body': 'body',
    'status': 'status',
  };

  @override
  Map<String, int> toProjection() => const {
    '_id': 1,
    'body': 1,
    'status': 1,
  };
}

class _PostWorkspaceProjections implements BaseProjections<_PostWorkspaceField> {
  const _PostWorkspaceProjections({this.inclusions, this.exclusions});

  @override
  final List<_PostWorkspaceField>? inclusions;

  @override
  final List<_PostWorkspaceField>? exclusions;

  @override
  final Map<String, dynamic> fieldMappings = const {
    'name': 'workspace.name',
    'slug': 'workspace.slug',
  };

  @override
  Map<String, int> toProjection() => const {
    'workspace.name': 1,
    'workspace.slug': 1,
  };
}

void main() {
  group('projection normalization', () {
    test('adds the base projection when only nested projections are provided', () {
      final normalized = normalizeProjectionList(
        [const _PostWorkspaceProjections()],
        const _PostProjections(),
      );

      expect(normalized, hasLength(2));
      expect(
        normalized.whereType<_PostProjections>(),
        hasLength(1),
      );
      expect(
        normalized.whereType<_PostWorkspaceProjections>(),
        hasLength(1),
      );
    });

    test('does not duplicate the base projection when it is already present', () {
      final normalized = normalizeProjectionList(
        [
          const _PostProjections(
            inclusions: [_PostField.id, _PostField.body],
          ),
          const _PostWorkspaceProjections(
            exclusions: [_PostWorkspaceField.slug],
          ),
        ],
        const _PostProjections(),
      );

      expect(normalized, hasLength(2));
      expect(
        normalized.whereType<_PostProjections>(),
        hasLength(1),
      );
    });
  });

  group('projection document building', () {
    test('keeps base fields when nested-only projections are requested', () {
      final projectionDoc = buildProjectionDoc(
        normalizeProjectionList(
          [const _PostWorkspaceProjections()],
          const _PostProjections(),
        ),
      );

      expect(
        projectionDoc,
        containsPair('_id', 1),
      );
      expect(
        projectionDoc,
        containsPair('body', 1),
      );
      expect(
        projectionDoc,
        containsPair('status', 1),
      );
      expect(
        projectionDoc,
        containsPair('workspace.name', 1),
      );
      expect(
        projectionDoc,
        containsPair('workspace.slug', 1),
      );
    });

    test('respects explicit inclusions and exclusions across projection groups', () {
      final projectionDoc = buildProjectionDoc([
        const _PostProjections(
          exclusions: [_PostField.status],
        ),
        const _PostWorkspaceProjections(
          inclusions: [_PostWorkspaceField.name],
        ),
      ]);

      expect(projectionDoc, containsPair('_id', 1));
      expect(projectionDoc, containsPair('body', 1));
      expect(projectionDoc, containsPair('status', 0));
      expect(projectionDoc, containsPair('workspace.name', 1));
      expect(projectionDoc.containsKey('workspace.slug'), isFalse);
    });
  });
}
