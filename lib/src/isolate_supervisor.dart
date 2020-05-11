import 'dart:io';
import 'dart:async';
import 'dart:isolate';

part 'isolate_task.dart';
part 'isolate_pool.dart';
part 'isolate_sink.dart';
part 'isolate_result.dart';
part 'isolate_wrapper.dart';
part 'isolate_context.dart';
part 'isolate_schedule.dart';
part 'isolate_arguments.dart';
part 'isolate_exceptions.dart';

class IsolateSupervisor
{
  final _workers = IsolatePool();
  final _schedule = IsolateSchedule();

  IsolateSupervisor._();
  factory IsolateSupervisor() => _instance;
  static final IsolateSupervisor _instance = IsolateSupervisor._();

  /// Returns a result of the execution of the [function] with passed arguments.
  Future<R> compute<R>(
    IsolateEntryPoint<FutureOr<R>> function, [List arguments]) async
  {
    if (this._workers.isEmpty) throw IsolateNoAvailableException();

    final task = this._schedule.add(function, arguments);
    this._arrangeWorkerOnSchedule();

    final result = await task.stream.first;
    task.close();

    this._arrangeWorkerOnSchedule();

    if (result is IsolateExitResult) return null;
    if (result is IsolateErrorResult) throw result.error;
    if (result is IsolateValueResult) return result.value;
    
    throw IsolateReturnInvalidTypeException();
  }

  /// Returns a stream that contains results of the execution of the [function]
  /// with passed arguments.
  Stream<R> launch<R>(
    IsolateEntryPoint<Stream<R>> function, [List arguments]) async*
  {
    if (this._workers.isEmpty) throw IsolateNoAvailableException();

    final task = this._schedule.add(function, arguments);
    this._arrangeWorkerOnSchedule();

    try {
      await for (final result in task.stream) {
        if (result is IsolateExitResult) break;
        if (result is IsolateErrorResult) throw result.error;
        if (result is IsolateValueResult) yield result.value;
        
        if (result is! IsolateResult) throw IsolateReturnInvalidTypeException();
      }
    }
    finally {  
      task.close();
      this._arrangeWorkerOnSchedule();
    }
  }

  /// Restarts isolates and incomplete tasks.
  Future<void> restart() async 
  {
    this._schedule.reset();
    await this._workers.restart();
    
    this._arrangeWorkerOnSchedule();
  }
  /// Disposes of the isolate instances.
  Future<void> dispose() async 
  {
    await this._workers.dispose();
    await this._schedule.close();
  }

  void _arrangeWorkerOnSchedule() async
  {
    final worker = await this._workers.take();
    if (worker == null) return;

    final task = this._schedule.attach(worker);
    if (task == null) return worker.free();

    this._schedule.addListener(task?.execute());
  }
}
