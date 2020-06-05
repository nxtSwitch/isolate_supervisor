import 'isolate_event.dart';

/// [IsolateProcess] represents the methods to interact with the running 
/// process.
abstract class IsolateProcess
{
  /// Kills the process.
  Future<void> kill();

  /// Resumes a paused process.
  void resume();

  /// Requests the process to pause.
  void pause();

  /// Returns the output stream of the process as a `Stream`.
  Stream<IsolateEvent> get output;

  /// Passes the event to the target consumer.
  /// 
  /// Returns `true` if the event is successfully delivered to the process.
  bool send(IsolateEvent event);
}
