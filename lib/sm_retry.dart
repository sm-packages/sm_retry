/// Retry asynchronous functions with exponential backoff.
///
/// For a simple solution see [retry], to modify and persist retry options see
/// [RetryOptions]. Note, in many cases the added configurability is
/// unnecessary and using [retry] is perfectly fine.
library;

export 'src/retry.dart';
