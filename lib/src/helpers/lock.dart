import 'dart:async';

class Lock 
{
  Completer _lock;

  Future<void> acquire() async
  {
    final lock = this._lock;
    this._lock = Completer.sync();
    
    if (lock != null) await lock.future;
  }

  void release() => this._lock?.complete();

  bool get locked => !(this._lock?.isCompleted ?? true);
}
