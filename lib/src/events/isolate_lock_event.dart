part of 'isolate_event.dart';

abstract class IsolateLockEvent extends IsolateEvent
{
  final String name;

  IsolateLockEvent(Capability capability, this.name) : super(capability);

  factory IsolateLockEvent.acquire(Capability capability, String name) = 
    IsolateLockAcquireEvent;

  factory IsolateLockEvent.release(Capability capability, String name) = 
    IsolateLockReleaseEvent;
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