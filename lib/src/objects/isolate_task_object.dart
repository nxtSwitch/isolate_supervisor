import 'dart:isolate';

import './../isolate_types.dart';

class IsolateTask<R> implements IsolateRunnableTask<R>
{
  @override
  final List arguments;

  final TaskPriority priority;
  final IsolateEntryPoint<R> function;

  @override
  final Capability capability = Capability();

  IsolateTask(this.function, List arguments, TaskPriority priority) :
    this.arguments = arguments ?? [],
    this.priority = priority ?? TaskPriority.regular;

  @override
  dynamic run(IsolateContext<R> context) => this.function(context);
}