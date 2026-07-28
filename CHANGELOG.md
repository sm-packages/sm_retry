## 1.0.0

- Initial release
- Retry asynchronous functions with exponential backoff
- Configurable delay factor, randomization factor, max delay, and max attempts
- `timeLimit` - Total time limit for all retry attempts
- `lastTry` - Option to attempt one final retry when timeout occurs
- `onTimeout` - Callback when timeout occurs
- `retryIf` - Conditional retry based on exception type
- `onRetry` - Callback before each retry attempt
