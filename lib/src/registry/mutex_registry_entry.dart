part of 'mutex_registry.dart';

class IsolateMutexRegistryEntry {
  final IsolateProcess process;
  final IsolateLockEvent event;

  IsolateMutexRegistryEntry(this.process, this.event);

  @override
  int get hashCode => hash([this.event, this.process]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IsolateMutexRegistryEntry &&
          this.event == other.event &&
          this.process == other.process;
}
