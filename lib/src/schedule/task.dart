import 'dart:async';
import 'dart:isolate';

import './../events/events.dart';

import './../base/isolate_task.dart';
import './../base/isolate_event.dart';
import './../base/isolate_process.dart';
import './../base/isolate_context.dart';
import './../base/isolate_runnable.dart';
import './../base/isolate_entry_point.dart';

part 'task_action.dart';

class IsolateScheduleTask<R> extends IsolateTask<R> 
{
  Function onDone;
  Function onResume;
  IsolateProcess _process;
  IsolateTaskStatus _status;
  IsolateTaskStatus _prevStatus;
  StreamSubscription<IsolateEvent> _subscription;

  final Completer<void> _wait;
  final StreamController<R> _controller;
  final IsolateScheduleTaskAction<R> action;

  IsolateScheduleTask(IsolateEntryPoint<R> action, List arguments) :
    this._wait = Completer<void>.sync(),
    this._status = IsolateTaskStatus.awaiting,
    this._controller = StreamController<R>.broadcast(),
    this.action = IsolateScheduleTaskAction<R>(action, arguments);

  @override
  bool send(dynamic value)
  {
    if (!this.isProcessing) return false;
    if (this._process == null) return false;

    final event = IsolateResult.value(this.action.capability, value);
    return this._process.send(event);
  }

  @override
  void pause()
  {
    if (!this.isAwaiting && !this.isProcessing) return;

    this._prevStatus = this._status;
    this._status = IsolateTaskStatus.paused;

    this._process?.pause();
  }

  @override
  void resume()
  {
    if (!this.isPaused) return;

    this._status = this._prevStatus;
    this._process?.resume();

    if (this.onResume != null) this.onResume();
  }

  @override
  Future<void> cancel() async
  {
    if (this.isCompleted || this.isCanceled) return;

    await this._process?.kill();
    this._close();
  }

  void attach(IsolateProcess process) 
  {
    if (process == null) return;
    
    this._process = process;
    this._status = IsolateTaskStatus.processing;

    this._subscription = this._process.output
      .listen(_onData, onError: (_) {}, cancelOnError: true, onDone: _close);

    this._wait.complete();
  }

  void _onData(IsolateEvent event) 
  {
    if (this._controller.isClosed) return;
    
    if (event is IsolateValueResult) this._controller.add(event.value);
    if (event is IsolateErrorResult) {
      final error = event.error;
      if (error is! Error) this._controller.addError(error);
      if (error is Error) this._controller.addError(error, error.stackTrace);
    };

    if (event is IsolateProcessExitEvent) {
      this._status = IsolateTaskStatus.completed;
    }
  }

  void _close() 
  {
    if (this._controller.isClosed) return;

    this._controller.close();
    this._subscription?.cancel();

    if (this.onDone != null) this.onDone();
    if (!this.isCompleted) this._status = IsolateTaskStatus.canceled;
  }

  @override
  Future<void> get wait => this._wait.future;

  @override
  Future<void> get done => this._controller.done; 

  @override
  Stream<R> get output => this._controller.stream;

  @override
  IsolateTaskStatus get status => this._status;

  @override
  bool get isPaused => this._status == IsolateTaskStatus.paused;

  bool get isAwaiting => this._status == IsolateTaskStatus.awaiting;

  @override
  bool get isCanceled => this._status == IsolateTaskStatus.canceled;

  @override
  bool get isCompleted => this._status == IsolateTaskStatus.completed;

  bool get isProcessing => this._status == IsolateTaskStatus.processing;
}
