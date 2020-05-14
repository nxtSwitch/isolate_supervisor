import 'dart:async';

import './isolate_types.dart';
import './isolate_exceptions.dart';

import './events/isolate_event.dart';
import './registry/isolate_registry.dart';
import './schedule/isolate_schedule.dart';

class IsolateSupervisor
{
  final IsolateRegistry _isolates;
  final IsolateSchedule _schedule;

  IsolateSupervisor._(this._schedule, this._isolates);

  IsolateSupervisor() :
    this._(IsolateSchedule(), IsolateRegistry(null, false));

  factory IsolateSupervisor.spawn({int count, bool lazily}) => 
    IsolateSupervisor._(IsolateSchedule(), IsolateRegistry(count, lazily));

  /// Returns a result of the execution of the [function] with passed arguments.
  Future<R> compute<R>(
    IsolateEntryPoint<R> function, 
    [List arguments, TaskPriority priority]) async
  {
    if (this._isolates.isEmpty) throw IsolateNoIsolateAvailableException();

    final task = this._schedule.add(function, arguments, priority);
    this._arrangeWorkerOnSchedule();

    try {
      final result = await task.single();
      
      if (result is IsolateErrorResult<R>) throw result.error;
      if (result is IsolateValueResult<R>) return result.value;
    }
    finally {
      this._arrangeWorkerOnSchedule();
    }

    return null;
  }

  /// Returns a stream that contains results of the execution of the [function]
  /// with passed arguments.
  Stream<R> launch<R>(
    IsolateEntryPoint<R> function, 
    [List arguments, TaskPriority priority]) async*
  {
    if (this._isolates.isEmpty) throw IsolateNoIsolateAvailableException();

    final task = this._schedule.add(function, arguments, priority);
    this._arrangeWorkerOnSchedule();

    try {
      await for (final result in task.stream) {
        if (result is IsolateErrorResult<R>) throw result.error;
        if (result is IsolateValueResult<R>) yield result.value;
      }
    }
    finally {  
      await task.done;
      this._arrangeWorkerOnSchedule();
    }
  }

  /// Restarts isolates and incomplete tasks.
  Future<void> restart() async 
  {
    await this._isolates.restart();
    this._schedule.reset();
    
    this._arrangeWorkerOnSchedule();
  }
  
  /// Disposes of the isolate instances.
  Future<void> dispose() async 
  {
    await this._isolates.dispose();
    await this._schedule.clear();
  }

  void _arrangeWorkerOnSchedule() async
  {
    final isolate = await this._isolates.take();
    if (isolate == null) return;

    final enabled = this._schedule.schedule(isolate);
    if (!enabled) return isolate.free();
  }
}
