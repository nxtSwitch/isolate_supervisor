abstract class IsolateException implements Exception {}

/// Thrown when unknown exception occurred.
class IsolateUndefinedException implements IsolateException 
{
  final String isolateName;
  IsolateUndefinedException(this.isolateName);
}

/// Thrown when there aren't any isolate available to take the job.
class IsolateNoIsolateAvailableException implements IsolateException {}

/// Thrown when there aren't any processor available.
class IsolateNoProcessorsAvailableException implements IsolateException 
{
  final int availableProcessors;
  IsolateNoProcessorsAvailableException(this.availableProcessors);

  @override
  String toString() => 'Available processors: $availableProcessors';
}

/// Thrown when error [StackTrace] is too big to return from isolate.
class IsolateTooBigStacktraceException implements IsolateException 
{
  final Type type;
  final String message;
  final String isolateName;
  final String _stackTrace;

  StackTrace get stackTrace => 
    StackTrace.fromString(this._stackTrace);

  IsolateTooBigStacktraceException(this.isolateName, Error error) :
    this.type = error.runtimeType, 
    this.message = error.toString(), 
    this._stackTrace = error.stackTrace.toString();

  @override
  String toString() => '$isolateName: <$type> $message\n$stackTrace';
}
