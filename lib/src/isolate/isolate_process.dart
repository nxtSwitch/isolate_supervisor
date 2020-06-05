part of 'isolate_wrapper.dart';

class _IsolateProcess extends IsolateProcess
{
  Function onDone;

  final IsolateWrapper _isolate;
  final IsolateRunnable _task;

  StreamSubscription<IsolateEvent> _subscription;
  final _controller = StreamController<IsolateEvent>.broadcast();

  _IsolateProcess(this._isolate, this._task)
  {
    this._subscription = this._isolate._broadcast
      ?.listen(_onData, onError: (_) {}, cancelOnError: true, onDone: _close);
  }

  @override
  Stream<IsolateEvent> get output => this._controller.stream;

  @override
  void pause() => this._isolate._isolate.pause(this._task.capability);

  @override
  void resume() => this._isolate._isolate.resume(this._task.capability);

  @override
  bool send(IsolateEvent event) 
  {  
    if (event == null) return false;
    if (this._isolate._sendPort == null) return false;
    if (this._isolate.status != _IsolateStatus.arrives) return false;

    this._isolate._sendPort.send(event);
    return true;
  }

  @override
  Future<void> kill() async
  {
    await this._isolate.cancel();
    this._close();
  }

  void _onData(IsolateEvent event) 
  {
    if (this._controller.isClosed) return;
    
    this._controller.add(event);
    if (event is IsolateProcessExitEvent) this._close();
  }

  void _close()
  {
    if (this._controller.isClosed) return;

    this._controller.close();
    this._subscription?.cancel();

    if (this.onDone != null) this.onDone();
  }
}
