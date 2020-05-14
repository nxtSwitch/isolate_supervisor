part of 'isolate_event.dart';

abstract class IsolateResult<R> extends IsolateEvent
{
  IsolateResult(capability) : super(capability);

  factory IsolateResult.value(Capability capability, R value) => 
    IsolateValueResult<R>(capability, value);

  factory IsolateResult.error(Capability capability, Object error) =>
    IsolateErrorResult<R>(capability, error);
}

class IsolateValueResult<R> extends IsolateResult<R> 
{
  final R value;
  IsolateValueResult(Capability capability, this.value) : super(capability);
}

class IsolateErrorResult<R> extends IsolateResult<R> 
{
  final Object error;
  IsolateErrorResult(Capability capability, this.error) : super(capability);
}