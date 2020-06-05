part of './../isolate_worker.dart';

class WorkerContext<R> implements IsolateContext<R>
{
  final Stream _stream;
  final SendPort _sendPort;
  final String _isolateName;
  final IsolateRunnable<R> _task;
  final Map<String, _IsolateLock> _locks = {};

  @override
  String get isolateName => this._isolateName;

  @override
  IsolateSink<R> get sink => _IsolateSink<R>.of(this);

  @override
  IsolateLock lock([String name]) => 
    this._locks[name] ??= _IsolateLock.of(this, name);

  @override
  IsolateArguments get arguments => _IsolateArguments.of(this);

  @override
  Stream get input => _stream
      .where((event) => event is IsolateValueResult)
      .map((event) => event.value);

  WorkerContext(this._task, this._stream, this._sendPort, this._isolateName);

  void dispose() 
  {
    for (final lock in this._locks.values) {
      lock.release();
    }
  }
}
