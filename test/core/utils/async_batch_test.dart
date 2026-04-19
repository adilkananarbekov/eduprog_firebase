import 'package:eduprog_firebase/core/utils/async_batch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runInBatches', () {
    test('preserves order while limiting concurrency by batch', () async {
      var running = 0;
      var maxRunning = 0;

      final results = await runInBatches<int, int>(
        [1, 2, 3, 4, 5],
        batchSize: 2,
        operation: (value) async {
          running++;
          if (running > maxRunning) {
            maxRunning = running;
          }

          await Future<void>.delayed(const Duration(milliseconds: 1));
          running--;
          return value * 2;
        },
      );

      expect(results, [2, 4, 6, 8, 10]);
      expect(maxRunning, lessThanOrEqualTo(2));
    });

    test('throws for invalid batch size', () {
      expect(
        () => runInBatches<int, int>(
          [1, 2, 3],
          batchSize: 0,
          operation: (value) async => value,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
