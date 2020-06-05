import 'isolate_process.dart';
import 'isolate_runnable.dart';

/// An object that execute submitted [IsolateRunnable]. 
abstract class IsolateExecutor
{
  /// Executes the given [IsolateRunnable] inside the isolate.
  IsolateProcess execute<R>(IsolateRunnable<R> task);
}
