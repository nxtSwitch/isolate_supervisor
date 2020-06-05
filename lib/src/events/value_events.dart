part of 'events.dart';

abstract class IsolateValueEvent extends _IsolateEvent
{
  IsolateValueEvent(Capability capability) : super(capability);
}
