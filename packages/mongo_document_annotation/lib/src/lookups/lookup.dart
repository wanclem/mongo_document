enum LookupResultType { array, single, boolean, count }

class Lookup {
  /// Collection to lookup from
  final String from;

  /// The field on the current document to use for matching (defaults to '_id')
  final String? localField;

  /// The foreign field in the lookup collection that references localField (defaults to '_id')
  final String foreignField;

  /// Field on the current model where results will be stored
  final String as;

  /// Maximum number of documents to return (defaults to 1 if not specified)
  final int? limit;

  /// Sort order: 1 for ascending, -1 for descending
  final Map<String, int>? sort;

  /// Additional match conditions for the lookup
  final Map<String, Object>? where;

  /// How to return the result (array, single, boolean, or count)
  final LookupResultType resultType;

  /// Nested lookups to perform on the results of this lookup
  final List<Lookup>? nestedLookups;

  /// Fields to exclude from the lookup results (e.g., ['email', 'password'])
  final List<String>? unsetFields;

  const Lookup({
    required this.from,
    this.localField,
    this.foreignField = '_id',
    required this.as,
    this.limit,
    this.sort,
    this.where,
    this.resultType = LookupResultType.array,
    this.nestedLookups,
    this.unsetFields,
  });

  int get _effectiveLimit => limit ?? 1;

  List<Map<String, Object>> buildPipeline() {
    final stages = <Map<String, Object>>[];
    final lookupStage = _buildLookupStage();
    stages.add(lookupStage);
    final transformStages = _buildTransformStages();
    stages.addAll(transformStages);
    return stages;
  }

  Map<String, Object> _buildLookupStage() {
    final pipeline = <Map<String, Object>>[];

    pipeline.add(
      Map<String, Object>.from({
        '\$match': Map<String, Object>.from({
          '\$expr': Map<String, Object>.from({
            '\$eq': List<Object?>.from(['\$$foreignField', '\$\$localValue']),
          }),
        }),
      }),
    );

    if (where != null && where!.isNotEmpty) {
      final lastStage = pipeline.last;
      final matchStage = lastStage['\$match'] as Map<String, Object>;
      if (matchStage.containsKey('\$expr')) {
        final existingExpr = matchStage['\$expr'];
        final whereExprs = _buildWhereExpressions();
        if (whereExprs.isNotEmpty) {
          matchStage['\$expr'] = {
            '\$and': [existingExpr, ...whereExprs],
          };
        }
      }
    }

    if (sort != null && sort!.isNotEmpty) {
      pipeline.add({'\$sort': sort!});
    }

    pipeline.add({'\$limit': _effectiveLimit});

    if (nestedLookups != null && nestedLookups!.isNotEmpty) {
      for (final nestedLookup in nestedLookups!) {
        pipeline.addAll(nestedLookup.buildPipeline());
      }
    }

    if (unsetFields != null && unsetFields!.isNotEmpty) {
      pipeline.add({'\$unset': unsetFields!});
    }

    return {
      '\$lookup': {
        'from': from,
        'let': {'localValue': '\$${localField ?? '_id'}'},
        'pipeline': pipeline,
        'as': as,
      },
    };
  }

  List<Map<String, Object>> _buildWhereExpressions() {
    if (where == null || where!.isEmpty) return [];
    return where!.entries.map((entry) {
      return {
        '\$eq': ['\$${entry.key}', entry.value],
      };
    }).toList();
  }

  List<Map<String, Object>> _buildTransformStages() {
    final stages = <Map<String, Object>>[];
    switch (resultType) {
      case LookupResultType.array:
        break;
      case LookupResultType.single:
        stages.add({
          '\$unwind': {'path': '\$$as', 'preserveNullAndEmptyArrays': true},
        });
        break;
      case LookupResultType.boolean:
        stages.add({
          '\$addFields': {
            as: {
              '\$cond': {
                'if': {
                  '\$gt': [
                    {'\$size': '\$$as'},
                    0,
                  ],
                },
                'then': true,
                'else': false,
              },
            },
          },
        });
        break;
      case LookupResultType.count:
        stages.add({
          '\$addFields': {
            as: {'\$size': '\$$as'},
          },
        });
        break;
    }
    return stages;
  }
}
