/// Possible priorities for tasks.
enum TaskPriority { low, regular, high }

/// Isolate entrypoint function.
typedef IsolateEntryPoint<R> = Function(IsolateContext<R> context);

/// A handle to the isolate task context.
///
/// [IsolateContext] objects are passed to [IsolateEntryPoint] functions.
/// Each isolate task has its own [IsolateContext].
abstract class IsolateContext<R>
{
  /// Returns the name used to identify isolate in debuggers or loggers.
  String get isolateName;

  /// Returns the isolate sink.
  IsolateSink<R> get sink;

  /// Returns the primitive lock object.
  Future<IsolateLock> lock([String name]);

  /// Returns the isolate arguments collection.
  IsolateArguments get arguments;
}

/// A isolate data receiver.
abstract class IsolateSink<R>
{
  /// Adds [value] to the sink.
  void add(R value);

  /// Adds an [error] to the sink.
  void addError(Object error);
}

/// An indexable collection of arguments.
abstract class IsolateArguments<A>
{
  /// Returns `true` if there are no arguments.
  bool get isEmpty;

  /// Returns `true` if there is at least one argument exists.
  bool get isNotEmpty;

  /// Obtains the nearest argument of [T] and returns its value
  /// or throws a [StateError] if argument does not exist.
  T nearest<T>();
  
  /// Returns the argument at the given [index] in the arguments list
  /// or throws a [RangeError] if [index] is out of bounds.
  A operator [](int index);

  /// Creates a [IsolateArguments<A>] from [context].
  factory IsolateArguments.of(IsolateContext context) => null;

  /// Creates a [IsolateArguments<A>] from [IsolateArguments] 
  /// instance.
  factory IsolateArguments.from(IsolateArguments arguments) => null;
}

/// A primitive lock object.
/// 
/// Once a isolate has acquired it, subsequent attempts to acquire it block, 
/// until it is released.
abstract class IsolateLock
{
  /// Releases a lock.
  void release();
}

/// An object that can be run by [IsolateScheduledExecutor]. 
abstract class IsolateRunnableTask<R>
{
  dynamic get capability;
  Iterable get arguments;
  dynamic run(IsolateContext<R> context);
}

/// An object that execute submitted [IsolateRunnableTask]. 
abstract class IsolateScheduledExecutor
{
  /// Executes the given [IsolateRunnableTask] inside the isolate.
  Stream execute(IsolateRunnableTask task);
}