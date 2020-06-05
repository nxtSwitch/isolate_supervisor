import 'isolate_context.dart';

/// An object that can be run by [IsolateExecutor]. 
abstract class IsolateRunnable<R>
{
  /// Capability granting the ability to identify the task.
  dynamic get capability;

  /// Contains the arguments provided for the task.
  Iterable get arguments;

  /// Runs the task with the specified [arguments].
  dynamic run(IsolateContext<R> context);
}
