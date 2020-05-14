import 'dart:async';

import './../isolate_types.dart';
import './../events/isolate_event.dart';
import './../objects/isolate_task_object.dart';

part 'isolate_schedule_task.dart';

class IsolateSchedule
{
  final _tasks = <IsolateScheduleTask>[];  

  IsolateScheduleTask<R> add<R>(
    IsolateEntryPoint<R> function, List arguments, TaskPriority priority)
  {
    final object = IsolateTask<R>(function, arguments, priority);
    final task = IsolateScheduleTask<R>(object);  

    this._tasks
      ..add(task)
      ..sort((a, b) => b.priority.index - a.priority.index);

    return task;
  }

  bool schedule(IsolateScheduledExecutor executor)
  {
    if (executor == null) return false;

    final task = this._tasks.firstWhere(
      (entry) => entry.isAwaiting, orElse: () => null);

    task?.lock();
    task?.listen(executor.execute(task.object));

    return task != null;
  }

  void reset()
  {
    this._tasks.removeWhere((task) => task.isCompleted);
    this._tasks.forEach((task) { if (task.isProcessing) task.reset(); });
  } 

  Future<void> clear() async 
  {
    await Future.wait(this._tasks.map((task) => task.close()));
    this._tasks.clear();
  }
}