part of 'isolate_supervisor.dart';

/// An indexable collection of arguments.
class IsolateArguments<A>
{
  final List<A> _arguments;
  IsolateArguments._(this._arguments);

  /// Creates a [IsolateArguments<A>] from [context].
  factory IsolateArguments.of(IsolateContext context) => 
    IsolateArguments<A>._(context._task.arguments.whereType<A>().toList());

  /// Creates a [IsolateArguments<A>] from [IsolateArguments] instance.
  factory IsolateArguments.from(IsolateArguments isolateArguments) => 
    IsolateArguments<A>._(isolateArguments._arguments.whereType<A>());

  /// Obtains the nearest argument of [T] and returns its value.
  T nearest<T>() => this._arguments.whereType<T>().first;
  
  /// Returns the argument at the given [index] in the arguments list
  /// or throws a [RangeError] if [index] is out of bounds.
  A operator [](int index) => this._arguments[index];

  /// Returns `true` if there are no arguments.
  bool get isEmpty => this._arguments.isEmpty;

  /// Returns `true` if there is at least one argument exists.
  bool get isNotEmpty => this._arguments.isNotEmpty;
}