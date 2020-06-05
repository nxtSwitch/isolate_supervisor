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

/// Thrown when a function is passed an unacceptable argument.
class IsolateInvalidArgumentException
  extends ArgumentError implements IsolateException
{
  IsolateInvalidArgumentException(invalidValue, [name, message]) : 
    super.value(invalidValue, name, message);
}

/// Thrown when a function is passed an invalid isolate entry point.
class IsolateInvalidEntryPointException extends IsolateInvalidArgumentException
{
  IsolateInvalidEntryPointException(invalidValue) : super(
    invalidValue, 'entryPoint', 
    'Invalid argument: entryPoint must take an IsolateContext (the context)'
  );
}

/// Thrown when passed an incorrect number of isolates.
class IsolateInvalidCountException extends IsolateInvalidArgumentException
{
  IsolateInvalidCountException(invalidValue) : super(
    invalidValue, 'count','Invalid argument: count must be greater than 0'
  );
}

/// Thrown when error [StackTrace] is too big to return from isolate.
class IsolateTooBigStacktraceException extends Error implements IsolateException
{
  final String message;
  final String isolateName;
  final String _stackTrace;

  @override
  StackTrace get stackTrace => StackTrace.fromString(this._stackTrace);

  IsolateTooBigStacktraceException(this.isolateName, error) :
    this.message = error.toString(), 
    this._stackTrace = error is Error ? error.stackTrace.toString() : '';

  @override
  String toString() => '$isolateName: $message'; // \n$_stackTrace
}
