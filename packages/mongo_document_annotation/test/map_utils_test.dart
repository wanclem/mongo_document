import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('toAggregationPipelineWithMap', () {
    test(
      'keeps lookup-backed nested field queries active without projections',
      () {
        final (foundLookups, pipeline) = toAggregationPipelineWithMap(
          lookupRef: const {'workspace': 'workspaces'},
          raw: const {
            r'$query': {'workspace.name': 'Launch Room'},
          },
          cleaned: const {'workspace.name': 'Launch Room'},
        );

        expect(foundLookups, isTrue);
        final lookupStage =
            pipeline.firstWhere(
                  (stage) => stage.containsKey(r'$lookup'),
                )[r'$lookup']
                as Map<String, Object>;
        expect(lookupStage['from'], 'workspaces');
        expect(lookupStage['localField'], 'workspace');
        expect(lookupStage['foreignField'], '_id');
        expect(lookupStage['as'], 'workspace');

        final unwindStage =
            pipeline.firstWhere(
                  (stage) => stage.containsKey(r'$unwind'),
                )[r'$unwind']
                as Map<String, Object>;
        expect(unwindStage['path'], r'$workspace');
        expect(unwindStage['preserveNullAndEmptyArrays'], isTrue);
        expect(
          pipeline.any((stage) => stage.containsKey(r'$project')),
          isFalse,
        );
      },
    );

    test(
      'does not force aggregation when a typed ref id query has already been cleaned',
      () {
        final (foundLookups, pipeline) = toAggregationPipelineWithMap(
          lookupRef: const {'author': 'accounts'},
          raw: const {
            r'$query': {'author._id': '507f1f77bcf86cd799439011'},
          },
          cleaned: const {'author': '507f1f77bcf86cd799439011'},
        );

        expect(foundLookups, isFalse);
        expect(
          pipeline,
          [
            {
              r'$match': {'author': '507f1f77bcf86cd799439011'},
            },
          ],
        );
      },
    );

    test(
      'keeps projection-only typed ref queries on the direct find path',
      () {
        final (foundLookups, pipeline) = toAggregationPipelineWithMap(
          lookupRef: const {'author': 'accounts'},
          projections: const {'_id': 1, 'body': 1},
          raw: const {
            r'$query': {'author._id': '507f1f77bcf86cd799439011'},
          },
          sort: ('created_at', -1),
          limit: 5,
          cleaned: const {'author': '507f1f77bcf86cd799439011'},
        );

        expect(foundLookups, isFalse);
        expect(
          pipeline,
          [
            {
              r'$match': {'author': '507f1f77bcf86cd799439011'},
            },
            {
              r'$sort': {'created_at': -1},
            },
            {r'$limit': 5},
          ],
        );
      },
    );

    test('does not inject sort or limit stages when omitted', () {
      final (foundLookups, pipeline) = toAggregationPipelineWithMap(
        lookupRef: const {'workspace': 'workspaces'},
        raw: const {
          r'$query': {'workspace.name': 'Launch Room'},
        },
        cleaned: const {'workspace.name': 'Launch Room'},
      );

      expect(foundLookups, isTrue);
      expect(pipeline.any((stage) => stage.containsKey(r'$sort')), isFalse);
      expect(pipeline.any((stage) => stage.containsKey(r'$limit')), isFalse);
    });

    test(
      'keeps direct-find-compatible projections off the aggregation path',
      () {
        final (requiresAggregation, pipeline) = toAggregationPipelineWithMap(
          projections: const {'_id': 1, 'body': 1},
          raw: const {
            r'$query': {'status': 'published'},
          },
          cleaned: const {'status': 'published'},
        );

        expect(requiresAggregation, isFalse);
        expect(
          pipeline.any((stage) => stage.containsKey(r'$project')),
          isFalse,
        );
      },
    );

    test('falls back to aggregation for mixed include/exclude projections', () {
      final (requiresAggregation, pipeline) = toAggregationPipelineWithMap(
        projections: const {'_id': 1, 'body': 1, 'internal_notes': 0},
        raw: const {
          r'$query': {'status': 'published'},
        },
        cleaned: const {'status': 'published'},
      );

      expect(requiresAggregation, isTrue);
      expect(pipeline.any((stage) => stage.containsKey(r'$project')), isTrue);
    });

    test(
      'uses explicit lookup stages for projected nested fields without duplicating the lookup',
      () {
        final (
          requiresAggregation,
          basePipeline,
        ) = toAggregationPipelineWithMap(
          lookupRef: const {'author': 'accounts'},
          lookups: const [
            Lookup.single(
              from: 'accounts',
              localField: 'author',
              foreignField: '_id',
              as: 'author',
            ),
          ],
          projections: const {
            '_id': 1,
            'text': 1,
            'author._id': 1,
            'author.first_name': 1,
          },
          raw: const {
            r'$query': {'status': 'published'},
          },
          cleaned: const {'status': 'published'},
        );

        expect(requiresAggregation, isTrue);
        expect(
          basePipeline.where((stage) => stage.containsKey(r'$lookup')),
          hasLength(1),
        );
        expect(
          basePipeline.any((stage) => stage.containsKey(r'$unwind')),
          isFalse,
        );
        expect(
          basePipeline.any((stage) => stage.containsKey(r'$addFields')),
          isTrue,
        );

        final merged = withNoCollisions(
          mergeLookups(
            lookups: const [
              Lookup.single(
                from: 'accounts',
                localField: 'author',
                foreignField: '_id',
                as: 'author',
              ),
            ],
            existingPipeline: basePipeline,
            limit: 1,
          ).$2,
        );

        expect(
          merged.where((stage) => stage.containsKey(r'$lookup')),
          hasLength(1),
        );
        final projectStage =
            merged.firstWhere(
                  (stage) => stage.containsKey(r'$project'),
                )[r'$project']
                as Map<String, Object>;
        expect(projectStage['_id'], 1);
        expect(projectStage['text'], 1);
        expect(projectStage['author._id'], 1);
        expect(projectStage['author.first_name'], 1);
      },
    );
  });

  group('mongoValuesEqual', () {
    test('compares primitive values', () {
      expect(mongoValuesEqual('a', 'a'), isTrue);
      expect(mongoValuesEqual('a', 'b'), isFalse);
      expect(mongoValuesEqual(1, 1), isTrue);
      expect(mongoValuesEqual(1, 2), isFalse);
    });

    test('compares lists deeply', () {
      expect(
        mongoValuesEqual(
          [
            'a',
            1,
            {'ok': true},
          ],
          [
            'a',
            1,
            {'ok': true},
          ],
        ),
        isTrue,
      );
      expect(
        mongoValuesEqual(
          [
            'a',
            1,
            {'ok': true},
          ],
          [
            'a',
            1,
            {'ok': false},
          ],
        ),
        isFalse,
      );
    });

    test('compares maps deeply', () {
      expect(
        mongoValuesEqual(
          {
            'name': 'Post',
            'tags': ['dart', 'mongo'],
            'meta': {'published': true},
          },
          {
            'name': 'Post',
            'tags': ['dart', 'mongo'],
            'meta': {'published': true},
          },
        ),
        isTrue,
      );

      expect(
        mongoValuesEqual(
          {
            'name': 'Post',
            'meta': {'published': true},
          },
          {
            'name': 'Post',
            'meta': {'published': false},
          },
        ),
        isFalse,
      );
    });
  });

  group('firstEntryToTuple', () {
    test('returns the first sort entry as a typed tuple', () {
      expect(firstEntryToTuple(const {'created_at': -1}), ('created_at', -1));
    });

    test('throws when sort direction is not an int', () {
      expect(
        () => firstEntryToTuple(const {'created_at': 'desc'}),
        throwsArgumentError,
      );
    });
  });
}
