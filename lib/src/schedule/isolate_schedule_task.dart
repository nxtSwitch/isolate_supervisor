part of 'isolate_schedule.dart';

enum _ScheduleTaskStatus { awaiting, processing, completed, canceled }

class IsolateScheduleTask<R>
{
  final IsolateTask<R> object;
  final _streamController = StreamController<IsolateResult<R>>.broadcast();

  _ScheduleTaskStatus _status;
  StreamSubscription<IsolateEvent> _subscription;

  IsolateScheduleTask(this.object)
  {
    this._status = _ScheduleTaskStatus.awaiting;

    this._streamController.onCancel = () =>
      this._status = _ScheduleTaskStatus.completed;
  }

  void listen(Stream<IsolateEvent> stream)
  {
    if (stream == null) return;
    if (this._subscription != null) return;

    this._status = _ScheduleTaskStatus.processing;

    this._subscription = stream
      ?.where((event) => event.capability == object.capability)
      ?.listen(_update, onError: (_) {}, cancelOnError: true, onDone: close);
  }

  void _update(IsolateEvent event) 
  {
    if (this._streamController.isClosed) return;
    if (event is IsolateResult<R>) this._streamController.add(event);
  }

  Future<void> cancel() async
  {
    if (this.isCompleted) return;

    await this.close();
    this._status = _ScheduleTaskStatus.canceled;
  }
   
  Future<IsolateResult<R>> single() async
  {
    try {
      final result = await this._streamController.stream.first;
      await this._streamController.done;
      return result;
    }
    catch(e) { return null; }
  }

  void close()
  {
    if (this._streamController.isClosed) return;
    
    this._subscription?.cancel();
    this._streamController?.close();
  }

  TaskPriority get priority => this.object.priority;

  Future<void> get done async => await this._streamController.done;
  Stream<IsolateResult<R>> get stream => this._streamController.stream;

  bool get isAwaiting => this._status == _ScheduleTaskStatus.awaiting;
  bool get isCompleted => this._status == _ScheduleTaskStatus.completed;
}

