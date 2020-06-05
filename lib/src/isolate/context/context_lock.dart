part of './../isolate_worker.dart';

enum _IsolateLockState { released, acquired }

class _IsolateLock implements IsolateLock
{
  _IsolateLockState _state;

  final String name;
  final Stream _stream;
  final SendPort _sendPort;
  final String _isolateName;
  final Capability _capability = Capability();

  _IsolateLock(WorkerContext context, this.name) :
    this._stream = context._stream,
    this._sendPort = context._sendPort,
    this._isolateName = context._isolateName;

  _IsolateLock.of(IsolateContext context, String name) : 
    this(context, name);

  @override
  void release() 
  {
    if (this._state == _IsolateLockState.released) return;
    
    final releaseEvent = IsolateLockEvent.release(this._capability, this.name);

    this._sendPort.send(releaseEvent);
    this._state = _IsolateLockState.released;
  }

  @override
  Future<void> acquire() async
  {
    if (this._state == _IsolateLockState.acquired) return;

    final acquireEvent = IsolateLockEvent.acquire(this._capability, this.name);

    this._sendPort.send(acquireEvent);
    this._state = _IsolateLockState.acquired;

    IsolateLockEvent event = await this._stream.firstWhere(
      (event) => event == acquireEvent, orElse: () => null);

    if (event == null) throw IsolateUndefinedException(this._isolateName);
  }
}
