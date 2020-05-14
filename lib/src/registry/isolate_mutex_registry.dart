part of 'isolate_registry.dart';

class IsolateMutexRegistry
{
  final _isolates = <IsolateWrapper>{};
  final _locks = <String, Queue<IsolateLockEvent>>{};

  IsolateMutexRegistry._();
  factory IsolateMutexRegistry() => _instance;
  static final IsolateMutexRegistry _instance = IsolateMutexRegistry._();

  void register(IsolateWrapper isolate) 
  {
    if (isolate == null) return;

    final isAdded = this._isolates.add(isolate);
    if (!isAdded) return;

    isolate.broadcast
      ?.where((event) => event is IsolateLockEvent)
      ?.cast<IsolateLockEvent>()
      ?.listen(this._handleEvents, onError: (_) {}, cancelOnError: true);
  }

  void _handleEvents(IsolateLockEvent event)
  {
    if (event is IsolateLockAcquireEvent) this._add(event);
    if (event is IsolateLockReleaseEvent) this._remove(event);
  }

  void _add(IsolateLockAcquireEvent lock) 
  {
    this._locks[lock.name] ??= Queue<IsolateLockEvent>();
    this._locks[lock.name].add(lock);

    final needUpdate = this._locks[lock.name].first == lock;
    if (needUpdate) this._update(lock.name);
  }

  void _remove(IsolateLockReleaseEvent lock) 
  {
    if (!this._locks.containsKey(lock.name)) return;
    if (this._locks[lock.name].isEmpty) return;

    final needUpdate = this._locks[lock.name].first == lock;
    this._locks[lock.name].removeWhere((event) => event == lock);

    if (needUpdate) this._update(lock.name);
  }

  void _update(String lockName) 
  {
    if (!this._locks.containsKey(lockName)) return;

    if (this._locks[lockName].isEmpty) 
    {
      this._locks.remove(lockName);
      return;
    }

    for (final isolate in this._isolates) {
      isolate.sendEvent(this._locks[lockName].first);
    }
  }
}