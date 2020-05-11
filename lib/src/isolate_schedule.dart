part of 'isolate_supervisor.dart';

class IsolateSchedule
{
  final _entries = <Capability, IsolateScheduleEntry>{};  
  final _streamController = StreamController<IsolateResult>.broadcast();

  IsolateScheduleEntry<R, F> add<R, F>(
    _IsolateEntryPoint<F> function, List arguments, TaskPriority priority)
  {
    final task = IsolateTask<F>(function, arguments, priority);
    final taskEntry = IsolateScheduleEntry(task, this._streamController.stream);
    
    return this._entries[task.capability] = taskEntry;
  }

  void addListener(Stream<IsolateResult> results) => 
    results?.listen(this.update, onError: (_) {}, cancelOnError: true);

  void update(IsolateResult result) => this._streamController.add(result);

  IsolateTask unfulfilled()
  {
    final tasks = this._entries.values.map((entry) => entry._task).toList();

    tasks.sort((a, b) => b.priority.index - a.priority.index);
    return tasks.firstWhere((task) => task.isAwaiting, orElse: () => null);
  }

  void reset()
  {
    this._entries.removeWhere((_, item) => item._task.isCompleted);

    this._entries.values
      .where((item) => item._task.isProcessing)
      .forEach((item) => item._task.reset());
  } 

  IsolateScheduleEntry operator [](IsolateTask task) => 
    this._entries[task.capability];

  Future<void> close() async 
  {
    this._entries.clear();
    await this._streamController?.close();
  }
}

class IsolateScheduleEntry<R, F>
{
  final IsolateTask<F> _task;
  final Stream<IsolateResult<R>> stream;

  IsolateScheduleEntry(this._task, stream) :
    this.stream = stream.where((value) => value.capability == _task.capability);

  Future<IsolateResult<R>> single() async
  {
    final result = await this.stream.first;
    this._task.close();

    return result;
  }
  
  void close() => this._task.close();
}