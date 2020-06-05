part of 'events.dart';

abstract class IsolateLockEvent extends _IsolateEvent
{
  final String name;

  IsolateLockEvent(Capability capability, this.name) : super(capability);

  factory IsolateLockEvent.acquire(Capability capability, String name) = 
    IsolateLockAcquireEvent;

  factory IsolateLockEvent.release(Capability capability, String name) = 
    IsolateLockReleaseEvent;

  @override
  int get hashCode => hash([this.name, this.capability]);

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is IsolateLockEvent && 
    this.capability == other.capability && this.name == other.name;
}

class IsolateLockAcquireEvent extends IsolateLockEvent
{
  IsolateLockAcquireEvent(Capability capability, String name) : 
    super(capability, name);
}

class IsolateLockReleaseEvent extends IsolateLockEvent
{
  IsolateLockReleaseEvent(Capability capability, String name) : 
    super(capability, name);
}
