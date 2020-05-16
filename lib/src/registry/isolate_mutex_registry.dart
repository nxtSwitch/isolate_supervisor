part of 'isolate_registry.dart';

class IsolateMutexRegistry
{
  final _locks = <String, Queue<IsolateMutexRegistryEntry>>{};

  void register(IsolateWrapper isolate) 
  {
    if (isolate == null) return;

    isolate.listen((broadcast) {
      broadcast
        ?.where((event) => event is IsolateLockEvent)
        ?.cast<IsolateLockEvent>()
        ?.listen(
          (event) => this._handleEvents(event, isolate), 
          onDone: () => this._removeLocks(isolate),
          onError: (_) => this._removeLocks(isolate),
          cancelOnError: true
        );
    });
  }

  void _removeLocks(IsolateWrapper isolate)
  {
    for (final locks in this._locks.values) {
      if (locks.isEmpty) continue;

      final needUpdate = locks.first.isolate == isolate;
      locks.removeWhere((lock) => lock.isolate == isolate);

      if (needUpdate && locks.isNotEmpty) this._update(locks.first);
    }
  }

  void _handleEvents(IsolateLockEvent event, IsolateWrapper isolate)
  {
    final lock = IsolateMutexRegistryEntry(isolate, event);

    if (event is IsolateLockAcquireEvent) this._add(lock);
    if (event is IsolateLockReleaseEvent) this._remove(lock);
  }

  void _add(IsolateMutexRegistryEntry lock) 
  {
    final name = lock.event.name;
    this._locks[name] ??= Queue<IsolateMutexRegistryEntry>();

    this._locks[name].add(lock);
    if (this._locks[name].length == 1) this._update(lock);
  }

  void _remove(IsolateMutexRegistryEntry lock) 
  {
    final name = lock.event.name;
    if (this._locks[name]?.isEmpty ?? false) return;

    final needUpdate = this._locks[name].first == lock;
    this._locks[name].removeWhere((entry) => entry == lock);

    if (needUpdate && this._locks[name].isNotEmpty) {
      this._update(this._locks[name].first);
    };
  }
  
  void _update(IsolateMutexRegistryEntry lock)
  {
    lock.isolate.sendEvent(lock.event);
  }
}