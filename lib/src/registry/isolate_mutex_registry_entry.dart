part of 'isolate_registry.dart';

class IsolateMutexRegistryEntry 
{
  final IsolateWrapper isolate;
  final IsolateLockEvent event;

  IsolateMutexRegistryEntry(this.isolate, this.event);

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is IsolateMutexRegistryEntry && this.event == other.event;
}