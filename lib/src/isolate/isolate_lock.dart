part of 'isolate_wrapper.dart';

enum _IsolateLockState { released, acquired }

class _IsolateLock implements IsolateLock
{
  bool _isReleased = false;

  _IsolateLockState _state;

  final String name;
  final Stream _stream;
  final SendPort _sendPort;
  final String _isolateName;
  final Capability _capability = Capability();

  _IsolateLock._(_IsolateContext context, this.name) :
    this._stream = context._stream,
    this._sendPort = context._sendPort,
    this._isolateName = context._isolateName;

  _IsolateLock.of(_IsolateContext context, String name) : this._(context, name);

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

  @override
  int get hashCode => this.name.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _IsolateLock &&
      runtimeType == other.runtimeType && this.name == other.name;
}