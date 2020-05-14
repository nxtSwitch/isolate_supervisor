part of 'isolate_wrapper.dart';

class _IsolateLock implements IsolateLock
{
  bool _isReleased = false;

  final String name;
  final Stream _stream;
  final SendPort _sendPort;
  final String _isolateName;
  final Capability _capability = Capability();

  _IsolateLock._(_IsolateContext context, this.name) :
    this._stream = context._stream,
    this._sendPort = context._sendPort,
    this._isolateName = context._isolateName;

  factory _IsolateLock.of(_IsolateContext context, String name) => 
    _IsolateLock._(context, name);

  @override
  void release() 
  {
    if (this._isReleased) return;
    
    final releaseEvent = IsolateLockEvent.release(this._capability, this.name);

    this._isReleased = true;
    this._sendPort.send(releaseEvent);
  }

  Future<IsolateLock> _acquire() async
  {
    final acquireEvent = IsolateLockEvent.acquire(this._capability, this.name);

    this._sendPort.send(acquireEvent);

    IsolateLockEvent event = await this._stream.firstWhere(
      (event) => event == acquireEvent, orElse: () => null);

    if (event == null) throw IsolateUndefinedException(this._isolateName);
    return this;
  }
}