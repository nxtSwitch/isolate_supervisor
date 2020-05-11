part of 'isolate_supervisor.dart';

class IsolateSchedule
{
  final _entries = <Capability, IsolateScheduleEntry>{};  
  final _streamController = StreamController<IsolateResult>.broadcast();

  IsolateScheduleEntry<R, F> add<R, F>(
    IsolateEntryPoint<F> function, List arguments)
  {
    final task = IsolateTask<F>(function, arguments);
    final taskEntry = IsolateScheduleEntry(task, this._streamController.stream);
    
    return this._entries[task.capability] = taskEntry;
  }

  void addListener(Stream<IsolateResult> results) => 
    results?.listen((value) => this.update(value));

  void update(IsolateResult result) => this._streamController.add(result);

  IsolateScheduleEntry attach(IsolateWrapper worker)
  {
    if (worker == null) return null; 

    final task = this._entries.values
      .firstWhere((entry) => entry.task.isAwaiting, orElse: () => null);

    task?.attach(worker);
    return task;
  }

  void reset() => this._entries.values
    .where((item) => item.task.status == TaskStatus.processing)
    .forEach((item) => item.task.status = TaskStatus.awaiting);

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
  IsolateWrapper _worker;

  final IsolateTask<F> task;
  final Stream<IsolateResult<R>> stream;

  IsolateScheduleEntry(this.task, stream) :
    this.stream = stream.where((value) => value.capability == task.capability);

  void close() => this.task.close();

  void attach(IsolateWrapper worker)
  {
    if (worker == null) return; 

    this.task.lock();
    this._worker = worker;
  }
  
  Stream<IsolateResult> execute() => this._worker.execute(this.task);
}