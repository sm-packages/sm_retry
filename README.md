# sm_retry

[![pub package](https://img.shields.io/pub/v/sm_retry.svg)](https://pub.dev/packages/sm_retry)

[中文文档](README.zh.md)

Retry asynchronous functions with exponential backoff.

## Features

- Retry asynchronous functions with configurable exponential backoff
- Set maximum number of retry attempts
- Set total time limit for all retry attempts
- Configure delay factor and randomization
- Support for conditional retry with `retryIf`
- Callback support with `onRetry` and `onTimeout`
- `lastTry` option for one final attempt before timeout

## Installation

Add `sm_retry` to your `pubspec.yaml`:

```yaml
dependencies:
  sm_retry: ^1.0.0
```

## Usage

### Basic Usage

```dart
import 'package:sm_retry/sm_retry.dart';

final response = await retry(
  () => http.get('https://example.com'),
  maxAttempts: 5,
);
```

### Conditional Retry

```dart
final response = await retry(
  () => http.get('https://example.com').timeout(Duration(seconds: 5)),
  retryIf: (e, attempt) => e is SocketException || e is TimeoutException,
);
```

### With Time Limit

```dart
final response = await retry(
  () => http.get('https://example.com'),
  timeLimit: Duration(seconds: 30),
  onTimeout: (attempts, elapsed) {
    print('Timed out after $attempts attempts ($elapsed)');
    return fallbackResponse;
  },
);
```

### Using RetryOptions

```dart
final options = RetryOptions(
  maxAttempts: 5,
  delayFactor: Duration(milliseconds: 500),
  maxDelay: Duration(seconds: 10),
  timeLimit: Duration(seconds: 30),
  lastTry: true,
);

final response = await options.retry(
  () => http.get('https://example.com'),
  retryIf: (e, attempt) => e is SocketException,
  onRetry: (e, attempt) => print('Retry attempt $attempt'),
);
```

## Parameters

| Parameter             | Type                     | Default  | Description                                  |
| --------------------- | ------------------------ | -------- | -------------------------------------------- |
| `fn`                  | `FutureOr<T> Function()` | required | The function to retry                        |
| `delayFactor`         | `Duration`               | 200ms    | Base delay that doubles after each attempt   |
| `randomizationFactor` | `double`                 | 0.25     | Random variation applied to delays (0-1)     |
| `maxDelay`            | `Duration`               | 30s      | Maximum delay between retries                |
| `maxAttempts`         | `int`                    | 8        | Maximum number of attempts                   |
| `timeLimit`           | `Duration?`              | null     | Total time limit for all attempts            |
| `lastTry`             | `bool`                   | true     | Whether to attempt once more after timeout   |
| `retryIf`             | `RetryFunction<bool>?`   | null     | Condition to determine if retry should occur |
| `onRetry`             | `RetryFunction<void>?`   | null     | Callback called before each retry            |
| `onTimeout`           | `TimeoutCallback<T>?`    | null     | Callback called when timeout occurs          |

## Default Delay Schedule

With default settings, delays between attempts are:

| Attempt | Delay            |
| ------- | ---------------- |
| 1       | 400 ms +/- 25%   |
| 2       | 800 ms +/- 25%   |
| 3       | 1600 ms +/- 25%  |
| 4       | 3200 ms +/- 25%  |
| 5       | 6400 ms +/- 25%  |
| 6       | 12800 ms +/- 25% |
| 7       | 25600 ms +/- 25% |

## Acknowledgments

This package is based on [retry](https://pub.dev/packages/retry) by Google, licensed under the Apache License 2.0.

**Modifications:**

- Added `timeLimit` parameter for total retry time limit
- Added `lastTry` option for one final attempt before timeout
- Added `onTimeout` callback for timeout handling

## License

Apache License 2.0 - See [LICENSE](LICENSE) file for details.
