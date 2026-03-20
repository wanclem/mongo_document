import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('Lookup', () {
    test('array lookups stay unlimited by default', () {
      final lookup = Lookup.array(
        from: 'comments',
        localField: '_id',
        foreignField: 'post',
        as: 'comments',
      );

      final pipeline = _lookupPipeline(lookup);

      expect(_limitStage(pipeline), isNull);
      expect(lookup.buildPipeline(), hasLength(1));
    });

    test('generic array lookup also stays unlimited by default', () {
      final lookup = Lookup(
        from: 'comments',
        localField: '_id',
        foreignField: 'post',
        as: 'comments',
        resultType: LookupResultType.array,
      );

      final pipeline = _lookupPipeline(lookup);

      expect(_limitStage(pipeline), isNull);
    });

    test('single lookups default to limit one', () {
      final lookup = Lookup.single(
        from: 'users',
        localField: 'author',
        foreignField: '_id',
        as: 'author',
      );

      final pipeline = _lookupPipeline(lookup);

      expect(_limitStage(pipeline), {'\$limit': 1});
      expect(lookup.buildPipeline().last, {
        '\$addFields': {
          'author': {
            '\$cond': {
              'if': {
                '\$gt': [
                  {'\$size': '\$author'},
                  0,
                ],
              },
              'then': {
                '\$arrayElemAt': ['\$author', 0],
              },
              'else': null,
            },
          },
        },
      });
    });

    test('boolean lookups default to limit one', () {
      final lookup = Lookup.boolean(
        from: 'followers',
        localField: '_id',
        foreignField: 'leader',
        as: 'you_follow',
      );

      final pipeline = _lookupPipeline(lookup);

      expect(_limitStage(pipeline), {'\$limit': 1});
    });

    test('count lookups do not silently cap results', () {
      final lookup = Lookup.count(
        from: 'comments',
        localField: '_id',
        foreignField: 'post',
        as: 'commentCount',
      );

      final pipeline = _lookupPipeline(lookup);

      expect(_limitStage(pipeline), isNull);
      expect(lookup.buildPipeline().last, {
        '\$addFields': {
          'commentCount': {'\$size': '\$commentCount'},
        },
      });
    });

    test('explicit limits are preserved for array and count lookups', () {
      final arrayLookup = Lookup.array(
        from: 'comments',
        localField: '_id',
        foreignField: 'post',
        as: 'comments',
        limit: 3,
      );
      final countLookup = Lookup.count(
        from: 'comments',
        localField: '_id',
        foreignField: 'post',
        as: 'commentCount',
        limit: 5,
      );

      expect(_limitStage(_lookupPipeline(arrayLookup)), {'\$limit': 3});
      expect(_limitStage(_lookupPipeline(countLookup)), {'\$limit': 5});
    });

    test(
      'explicit lookups replace implicit projection-driven lookups for the same alias',
      () {
        final merged =
            mergeLookups(
              lookups: const [
                Lookup.single(
                  from: 'accounts',
                  localField: 'author',
                  foreignField: '_id',
                  as: 'author',
                  unsetFields: ['email'],
                ),
              ],
              existingPipeline: [
                {
                  r'$match': {'status': 'published'},
                },
                {
                  r'$lookup': {
                    'from': 'accounts',
                    'localField': 'author',
                    'foreignField': '_id',
                    'as': 'author',
                  },
                },
                {
                  r'$unwind': {
                    'path': r'$author',
                    'preserveNullAndEmptyArrays': true,
                  },
                },
                {
                  r'$project': {
                    '_id': 1,
                    'author._id': 1,
                    'author.first_name': 1,
                  },
                },
              ],
              limit: 1,
            ).$2;

        expect(
          merged.where((stage) => stage.containsKey(r'$lookup')),
          hasLength(1),
        );
        expect(merged.any((stage) => stage.containsKey(r'$unwind')), isFalse);
        expect(merged.any((stage) => stage.containsKey(r'$addFields')), isTrue);

        final lookupStage =
            merged.firstWhere(
                  (stage) => stage.containsKey(r'$lookup'),
                )[r'$lookup']
                as Map<String, Object>;
        expect(lookupStage['as'], 'author');
        expect(lookupStage.containsKey('pipeline'), isTrue);

        final lookupPipeline = List<Map<String, Object>>.from(
          lookupStage['pipeline']! as List<Object>,
        );
        expect(
          lookupPipeline.any(
            (stage) =>
                stage[r'$unset'] is List &&
                (stage[r'$unset'] as List).contains('email'),
          ),
          isTrue,
        );
      },
    );

    test(
      'explicit lookups keep root skip and limit ahead of lookup stages',
      () {
        final merged =
            mergeLookups(
              lookups: const [
                Lookup.single(
                  from: 'accounts',
                  localField: 'author',
                  foreignField: '_id',
                  as: 'author',
                ),
              ],
              queryMap: const {'status': 'published'},
              sort: const ('created_at', -1),
              skip: 5,
              limit: 10,
            ).$2;

        expect(merged, hasLength(6));
        expect(
          merged,
          equals([
            {
              r'$match': {'status': 'published'},
            },
            {
              r'$sort': {'created_at': -1},
            },
            {r'$skip': 5},
            {r'$limit': 10},
            {
              r'$lookup': {
                'from': 'accounts',
                'let': {'localValue': r'$author'},
                'pipeline': [
                  {
                    r'$match': {
                      r'$expr': {
                        r'$eq': [r'$_id', r'$$localValue'],
                      },
                    },
                  },
                  {r'$limit': 1},
                ],
                'as': 'author',
              },
            },
            {
              r'$addFields': {
                'author': {
                  r'$cond': {
                    'if': {
                      r'$gt': [
                        {r'$size': r'$author'},
                        0,
                      ],
                    },
                    'then': {
                      r'$arrayElemAt': [r'$author', 0],
                    },
                    'else': null,
                  },
                },
              },
            },
          ]),
        );
      },
    );

    test(
      'explicit lookups still keep project stages after lookup stages',
      () {
        final merged =
            mergeLookups(
              lookups: const [
                Lookup.single(
                  from: 'accounts',
                  localField: 'author',
                  foreignField: '_id',
                  as: 'author',
                ),
              ],
              queryMap: const {'status': 'published'},
              limit: 1,
              existingPipeline: [
                {
                  r'$match': {'status': 'published'},
                },
                {r'$limit': 1},
                {
                  r'$project': {
                    '_id': 1,
                    'author._id': 1,
                    'author.first_name': 1,
                  },
                },
              ],
            ).$2;

        expect(merged[0], {
          r'$match': {'status': 'published'},
        });
        expect(merged[1], {
          r'$limit': 1,
        });
        expect(merged[2].containsKey(r'$lookup'), isTrue);
        expect(merged[3].containsKey(r'$addFields'), isTrue);
        expect(
          merged.last,
          {
            r'$project': {
              '_id': 1,
              'author._id': 1,
              'author.first_name': 1,
            },
          },
        );
      },
    );

    test('remapLookups translates Dart field names to stored Mongo keys', () {
      final remapped = remapLookups(
        const [
          Lookup.single(
            from: 'accounts',
            localField: 'user',
            foreignField: '_id',
            as: 'user',
            nestedLookups: [
              Lookup.array(
                from: 'organizations',
                localField: 'organization',
                foreignField: '_id',
                as: 'organization',
              ),
            ],
          ),
        ],
        const {'id': '_id', 'user': 'user_id', 'organization': 'organization'},
      );

      expect(remapped, hasLength(1));
      expect(remapped.first.localField, 'user_id');
      expect(remapped.first.as, 'user_id');
      expect(remapped.first.nestedLookups, isNotNull);
      expect(remapped.first.nestedLookups!.single.localField, 'organization');
      expect(remapped.first.nestedLookups!.single.as, 'organization');
    });
  });
}

List<Map<String, Object>> _lookupPipeline(Lookup lookup) {
  final stage = lookup.buildPipeline().first;
  final lookupStage = stage['\$lookup'] as Map<String, Object>;
  return List<Map<String, Object>>.from(
    lookupStage['pipeline']! as List<Object>,
  );
}

Map<String, Object>? _limitStage(List<Map<String, Object>> pipeline) {
  for (final stage in pipeline) {
    if (stage.containsKey('\$limit')) {
      return stage;
    }
  }
  return null;
}
