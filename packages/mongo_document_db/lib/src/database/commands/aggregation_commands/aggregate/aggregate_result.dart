import 'package:mongo_document_db/src/database/commands/base/cursor_result.dart';
import 'package:mongo_document_db/src/database/commands/mixin/basic_result.dart';
import 'package:mongo_document_db/src/database/commands/mixin/timing_result.dart';
import 'package:mongo_document_db/src/database/utils/map_keys.dart';

class AggregateResult with BasicResult, TimingResult {
  AggregateResult(Map<String, dynamic> document)
      : cursor = CursorResult(
            document[keyCursor] as Map<String, Object>? ?? <String, Object>{}) {
    extractBasic(document);
    extractTiming(document);
  }
  CursorResult cursor;
}
