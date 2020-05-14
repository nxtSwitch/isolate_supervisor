import 'dart:collection';
import 'dart:io';
import 'dart:async';

import './../isolate_exceptions.dart';
import './../events/isolate_event.dart';
import './../isolate/isolate_wrapper.dart';

part 'isolate_mutex_registry.dart';

class IsolateRegistry
{
  static int numberOfIsolates = 0;
  final _isolates = <IsolateWrapper>[];

  bool get isEmpty => this._isolates.isEmpty;

  IsolateRegistry(int count, bool lazily)
  {
    final numberOfProcessors = Platform.numberOfProcessors - 1;
    final availableProcessors = numberOfProcessors - numberOfIsolates;

    count ??= availableProcessors;

    if (availableProcessors <= 0 || count > availableProcessors) {
      throw IsolateNoProcessorsAvailableException(availableProcessors);
    }

    for (int i = 0; i < count; ++i) {
      final id = numberOfIsolates + i;
      this._isolates.add(IsolateWrapper('Isolate[$id]', lazily ?? false));
    }

    IsolateRegistry.numberOfIsolates += count;
  }

  Future<IsolateWrapper> take() async
  {
    for (IsolateWrapper isolate in this._isolates) {
      if ((await isolate.initialize()) && isolate.isIdle) {
        IsolateMutexRegistry().register(isolate);
        return isolate..lock();
      }
    }

    return null;
  }

  Future<void> restart() async => 
    Future.wait(this._isolates.map((isolate) => isolate.cancel())); 

  Future<void> dispose() async
  {
    await Future.wait(
      this._isolates.map((isolate) => isolate.dispose()));

    IsolateRegistry.numberOfIsolates -= this._isolates.length;
    this._isolates.clear();
  }
}