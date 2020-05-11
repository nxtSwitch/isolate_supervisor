part of 'isolate_supervisor.dart';

enum _IsolateStatus { none, idle, arrives, attached, paused }

class IsolateWrapper
{
  final String name;

  SendPort _sendPort;
  ReceivePort _receivePort;

  Isolate _isolate;
  Stream _broadcast;
  _IsolateStatus status;
  
  Completer<bool> _initCompleter;

  IsolateWrapper([this.name])
  { 
    this.status = _IsolateStatus.none;
    this._spawn();
  }

  bool get isIdle => this.status == _IsolateStatus.idle;
  bool get isAttached => this.status == _IsolateStatus.attached;

  void lock() => this.status = _IsolateStatus.attached;
  Future<bool> initialize() => this._initCompleter.future;

  Stream<IsolateResult> execute(IsolateTask task) async*
  {
    if (!this.isAttached) throw IsolateNotIdleException();
    
    if (task == null) {
       this.status = _IsolateStatus.idle;
       throw IsolateEmptyTaskException();
    }
    
    if (this._sendPort == null || this._broadcast == null) {
      this.status = _IsolateStatus.none;
      throw IsolateUndefinedException();
    }

    task.lock();
    this.status = _IsolateStatus.arrives;

    this._sendPort.send(task);

    await for(final result in this._broadcast.cast<IsolateResult>()) {
      yield result;
      if (result is IsolateExitResult) break;
    }

    this.status = _IsolateStatus.idle;
  }

  Future<void> _spawn() async
  {
    this._receivePort = ReceivePort();
    this._initCompleter = Completer<bool>();

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

    this._broadcast = this._receivePort.asBroadcastStream();

    this._sendPort = await this._broadcast.first;
    this._sendPort.send(this.name);

    this.status = _IsolateStatus.idle;
    this._initCompleter.complete(true);
  }

  Future<void> cancel() async 
  {
    await this.dispose();
    await this._spawn();
  }

  Future<void> dispose() async 
  {
    this._isolate?.kill();
    this._receivePort?.close();

    this._sendPort = null;
    this._broadcast = null;
    this.status = _IsolateStatus.none;

    this._initCompleter = Completer<bool>();
    this._initCompleter.complete(false);
  }

  static void _entryPoint(SendPort outPort) async 
  {
    final inPort = ReceivePort();
    outPort.send(inPort.sendPort);
    
    final broadcast = inPort.asBroadcastStream();
    final isolateName = await broadcast.first;

    await for (IsolateTask task in broadcast) {
      final context = IsolateContext._(task, outPort, isolateName);
      
      try {
        final result = task.function(context);
        
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
          context.sink.addError(IsolateUndefinedException());
        }
      }
      finally {
        outPort.send(IsolateResult.exit(task));
      }
    }

    inPort.close();
  }
}
