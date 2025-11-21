List<Map<String, Object>> withNoCollisions(List<Map<String, Object>> pipeline) {
  final newPipeline = List<Map<String, Object>>.from(
    pipeline.map((stage) => Map<String, Object>.from(stage)),
  );

  for (var stage in newPipeline) {
    if (stage.containsKey('\$project')) {
      final projectStage = stage['\$project'] as Map<String, Object>;
      final keysToRemove = <String>[];

      final allKeys = projectStage.keys.toList();

      for (var key in allKeys) {
        final parts = key.split('.');
        for (var i = 1; i < parts.length; i++) {
          final parentPath = parts.sublist(0, i).join('.');
          if (allKeys.contains(parentPath)) {
            keysToRemove.add(key);
            break;
          }
        }
      }

      for (var key in keysToRemove) {
        projectStage.remove(key);
      }
    }
  }

  return newPipeline;
}
