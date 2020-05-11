part of 'isolate_supervisor.dart';

/// A handle to the isolate task context.
///
/// [IsolateContext] objects are passed to [IsolateEntryPoint] functions.
/// Each isolate task has its own [IsolateContext].
class IsolateContext<R>
{
  /// Name used to identify isolate in debuggers or loggers.
  final String isolateName;
  
  final IsolateTask<R> _task;
  final IsolateSink<R> _sink;

  /// Returns the isolate sink.
  IsolateSink<R> get sink => this._sink;

  /// Returns the isolate arguments collection.
  IsolateArguments get arguments => IsolateArguments.of(this);

  IsolateContext._(this._task, SendPort outPort, this.isolateName) :
    this._sink = IsolateSink<R>._(outPort, _task);
}