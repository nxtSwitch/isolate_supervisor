import 'dart:isolate';

part 'isolate_lock_event.dart';
part 'isolate_result_event.dart';

abstract class IsolateEvent
{
  final Capability capability;
  IsolateEvent(this.capability);

  factory IsolateEvent.exit(Capability capability) => 
    IsolateExitEvent(capability);

  factory IsolateEvent.handshake(SendPort sendPort) => 
    IsolateHandshakeEvent(sendPort);

  factory IsolateEvent.lock(Capability capability) => 
    IsolateExitEvent(capability);
}

class IsolateHandshakeEvent extends IsolateEvent
{
  SendPort sendPort;
  IsolateHandshakeEvent(this.sendPort) : super(null);
}

class IsolateExitEvent<R> extends IsolateEvent
{
  IsolateExitEvent(Capability capability) : super(capability);
}