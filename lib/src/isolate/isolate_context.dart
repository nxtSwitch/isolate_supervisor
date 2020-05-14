part of 'isolate_wrapper.dart';

class _IsolateContext<R> implements IsolateContext<R>
{
  final Stream _stream;
  final SendPort _sendPort;
  final String _isolateName;
  final IsolateRunnableTask<R> _task;
  final List<_IsolateLock> _locks = <_IsolateLock>[];

  @override
  String get isolateName => this._isolateName;

  @override
  IsolateSink<R> get sink => _IsolateSink<R>.of(this);

  @override
  IsolateArguments get arguments => _IsolateArguments.of(this);

  @override
  Future<IsolateLock> lock([String name]) =>
    (this._locks..add(_IsolateLock.of(this, name))).last._acquire();
    
  _IsolateContext._(
    this._task, this._stream, this._sendPort, this._isolateName);

  void _releaseLocks() => this._locks.forEach((lock) => lock.release());
}