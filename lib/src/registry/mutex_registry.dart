import './../helpers/hash.dart';
import './../events/events.dart';
import './../base/isolate_process.dart';
import './../base/isolate_registry.dart';

part 'mutex_registry_entry.dart';

class IsolateMutexRegistry extends IsolateRegistry
{
  final _locks = <String, List<IsolateMutexRegistryEntry>>{};

  @override
  void register(IsolateProcess process) 
  {
    if (process == null) return;

    process.output
      ?.where((event) => event is IsolateLockEvent)
      ?.cast<IsolateLockEvent>()
      ?.listen(
        (event) => this._handleEvents(process, event), 
        onDone: () => this.unregister(process),
        onError: (_) => this.unregister(process),
        cancelOnError: true
      );
  }

  @override
  void unregister(IsolateProcess process) 
  {
    for (final locks in this._locks.values) {
      if (locks.isEmpty) continue;

      final needUpdate = locks.first.process == process;
      locks.removeWhere((lock) => lock.process == process);

      if (needUpdate && locks.isNotEmpty) this._update(locks.first);
    }
  }

  void _handleEvents(IsolateProcess process, IsolateLockEvent event)
  {
    final lock = IsolateMutexRegistryEntry(process, event);

    if (event is IsolateLockAcquireEvent) this._add(lock);
    if (event is IsolateLockReleaseEvent) this._remove(lock);
  }

  void _add(IsolateMutexRegistryEntry lock) 
  {
    final name = lock.event.name;
    this._locks[name] ??= <IsolateMutexRegistryEntry>[];

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
  
  void _update(IsolateMutexRegistryEntry lock) => lock.process.send(lock.event);
}
