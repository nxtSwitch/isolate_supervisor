import 'dart:async';
import 'dart:isolate';

import './../exceptions.dart';
import './../events/events.dart';

import './../base/isolate_event.dart';
import './../base/isolate_process.dart';
import './../base/isolate_executor.dart';
import './../base/isolate_runnable.dart';

import 'isolate_worker.dart';

part 'isolate_process.dart';

enum _IsolateStatus { none, initialized, idle, arrives }

class _IsolateNotIdleException implements IsolateException {}
class _IsolateEmptyTaskException implements IsolateException {}
class _IsolateInvalidHandshakeException implements IsolateException {}

class IsolateWrapper implements IsolateExecutor
{
  final String name;

  bool _spawnLazily;
  _IsolateStatus status;

  Isolate _isolate;
  SendPort _sendPort;
  ReceivePort _receivePort;
  Completer<void> _spawnCompleter;
  Stream<IsolateEvent> _broadcast;

  bool get isIdle => this.status == _IsolateStatus.idle;

  IsolateWrapper(this.name, this._spawnLazily)
  { 
    this._spawnLazily ??= false;

    this.status = _IsolateStatus.none;
    this._spawnCompleter = Completer<void>();
    
    if (!this._spawnLazily) this._spawn();
  }

  Future<void> get initialize async
  {
    this._spawn();
    await this._spawnCompleter.future;
  }

  @override
  IsolateProcess execute<R>(IsolateRunnable task)
  {
    if (!this.isIdle) throw _IsolateNotIdleException();
    if (task == null) throw _IsolateEmptyTaskException();
    
    try {
      this.status = _IsolateStatus.arrives;
      this._sendPort.send(task);

      final process = _IsolateProcess(this, task);
      process.onDone = () => this.status = _IsolateStatus.idle;

      return process;
    }
    catch(_) {
      throw IsolateUndefinedException(this.name);
    }
  }

  Future<void> cancel() async 
  {
    await this.dispose();
    this._spawnCompleter = Completer<void>();

    if (!this._spawnLazily) this._spawn();
  }

  Future<void> dispose() async 
  {
    if (this.status == _IsolateStatus.none) return;
    
    await this._spawnCompleter.future;

    this._isolate?.kill();
    this._receivePort?.close();

    this._isolate = null;
    this._sendPort = null;
    this._broadcast = null;
    this._receivePort = null;

    this.status = _IsolateStatus.none;
  }

  void _spawn() async
  {
    if (this._spawnCompleter.isCompleted) return;
    if (this.status != _IsolateStatus.none) return;
    
    this._receivePort = ReceivePort();
    this.status = _IsolateStatus.initialized;

    try {
      this._isolate = await Isolate.spawn(
        isolateWorker, 
        this._receivePort.sendPort, 
        paused: false,
        debugName: this.name,
        errorsAreFatal: false
      );
    } 
    on dynamic catch (_) {
      this._spawnCompleter.complete();
      return;
    }

    this._broadcast = this._receivePort
      .where((event) => event is IsolateEvent)
      .cast<IsolateEvent>()
      .asBroadcastStream();

    try {
      this._sendPort = await this._handshake(this._broadcast);
    }
    on dynamic catch (_) {
      this._spawnCompleter.complete();
      return;
    }

    this.status = _IsolateStatus.idle;
    this._spawnCompleter.complete();
  }

  Future<SendPort> _handshake(Stream<IsolateEvent> stream) async
  {
    final event = await stream.first;

    if (event is! IsolateHandshakeEvent) {
      throw _IsolateInvalidHandshakeException();
    }
  
    final sendPort = (event as IsolateHandshakeEvent).sendPort;
    sendPort.send(this.name);

    return sendPort;
  }
}
