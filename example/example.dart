// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:sm_retry/sm_retry.dart';

Future<void> main() async {
  // Basic usage
  await basicRetry();

  // Conditional retry
  await conditionalRetry();

  // With time limit
  await retryWithTimeLimit();

  // Using RetryOptions
  await retryWithOptions();
}

/// Basic retry example
Future<void> basicRetry() async {
  print('=== Basic Retry ===');

  var attempts = 0;
  final result = await retry(
    () async {
      attempts++;
      print('Attempt $attempts');
      if (attempts < 3) {
        throw Exception('Simulated failure');
      }
      return 'Success after $attempts attempts';
    },
    maxAttempts: 5,
    delayFactor: Duration(milliseconds: 100),
  );

  print('Result: $result\n');
}

/// Conditional retry based on exception type
Future<void> conditionalRetry() async {
  print('=== Conditional Retry ===');

  var attempts = 0;
  try {
    await retry(
      () async {
        attempts++;
        print('Attempt $attempts');
        if (attempts == 1) {
          throw SocketException('Network error');
        }
        if (attempts == 2) {
          throw FormatException('Data format error');
        }
        return 'Success';
      },
      maxAttempts: 5,
      delayFactor: Duration(milliseconds: 100),
      // Only retry on SocketException, not FormatException
      retryIf: (e, attempt) => e is SocketException,
    );
  } on FormatException catch (e) {
    print('Caught expected exception: $e\n');
  }
}

/// Retry with total time limit
Future<void> retryWithTimeLimit() async {
  print('=== Retry with Time Limit ===');

  var attempts = 0;
  final result = await retry(
    () async {
      attempts++;
      print('Attempt $attempts');
      // Simulate slow operation
      await Future.delayed(Duration(milliseconds: 200));
      throw Exception('Always fails');
    },
    maxAttempts: 10,
    delayFactor: Duration(milliseconds: 50),
    timeLimit: Duration(milliseconds: 500),
    lastTry: true,
    onRetry: (e, attempt) {
      print('onRetry called for attempt $attempt');
    },
    onTimeout: (attemptsMade, elapsed) {
      print('Timeout after $attemptsMade attempts ($elapsed)');
      return 'Fallback result';
    },
  );

  print('Result: $result\n');
}

/// Using RetryOptions for reusable configuration
Future<void> retryWithOptions() async {
  print('=== Using RetryOptions ===');

  final options = RetryOptions(
    maxAttempts: 3,
    delayFactor: Duration(milliseconds: 100),
    randomizationFactor: 0.1,
    maxDelay: Duration(seconds: 5),
  );

  var attempts = 0;
  final result = await options.retry(
    () async {
      attempts++;
      print('Attempt $attempts (delay: ${options.delay(attempts)})');
      if (attempts < 2) {
        throw Exception('Simulated failure');
      }
      return 'Success with RetryOptions';
    },
    onRetry: (e, attempt) {
      print('Retrying after exception: $e');
    },
  );

  print('Result: $result\n');
}
