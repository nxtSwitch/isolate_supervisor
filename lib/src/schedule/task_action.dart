part of 'task.dart';

class IsolateScheduleTaskAction<R> implements IsolateRunnable<R>
{
  @override
  final List arguments;

  final IsolateEntryPoint function;

  @override
  final Capability capability = Capability();

  IsolateScheduleTaskAction(this.function, List arguments) :
    this.arguments = arguments ?? [];

  @override
  dynamic run(IsolateContext context) => this.function(context);
}
