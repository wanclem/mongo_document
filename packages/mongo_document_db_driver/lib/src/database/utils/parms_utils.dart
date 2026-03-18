import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';

Map<String, dynamic> extractfilterMap(dynamic filter) {
  if (filter == null) {
    return <String, dynamic>{};
  }
  if (filter is SelectorBuilder) {
    return <String, dynamic>{...?filter.map[key$Query]};
  } else if (filter is Map) {
    return <String, dynamic>{...filter};
  }
  throw MongoDartError(
      'Filter can only be a Map or a SelectorBuilder instance');
}
