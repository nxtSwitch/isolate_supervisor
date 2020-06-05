import 'dart:io';
import 'dart:async';
import 'dart:collection';

import './exceptions.dart';
import './helpers/lock.dart';
import './schedule/task.dart';
import './base/isolate_task.dart';
import './isolate/isolate_wrapper.dart';
import './registry/mutex_registry.dart';
import './base/isolate_entry_point.dart';

/// A [IsolateSupervisor] creates and oversees a pool of isolates.
class IsolateSupervisor
{
  static int _numberOfIsolates = 0;

  final _isolates = <IsolateWrapper>[];
  final _schedule = Queue<IsolateScheduleTask>();

  final _lock = Lock();
  final _mutex = IsolateMutexRegistry();

  /// Returns the number of isolates.
  static int get numberOfIsolates => IsolateSupervisor._numberOfIsolates;

  /// Returns the number of available execution units of the machine.
  static int get availableProcessors => 
    (Platform.numberOfProcessors - 1) - IsolateSupervisor._numberOfIsolates;

  /// Creates a isolate pool with `availableProcessors` isolates.
  IsolateSupervisor() : this._(null, false);

  /// Creates a isolate pool of the given length.
  ///
  /// The default length is equal to `availableProcessors`.
  /// 
  /// If the [lazily] parameter is set to `true`, the isolate will start lazily,
  /// as tasks are required to execute. The default is `false`.
  IsolateSupervisor.spawn({int count, bool lazily}) : this._(count, lazily);

  /// Creates and spawns isolates.
  IsolateSupervisor._(int count, bool lazily)
  {
    count ??= availableProcessors;

    if (availableProcessors <= 0 || count > availableProcessors) {
      throw IsolateNoProcessorsAvailableException(availableProcessors);
    }

    if (count <= 0) throw IsolateInvalidCountException(count);
    
    for (int i = 0; i < count; ++i) {
      IsolateSupervisor._numberOfIsolates += 1;
      this._isolates.add(IsolateWrapper('Isolate #$numberOfIsolates', lazily));
    }
  }

  /// Return an [IsolateTask] object representing the task that needs to be 
  /// executed.
  IsolateTask<R> execute<R>(IsolateEntryPoint<R> action, [List arguments])
  {
    if (action == null) throw IsolateInvalidEntryPointException(null);

    if (this._isolates.isEmpty) {
      throw IsolateNoIsolateAvailableException();
    }

    final task = IsolateScheduleTask(action, arguments);

    task.onDone = this._arrangeWorkerOnTask;
    task.onResume = () {
      this._schedule.add(task);
      this._arrangeWorkerOnTask();
    };

    this._schedule.add(task);
    this._arrangeWorkerOnTask();

    return task;
  }

  /// Returns a result of the execution of the [action] with passed arguments.
  Future<R> compute<R>(IsolateEntryPoint<R> action, [List arguments]) async
  {
    final task = this.execute(action, arguments);

    await for (final result in task.output) {
      return result;
    }

    return null;
  }

  /// Returns a stream that contains results of the execution of the [action] 
  /// with passed arguments.
  Stream<R> launch<R>(IsolateEntryPoint<R> action, [List arguments])
  {
    final task = this.execute(action, arguments);
    return task.output;
  }

  /// Restarts isolates and cancels incomplete tasks.
  Future<void> reset() async 
  {
    await this._lock.acquire();
    try {
      for (final isolate in this._isolates) {
        await isolate.cancel();
      }

      for (final task in this._schedule) {
        await task.cancel();
      }

      this._schedule.clear();
    }
    finally {
      this._lock.release();
    }
  }

  /// Disposes of the isolate instances.
  Future<void> dispose() async
  {
    await this._lock.acquire();
    try {
      for (final isolate in this._isolates) {
        await isolate.dispose();
        IsolateSupervisor._numberOfIsolates -= 1;
      }
      this._isolates.clear();

      for (final task in this._schedule) {
        await task.cancel();
      }
      this._schedule.clear();
    }
    finally {
      this._lock.release();
    }
  }

  /// Arranges worker on task.
  void _arrangeWorkerOnTask() async
  {
    if (this._lock.locked) return;
    if (this._isolates.isEmpty || this._schedule.isEmpty) return;

    final task = this._schedule.removeFirst();
    if (!task.isAwaiting) return;

    for (IsolateWrapper isolate in this._isolates) {
      await isolate.initialize;

      if (!isolate.isIdle) continue;
      if (!task.isAwaiting) return;

      final process = isolate.execute(task.action);
      task.attach(process);

      this._mutex.register(process);
      // this._values.register(process);
      return;
    }

    this._schedule.addFirst(task);
  }

  /// Alias of [reset].
  @Deprecated('Use IsolateSupervisor.reset() instead.')
  Future<void> restart() => this.reset();
}
