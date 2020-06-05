/// Possible states of [IsolateTask].
enum IsolateTaskStatus { awaiting, processing, paused, completed, canceled }

/// An isolate task object.
abstract class IsolateTask<R>
{
  /// Whether the task is currently paused.
  bool get isPaused;

  /// Whether the task is canceled.
  bool get isCanceled;

  /// Whether the task is completed.
  bool get isCompleted;

  /// Returns the task status.
  IsolateTaskStatus get status;

  /// Returns the output stream of the task.
  Stream<R> get output;

  /// Return a future which is completed when the task started executing.
  Future<void> get wait async => null;

  /// Return a future which is completed when the task is finished.
  Future<void> get done async => null;

  /// Requests the task to pause.
  void pause();

  /// Resumes a paused task.
  void resume();

  /// Passes the value to the task.
  /// 
  /// Returns `true` if the value is successfully delivered to the isolate.
  bool send(dynamic value);

  /// Cancels this task.
  Future<void> cancel();
}
