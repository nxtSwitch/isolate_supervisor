part of 'isolate_wrapper.dart';

class _IsolateContext<R> implements IsolateContext<R>
{
  final Stream _stream;
  final SendPort _sendPort;
  final String _isolateName;
  final IsolateRunnableTask<R> _task;
  final Map<String, _IsolateLock> _locks = {};

  @override
  String get isolateName => this._isolateName;

  @override
  IsolateSink<R> get sink => _IsolateSink<R>.of(this);

  @override
  IsolateArguments get arguments => _IsolateArguments.of(this);

  @override
  IsolateLock lock([String name]) => 
    this._locks[name] ??= _IsolateLock.of(this, name);
    
  _IsolateContext._(
    this._task, this._stream, this._sendPort, this._isolateName);

  void _releaseLocks() => this._locks.values.forEach((lock) => lock.release());
}