part of 'isolate_supervisor.dart';

/// A isolate data receiver.
class IsolateSink<R>
{
  final SendPort _outPort;
  final IsolateTask _task;
  
  IsolateSink._(this._outPort, this._task);

  /// Adds [value] to the sink.
  void add(R value) => 
    this._outPort.send(IsolateResult.value(this._task, value));

  /// Adds an [error] to the sink.
  void addError(Object error) => 
    this._outPort.send(IsolateResult.error(this._task, error));
}