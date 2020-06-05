part of './../isolate_worker.dart';

class _IsolateArguments<A> implements IsolateArguments<A>
{
  final Iterable<A> _iterable;

  _IsolateArguments(this._iterable);
  
  _IsolateArguments.of(WorkerContext context) :
    this(context._task.arguments.whereType<A>());

  @override
  IsolateArguments<T> whereType<T>() => 
    _IsolateArguments<T>(this._iterable.whereType<T>());

  @override
  Iterable<A> get list => this._iterable;

  @override
  bool get isEmpty => this._iterable.isEmpty;

  @override
  bool get isNotEmpty => this._iterable.isNotEmpty;

  @override
  T nearest<T>() => this._iterable.whereType<T>().first;

  @override
  A operator [](int index) => this._iterable.elementAt(index);
}
