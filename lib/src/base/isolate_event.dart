/// An object that can be passed into the isolate.
abstract class IsolateEvent
{
  /// Capability granting the ability to identify the event.
  dynamic get capability;
}
