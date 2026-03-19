import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'package:mongo_document_db_driver/src/native/rust_worker.dart';
import 'package:test/test.dart';

void main() {
  group('Rust worker startup retries', () {
    test(
      'retries transient connection failures until startup succeeds',
      () async {
        var attempts = 0;

        final result = await debugRetryTransientWorkerStartupOperation<String>(
          operation: () async {
            attempts++;
            if (attempts < 3) {
              throw const ConnectionException(
                'worker pool primary 1/4 initial connectivity check failed: Kind: I/O error: timed out, labels: {"RetryableWriteError"}',
              );
            }
            return 'ok';
          },
        );

        expect(result, equals('ok'));
        expect(attempts, equals(3));
      },
    );

    test('does not retry authentication failures', () async {
      var attempts = 0;

      await expectLater(
        debugRetryTransientWorkerStartupOperation<void>(
          operation: () async {
            attempts++;
            throw const ConnectionException(
              'Authentication required for Rust worker startup.',
            );
          },
        ),
        throwsA(isA<ConnectionException>()),
      );

      expect(attempts, equals(1));
    });

    test('does not retry non-connection errors', () async {
      var attempts = 0;

      await expectLater(
        debugRetryTransientWorkerStartupOperation<void>(
          operation: () async {
            attempts++;
            throw MongoDartError('Malformed connection string.');
          },
        ),
        throwsA(isA<MongoDartError>()),
      );

      expect(attempts, equals(1));
    });

    test('stays bounded by the configured max attempts', () async {
      var attempts = 0;

      await expectLater(
        debugRetryTransientWorkerStartupOperation<void>(
          maxAttempts: 2,
          operation: () async {
            attempts++;
            throw const ConnectionException(
              'Server selection timeout while opening Rust worker.',
            );
          },
        ),
        throwsA(isA<ConnectionException>()),
      );

      expect(attempts, equals(2));
    });
  });
}
