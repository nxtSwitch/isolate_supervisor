part of 'isolate_supervisor.dart';

abstract class IsolateResult<R>
{
  final Capability capability;
  IsolateResult(this.capability);

  factory IsolateResult.value(IsolateTask<R> task, R value) => 
    IsolateValueResult<R>(task, value);

  factory IsolateResult.error(IsolateTask<R> task, Object error) =>
      IsolateErrorResult<R>(task, error);

  factory IsolateResult.exit(IsolateTask<R> task) => 
    IsolateExitResult<R>(task);
}

class IsolateValueResult<R> extends IsolateResult<R> 
{
  final R value;
  IsolateValueResult(IsolateTask task, this.value) : super(task.capability);
}

class IsolateErrorResult<R> extends IsolateResult<R> 
{
  final Object error;
  IsolateErrorResult(IsolateTask task, this.error) : super(task.capability);
}

class IsolateExitResult<R> extends IsolateResult<R> 
{
  IsolateExitResult(IsolateTask task) : super(task.capability);
}
