part of 'isolate_supervisor.dart';

abstract class IsolateException implements Exception {}

/// Thrown when unknown exception occurred.
class IsolateUndefinedException implements IsolateException {}

/// Thrown when there aren't any isolate available to take the job.
class IsolateNoAvailableException implements IsolateException {}

/// Thrown when the task was forcibly canceled.
class IsolateForceExitException implements IsolateException {}

/// Thrown when the result type is not [IsolateResult].
class IsolateReturnInvalidTypeException implements IsolateException {}

/// Thrown when error [StackTrace] is too big to return from isolate.
class IsolateTooBigStacktraceException implements IsolateException 
{
  final Type type;
  final String message;
  final String stackTrace;
  final String isolateName;

  IsolateTooBigStacktraceException(this.isolateName, Error error) :
    this.type = error.runtimeType, 
    this.message = error.toString(), 
    this.stackTrace = error.stackTrace.toString();

  @override
  String toString() => '$isolateName: <$type> $message\n$stackTrace';
}
