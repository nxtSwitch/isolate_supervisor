import 'dart:async';

import './isolate_types.dart';
import './isolate_exceptions.dart';

import './events/isolate_event.dart';
import './registry/isolate_registry.dart';
import './schedule/isolate_schedule.dart';

class IsolateSupervisor
{
  bool _isDestroyed = false;

  final IsolateRegistry _isolates;
  final IsolateSchedule _schedule;

  IsolateSupervisor._(this._schedule, this._isolates);

  IsolateSupervisor() :
    this._(IsolateSchedule(), IsolateRegistry(null, false));

  factory IsolateSupervisor.spawn({int count, bool lazily}) => 
    IsolateSupervisor._(IsolateSchedule(), IsolateRegistry(count, lazily));

  /// Returns the number of isolates.
  static int numberOfIsolates() => IsolateRegistry.numberOfIsolates;

  /// Returns a result of the execution of the [entryPoint] with passed 
  /// arguments.
  Future<R> compute<R>(
    IsolateEntryPoint<R> entryPoint, 
    [List arguments, TaskPriority priority]) async
  {
    if (entryPoint == null) throw IsolateInvalidEntryPointException(null);

    if (this._isDestroyed || !this._isolates.isInitialized) {
      throw IsolateNoIsolateAvailableException();
    }

    final task = this._schedule.add(entryPoint, arguments, priority);
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

  /// Returns a stream that contains results of the execution of the 
  /// [entryPoint] with passed arguments.
  Stream<R> launch<R>(
    IsolateEntryPoint<R> entryPoint, 
    [List arguments, TaskPriority priority]) async*
  {
    if (entryPoint == null) throw IsolateInvalidEntryPointException(null);

    if (this._isDestroyed || !this._isolates.isInitialized) {
      throw IsolateNoIsolateAvailableException();
    }

    final task = this._schedule.add(entryPoint, arguments, priority);
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

  /// Alias of [reset].
  @Deprecated('Use IsolateSupervisor.reset() instead.')
  Future<void> restart() => this.reset();

  /// Restarts isolates and cancels incomplete tasks.
  Future<void> reset() async 
  {
    await this._schedule.reset();
    await this._isolates.restart();
  }
  
  /// Disposes of the isolate instances.
  Future<void> dispose() async 
  {
    this._isDestroyed = true;
    await this._schedule.clear();
    await this._isolates.dispose();
  }

  void _arrangeWorkerOnSchedule() async
  {
    if (this._isDestroyed) return;

    final isolate = await this._isolates.take();
    if (isolate == null) return;
    
    final enabled = this._schedule.schedule(isolate);
    if (!enabled) return isolate.free();
  }
}
