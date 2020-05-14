part of 'isolate_schedule.dart';

enum ScheduleTaskStatus { awaiting, processing, completed }

class IsolateScheduleTask<R>
{
  final IsolateTask<R> object;
  final StreamController<IsolateResult<R>> _streamController;

  ScheduleTaskStatus _status = ScheduleTaskStatus.awaiting;

  IsolateScheduleTask(this.object) :
    this._streamController = StreamController<IsolateResult<R>>.broadcast();

  Future<IsolateResult<R>> single() async
  {
    try {
      final result = await this.stream.first;
      await this._streamController.done;
      return result;
    }
    catch(_) { return null; }
  }
  
  void listen(Stream<IsolateEvent> stream)
  {
    stream
      ?.where((event) => event is IsolateResult<R>)
      ?.where((event) => event.capability == object.capability)
      ?.listen(_update, onError: (_) {}, cancelOnError: true, onDone: close);
  }

  void reset() => 
    this._status = ScheduleTaskStatus.awaiting;

  void lock() => 
    this._status = ScheduleTaskStatus.processing;

  Future<void> close() async
  {
    this._status = ScheduleTaskStatus.completed;
    await this._streamController.close();
  }

  Future<void> get done async => await this._streamController.done;
  Stream<IsolateResult<R>> get stream => this._streamController.stream;

  TaskPriority get priority => this.object.priority;

  bool get isAwaiting => this._status == ScheduleTaskStatus.awaiting;
  bool get isCompleted => this._status == ScheduleTaskStatus.completed;
  bool get isProcessing => this._status == ScheduleTaskStatus.processing;

  void _update(IsolateEvent event) 
  {
    if (this._streamController.isClosed) return;
    if (event is IsolateResult<R>) this._streamController.add(event);
  }
}

