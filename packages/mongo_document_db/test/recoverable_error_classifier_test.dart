import 'package:mongo_document_db/src/database/utils/map_keys.dart';
import 'package:mongo_document_db/src/database/utils/recoverable_error_classifier.dart';
import 'package:test/test.dart';

void main() {
  group('RecoverableErrorClassifier', () {
    test('classifies legacy not master with slaveOk=false message', () {
      expect(
          RecoverableErrorClassifier.isPrimaryRoutingFailureMessage(
              'MongoDart Error: not master and slaveOk=false'),
          isTrue);
    });

    test('classifies modern NotPrimary codeName variants', () {
      expect(
          RecoverableErrorClassifier.isPrimaryRoutingFailureCodeName(
              'NotWritablePrimary'),
          isTrue);
      expect(
          RecoverableErrorClassifier.isPrimaryRoutingFailureCodeName(
              'NotPrimaryNoSecondaryOk'),
          isTrue);
      expect(
          RecoverableErrorClassifier.isPrimaryRoutingFailureCodeName(
              'PrimarySteppedDown'),
          isTrue);
    });

    test('classifies retryable server error codes', () {
      expect(
          RecoverableErrorClassifier.isRetryableServerErrorCode(10107), isTrue);
      expect(
          RecoverableErrorClassifier.isRetryableServerErrorCode(13435), isTrue);
      expect(RecoverableErrorClassifier.isRetryableServerErrorCode(999999),
          isFalse);
    });

    test('classifies server error document by message and codeName', () {
      expect(
          RecoverableErrorClassifier
              .isRecoverableServerErrorDocument(<String, dynamic>{
            keyErrmsg: 'not master and slaveOk=false',
            keyCode: 0,
            keyCodeName: 'UnknownError',
          }),
          isTrue);

      expect(
          RecoverableErrorClassifier
              .isRecoverableServerErrorDocument(<String, dynamic>{
            keyErrmsg: 'random validation failure',
            keyCode: 0,
            keyCodeName: 'NotWritablePrimary',
          }),
          isTrue);
    });

    test('does not classify unrelated errors as recoverable', () {
      expect(
          RecoverableErrorClassifier
              .isRecoverableServerErrorDocument(<String, dynamic>{
            keyErrmsg: 'document validation failed',
            keyCode: 121,
            keyCodeName: 'DocumentValidationFailure',
          }),
          isFalse);
    });
  });
}
