import 'dart:isolate';

import './../exceptions.dart';
import './../events/events.dart';
import './../base/isolate_context.dart';
import './../base/isolate_runnable.dart';

part './context/context.dart';
part './context/context_sink.dart';
part './context/context_lock.dart';
part './context/context_arguments.dart';

Future<void> isolateWorker(SendPort sendPort) async 
{
  final receivePort = ReceivePort();
  final broadcast = receivePort.asBroadcastStream();

  sendPort.send(IsolateHandshakeEvent(receivePort.sendPort));
  
  final debugName = await broadcast.first;
  final tasks = broadcast.where((data) => data is IsolateRunnable);

  await for (IsolateRunnable task in tasks) {
    final context = WorkerContext(task, broadcast, sendPort, debugName);

    try {
      final result = task.run(context);
      
      if (result is! Stream) {
        context.sink.add(await result);
        continue;
      }

      await for (final value in result) {
        context.sink.add(value);
      }
    } 
    on dynamic catch (error) {
      try {
        context.sink.addError(error);
      } 
      on ArgumentError catch (_) {
        context.sink.addError(
          IsolateTooBigStacktraceException(debugName, error));
      }
      catch(_) {
        context.sink.addError(IsolateUndefinedException(debugName));
      }
    }
    finally {
      context.dispose();
      sendPort.send(IsolateProcessExitEvent(task.capability));
    }
  }
}
