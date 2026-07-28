# sm_retry

[![pub package](https://img.shields.io/pub/v/sm_retry.svg)](https://pub.dev/packages/sm_retry)

[English](README.md)

异步函数指数退避重试库。

## 功能特性

- 支持可配置的指数退避重试策略
- 可设置最大重试次数
- 可设置所有重试的总时间限制
- 可配置延迟因子和随机化因子
- 支持 `retryIf` 条件重试
- 支持 `onRetry` 和 `onTimeout` 回调
- `lastTry` 选项允许超时前进行最后一次尝试

## 安装

在 `pubspec.yaml` 中添加 `sm_retry`:

```yaml
dependencies:
  sm_retry: ^1.0.0
```

## 使用方法

### 基本用法

```dart
import 'package:sm_retry/sm_retry.dart';

final response = await retry(
  () => http.get('https://example.com'),
  maxAttempts: 5,
);
```

### 条件重试

```dart
final response = await retry(
  () => http.get('https://example.com').timeout(Duration(seconds: 5)),
  retryIf: (e, attempt) => e is SocketException || e is TimeoutException,
);
```

### 设置时间限制

```dart
final response = await retry(
  () => http.get('https://example.com'),
  timeLimit: Duration(seconds: 30),
  onTimeout: (attempts, elapsed) {
    print('超时: 尝试了 $attempts 次 (耗时 $elapsed)');
    return fallbackResponse;
  },
);
```

### 使用 RetryOptions

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
  onRetry: (e, attempt) => print('第 $attempt 次重试'),
);
```

## 参数说明

| 参数                  | 类型                     | 默认值 | 描述                       |
| --------------------- | ------------------------ | ------ | -------------------------- |
| `fn`                  | `FutureOr<T> Function()` | 必需   | 需要重试的函数             |
| `delayFactor`         | `Duration`               | 200ms  | 每次尝试后翻倍的基础延迟   |
| `randomizationFactor` | `double`                 | 0.25   | 应用于延迟的随机变化 (0-1) |
| `maxDelay`            | `Duration`               | 30s    | 重试之间的最大延迟         |
| `maxAttempts`         | `int`                    | 8      | 最大尝试次数               |
| `timeLimit`           | `Duration?`              | null   | 所有尝试的总时间限制       |
| `lastTry`             | `bool`                   | true   | 超时后是否再尝试一次       |
| `retryIf`             | `RetryFunction<bool>?`   | null   | 判断是否应该重试的条件     |
| `onRetry`             | `RetryFunction<void>?`   | null   | 每次重试前调用的回调       |
| `onTimeout`           | `TimeoutCallback<T>?`    | null   | 超时时调用的回调           |

## 默认延迟时间表

使用默认设置时，各次尝试之间的延迟为:

| 尝试次数 | 延迟             |
| -------- | ---------------- |
| 1        | 400 ms +/- 25%   |
| 2        | 800 ms +/- 25%   |
| 3        | 1600 ms +/- 25%  |
| 4        | 3200 ms +/- 25%  |
| 5        | 6400 ms +/- 25%  |
| 6        | 12800 ms +/- 25% |
| 7        | 25600 ms +/- 25% |

## 致谢

本库基于 Google 的 [retry](https://pub.dev/packages/retry) 包修改，原库采用 Apache License 2.0 许可证。

**修改内容：**

- 新增 `timeLimit` 参数，支持设置总重试时间限制
- 新增 `lastTry` 选项，支持超时前进行最后一次尝试
- 新增 `onTimeout` 回调，支持超时时的自定义处理

## 许可证

Apache License 2.0 - 详见 [LICENSE](LICENSE) 文件。
