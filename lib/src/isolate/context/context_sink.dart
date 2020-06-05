part of './../isolate_worker.dart';

class _IsolateSink<R> implements IsolateSink<R>
{
  final SendPort _sendPort;
  final Capability _capability;

  _IsolateSink._(this._sendPort, this._capability);

  _IsolateSink.of(WorkerContext<R> context) : 
    this._(context._sendPort, context._task.capability);

  @override
  void add(R value) => 
    this._sendPort.send(IsolateResult.value(this._capability, value));

  @override
  void addError(Object error) => 
    this._sendPort.send(IsolateResult.error(this._capability, error));
}
