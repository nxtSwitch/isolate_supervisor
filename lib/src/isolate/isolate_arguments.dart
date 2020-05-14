part of 'isolate_wrapper.dart';

class _IsolateArguments<A> implements IsolateArguments<A>
{
  final Iterable<A> _arguments;
  _IsolateArguments._(this._arguments);

  factory _IsolateArguments.of(_IsolateContext context) => 
    _IsolateArguments<A>._(context._task.arguments.whereType<A>());

  factory _IsolateArguments.from(_IsolateArguments arguments) => 
    _IsolateArguments<A>._(arguments._arguments.whereType<A>());

  @override
  T nearest<T>() => this._arguments.whereType<T>().first;
  
  @override
  A operator [](int index) => this._arguments.elementAt(index);

  @override
  bool get isEmpty => this._arguments.isEmpty;

  @override
  bool get isNotEmpty => this._arguments.isNotEmpty;
}