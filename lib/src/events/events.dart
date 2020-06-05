import 'dart:isolate';

import './../helpers/hash.dart';
import './../base/isolate_event.dart';

part 'lock_events.dart';
part 'value_events.dart';
part 'result_events.dart';

abstract class _IsolateEvent extends IsolateEvent
{
  @override
  final Capability capability;
  
  _IsolateEvent(this.capability);
}

class IsolateHandshakeEvent extends _IsolateEvent
{
  SendPort sendPort;
  IsolateHandshakeEvent(this.sendPort) : super(null);
}

class IsolateProcessExitEvent extends _IsolateEvent 
{
  IsolateProcessExitEvent(Capability capability) : super(capability);
}
