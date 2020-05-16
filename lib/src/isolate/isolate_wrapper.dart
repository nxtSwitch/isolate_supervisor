import 'dart:async';
import 'dart:isolate';

import './../isolate_types.dart';
import './../isolate_exceptions.dart';
import './../events/isolate_event.dart';

part 'isolate_sink.dart';
part 'isolate_lock.dart';
part 'isolate_context.dart';
part 'isolate_arguments.dart';

enum _IsolateStatus { none, initialized, idle, arrives, attached }

class _IsolateNotIdleException  implements IsolateException {}
class _IsolateEmptyTaskException   implements IsolateException {}
class _IsolateTaskNotCompletedException implements IsolateException {}

class IsolateWrapper implements IsolateScheduledExecutor
{
  final String name;
  _IsolateStatus status;

  Isolate _isolate;
  SendPort _sendPort;
  ReceivePort _receivePort;
  Completer<bool> _initCompleter;
  Stream<IsolateEvent> _broadcast;

  Function(Stream<IsolateEvent>) _onSpawn;

  bool get isIdle => this.status == _IsolateStatus.idle;
  bool get isAttached => this.status == _IsolateStatus.attached;
  bool get isUninitialized => this.status == _IsolateStatus.none;
  
  void free() => this.status = _IsolateStatus.idle;
  void lock() => this.status = _IsolateStatus.attached;

  IsolateWrapper(this.name, bool spawnLazily)
  { 
    this.status = _IsolateStatus.none;
    
    this._resetCompleter();
    if (!spawnLazily) this._spawn();
  }

  Future<bool> initialize()
  {
    this._spawn();
    return this._initCompleter.future;
  }

  void listen(Function(Stream<IsolateEvent>) onSpawn)
  {
    if (onSpawn == null) return;
    this._onSpawn = onSpawn;
  }

  void _resetCompleter() 
  {
    this._initCompleter = Completer<bool>();
    this._initCompleter.future.then(
      (success) { 
        if (success && this._onSpawn != null) {
          this._onSpawn(this._broadcast); 
        }
      },
      onError: (_) {}
    );
  }

  Future<void> _spawn() async
  {
    if (this._initCompleter.isCompleted) return;
    if (this.status != _IsolateStatus.none) return;
    
    this.status = _IsolateStatus.initialized;
    this._receivePort = ReceivePort();

    try {
      this._isolate = await Isolate.spawn(
        IsolateWrapper._entryPoint, 
        this._receivePort.sendPort, 
        paused: false,
        debugName: this.name,
        errorsAreFatal: false
      );
    } 
    on dynamic catch (_) {
      this._initCompleter.complete(false);
      return;
    }

    this._broadcast = this._receivePort
      .where((event) => event is IsolateEvent)
      .cast<IsolateEvent>()
      .asBroadcastStream();
    
    final event = await this._broadcast.first;

    if (event is! IsolateHandshakeEvent) {
      this._initCompleter.complete(false);
      return;
    }
  
    this._sendPort = (event as IsolateHandshakeEvent).sendPort;
    this._sendPort.send(this.name);

    this.status = _IsolateStatus.idle;
    this._initCompleter.complete(true);
  }

  void sendEvent(IsolateEvent event)
  {
    if (event == null) return;
    if (this.status != _IsolateStatus.arrives) return;
    if (this._sendPort == null) throw IsolateUndefinedException(this.name);

    this._sendPort.send(event);
  }

  @override
  Stream<IsolateEvent> execute(IsolateRunnableTask task) async*
  {
    if (!this.isAttached) throw _IsolateNotIdleException();
    
    if (task == null) {
      this.status = _IsolateStatus.idle;
      throw _IsolateEmptyTaskException();
    }
    
    if (this._sendPort == null || this._broadcast == null) {
      this.status = _IsolateStatus.none;
      throw IsolateUndefinedException(this.name);
    }

    try {
      this.status = _IsolateStatus.arrives;
      this._sendPort.send(task);

      await for(final event in this._broadcast) {
        yield event;
        if (event is IsolateExitEvent) return;
      }
    }
    catch(_) {
      throw _IsolateTaskNotCompletedException();
    }
    finally {
      this.status = _IsolateStatus.idle;
    }
  }

  Future<void> cancel() async 
  {
    await this.dispose();
    this._resetCompleter();

    await this._spawn();
  }

  Future<void> dispose() async 
  {
    if (!this.isUninitialized) {
      await this._initCompleter.future;
      this._resetCompleter();
    }

    this._isolate?.kill();
    this._receivePort?.close();

    this._isolate = null;
    this._sendPort = null;
    this._broadcast = null;
    this._receivePort = null;

    this.status = _IsolateStatus.none;
    this._initCompleter.complete(false);
  }

  static void _entryPoint(SendPort sendPort) async 
  {
    final receivePort = ReceivePort();
    final broadcast = receivePort.asBroadcastStream();

    sendPort.send(IsolateEvent.handshake(receivePort.sendPort));
    
    final isolateName = await broadcast.first;
    final tasksStream = broadcast.where((data) => data is IsolateRunnableTask);
    
    await for (IsolateRunnableTask task in tasksStream) {
      final context = _IsolateContext._(task, broadcast, sendPort, isolateName);

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
            IsolateTooBigStacktraceException(isolateName, error));
        }
        catch(_) {
          context.sink.addError(IsolateUndefinedException(isolateName));
        }
      }
      finally {
        context._releaseLocks();
        sendPort.send(IsolateEvent.exit(task.capability));
      }
    }
  }
}
