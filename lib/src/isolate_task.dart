part of 'isolate_supervisor.dart';

enum _TaskStatus { awaiting, processing, completed }
enum TaskPriority { low, regular, high }

typedef _IsolateEntryPoint<R> = R Function(IsolateContext<R> context);

class IsolateTask<R>
{
  final List arguments;
  final Capability capability;
  final TaskPriority priority;
  final _IsolateEntryPoint<R> function;

  _TaskStatus _status = _TaskStatus.awaiting;

  IsolateTask(this.function, this.arguments, TaskPriority priority) : 
    assert(function != null),
    this.capability = Capability(),
    this.priority = priority ?? TaskPriority.regular;

  void reset() => this._status = _TaskStatus.awaiting;
  void lock() => this._status = _TaskStatus.processing;
  void close() => this._status = _TaskStatus.completed;

  bool get isAwaiting => this._status == _TaskStatus.awaiting;
  bool get isCompleted => this._status == _TaskStatus.completed;
  bool get isProcessing => this._status == _TaskStatus.processing;
}