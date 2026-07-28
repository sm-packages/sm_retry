import 'dart:async';

import 'package:sm_retry/sm_retry.dart';
import 'package:test/test.dart';

void main() {
  group('retry basic', () {
    test('successful execution does not need retry', () async {
      var attempts = 0;
      final String result = await retry(
        () async {
          attempts++;
          return 'success';
        },
        maxAttempts: 3,
      );

      expect(result, 'success');
      expect(attempts, 1);
    });

    test('retry after failure until success', () async {
      var attempts = 0;
      final String result = await retry(
        () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('fail');
          }
          return 'success';
        },
        maxAttempts: 5,
        delayFactor: Duration(milliseconds: 10),
      );

      expect(result, 'success');
      expect(attempts, 3);
    });

    test('throw exception after reaching max attempts', () async {
      var attempts = 0;
      await expectLater(
        retry(
          () async {
            attempts++;
            throw Exception('always fail');
          },
          maxAttempts: 3,
          delayFactor: Duration(milliseconds: 10),
        ),
        throwsException,
      );

      expect(attempts, 3);
    });
  });

  group('retry with retryIf', () {
    test('do not retry when retryIf returns false', () async {
      var attempts = 0;
      await expectLater(
        retry(
          () async {
            attempts++;
            throw FormatException('format error');
          },
          maxAttempts: 5,
          delayFactor: Duration(milliseconds: 10),
          retryIf: (e, attempt) => e is! FormatException,
        ),
        throwsFormatException,
      );

      expect(attempts, 1);
    });

    test('continue retry when retryIf returns true', () async {
      var attempts = 0;
      await expectLater(
        retry(
          () async {
            attempts++;
            throw Exception('retriable error');
          },
          maxAttempts: 3,
          delayFactor: Duration(milliseconds: 10),
          retryIf: (e, attempt) => true,
        ),
        throwsException,
      );

      expect(attempts, 3);
    });
  });

  group('retry with onRetry', () {
    test('call onRetry on each retry', () async {
      var attempts = 0;
      final retryAttempts = <int>[];

      await expectLater(
        retry(
          () async {
            attempts++;
            throw Exception('fail');
          },
          maxAttempts: 3,
          delayFactor: Duration(milliseconds: 10),
          onRetry: (e, attempt) {
            retryAttempts.add(attempt);
          },
        ),
        throwsException,
      );

      expect(attempts, 3);
      // onRetry called after 1st and 2nd failure, throws directly after 3rd failure
      expect(retryAttempts, [1, 2]);
    });
  });

  group('retry with timeLimit', () {
    test('throw TimeoutException on timeout', () async {
      var attempts = 0;
      await expectLater(
        retry(
          () async {
            attempts++;
            await Future.delayed(Duration(milliseconds: 100));
            throw Exception('slow fail');
          },
          maxAttempts: 10,
          delayFactor: Duration(milliseconds: 10),
          timeLimit: Duration(milliseconds: 50),
          lastTry: false,
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(attempts, 1);
    });

    test('call onTimeout on timeout', () async {
      var attempts = 0;
      int? timeoutAttempts;
      Duration? timeoutElapsed;

      final String result = await retry(
        () async {
          attempts++;
          await Future.delayed(Duration(milliseconds: 200));
          throw Exception('slow fail');
        },
        maxAttempts: 10,
        delayFactor: Duration(milliseconds: 10),
        timeLimit: Duration(milliseconds: 100),
        lastTry: false,
        onTimeout: (attempt, elapsed) {
          timeoutAttempts = attempt;
          timeoutElapsed = elapsed;
          return 'timeout result';
        },
      );

      expect(result, 'timeout result');
      expect(attempts, 1);
      expect(timeoutAttempts, 1);
      expect(timeoutElapsed, isNotNull);
    });
  });

  group('retry with lastTry', () {
    test('lastTry = true attempts once more after timeout', () async {
      var attempts = 0;
      final String result = await retry(
        () async {
          attempts++;
          if (attempts == 1) {
            // First attempt is slow, will trigger timeout
            await Future.delayed(Duration(milliseconds: 100));
            throw Exception('slow');
          }
          // lastTry succeeds immediately
          return 'success from lastTry';
        },
        maxAttempts: 10,
        delayFactor: Duration(milliseconds: 10),
        timeLimit: Duration(milliseconds: 50),
      );

      expect(result, 'success from lastTry');
      expect(attempts, 2);
    });

    test('lastTry = false does not attempt after timeout', () async {
      var attempts = 0;
      await expectLater(
        retry(
          () async {
            attempts++;
            await Future.delayed(Duration(milliseconds: 100));
            return 'never reached';
          },
          maxAttempts: 10,
          delayFactor: Duration(milliseconds: 10),
          timeLimit: Duration(milliseconds: 50),
          lastTry: false,
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(attempts, 1);
    });

    test('trigger onTimeout after lastTry fails', () async {
      var attempts = 0;
      int? timeoutAttempts;

      final String result = await retry(
        () async {
          attempts++;
          if (attempts == 1) {
            await Future.delayed(Duration(milliseconds: 100));
          }
          throw Exception('always fail');
        },
        maxAttempts: 10,
        delayFactor: Duration(milliseconds: 10),
        timeLimit: Duration(milliseconds: 50),
        onTimeout: (attemptsMade, elapsed) {
          timeoutAttempts = attemptsMade;
          return 'timeout after lastTry';
        },
      );

      expect(result, 'timeout after lastTry');
      expect(attempts, 2);
      expect(timeoutAttempts, 2);
    });

    test('do not execute lastTry when retryIf returns false', () async {
      var attempts = 0;
      await expectLater(
        retry(
          () async {
            attempts++;
            await Future.delayed(Duration(milliseconds: 100));
            throw FormatException('format error');
          },
          maxAttempts: 10,
          delayFactor: Duration(milliseconds: 10),
          timeLimit: Duration(milliseconds: 50),
          retryIf: (e, attempt) => e is! TimeoutException,
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(attempts, 1);
    });

    test('do not execute lastTry when maxAttempts reached', () async {
      var attempts = 0;
      await expectLater(
        retry(
          () async {
            attempts++;
            await Future.delayed(Duration(milliseconds: 200));
            throw Exception('slow fail');
          },
          maxAttempts: 1,
          delayFactor: Duration(milliseconds: 10),
          timeLimit: Duration(milliseconds: 100),
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(attempts, 1);
    });
  });

  group('retry with onRetry during timeout', () {
    test('call onRetry on timeout (TimeoutException)', () async {
      var attempts = 0;
      final retryExceptions = <Type>[];

      // This test verifies: onRetry is called after timeout with TimeoutException
      final String result = await retry(
        () async {
          attempts++;
          if (attempts == 1) {
            // First attempt is slow, will trigger timeout
            await Future.delayed(Duration(milliseconds: 500));
            throw Exception('slow');
          }
          // lastTry succeeds immediately
          return 'success';
        },
        maxAttempts: 10,
        delayFactor: Duration(milliseconds: 10),
        timeLimit: Duration(milliseconds: 100),
        onRetry: (e, attempt) {
          retryExceptions.add(e.runtimeType);
        },
      );

      expect(result, 'success');
      expect(attempts, 2);
      // onRetry called after timeout with TimeoutException
      expect(retryExceptions, [TimeoutException]);
    });
  });

  group('RetryOptions', () {
    test('use RetryOptions instance', () async {
      var attempts = 0;
      final options = RetryOptions(
        maxAttempts: 3,
        delayFactor: Duration(milliseconds: 10),
        timeLimit: Duration(milliseconds: 500),
      );

      final String result = await options.retry(
        () async {
          attempts++;
          if (attempts < 2) {
            throw Exception('fail');
          }
          return 'success';
        },
      );

      expect(result, 'success');
      expect(attempts, 2);
    });
  });
}
