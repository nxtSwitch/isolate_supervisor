part of 'isolate_supervisor.dart';

enum TaskStatus { awaiting, processing, completed }
enum TaskPriority { low, regular, high }

typedef IsolateEntryPoint<R> = R Function(IsolateContext<R> context);

class IsolateTask<R>
{
  final List arguments;
  final Capability capability;
  final TaskPriority priority;
  final IsolateEntryPoint<R> function;

  TaskStatus status = TaskStatus.awaiting;

  IsolateTask(this.function, this.arguments, [TaskPriority priority]) : 
    assert(function != null),
    this.capability = Capability(),
    this.priority = priority ?? TaskPriority.regular;

  void lock() => this.status = TaskStatus.processing;
  void close() => this.status = TaskStatus.completed;

  bool get isAwaiting => this.status == TaskStatus.awaiting;
}