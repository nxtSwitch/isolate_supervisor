import 'dart:collection';
import 'dart:io';
import 'dart:async';

import './../isolate_exceptions.dart';
import './../events/isolate_event.dart';
import './../isolate/isolate_wrapper.dart';

part 'isolate_mutex_registry.dart';
part 'isolate_mutex_registry_entry.dart';

class IsolateRegistry
{
  static int numberOfIsolates = 0;

  final _isolates = <IsolateWrapper>[];
  final _mutex = IsolateMutexRegistry();

  bool get isInitialized => this._isolates.isNotEmpty;

  IsolateRegistry(int count, bool lazily)
  {
    final numberOfProcessors = Platform.numberOfProcessors - 1;
    final availableProcessors = numberOfProcessors - numberOfIsolates;

    count ??= availableProcessors;

    if (availableProcessors <= 0 || count > availableProcessors) {
      throw IsolateNoProcessorsAvailableException(availableProcessors);
    }

    if (count <= 0) throw IsolateInvalidCountException(count);

    try {
      for (int i = 0; i < count; ++i) {
        final id = numberOfIsolates + i;
        final isolate = IsolateWrapper('Isolate[$id]', lazily ?? false);

        this._isolates.add(isolate);
        this._mutex.register(isolate);
      }
    }
    finally {
      IsolateRegistry.numberOfIsolates += this._isolates.length;
    }
  }

  Future<IsolateWrapper> take() async
  {
    for (IsolateWrapper isolate in this._isolates) {
      final isInitialized = await isolate.initialize();
      if (isInitialized && isolate.isIdle) return isolate..lock();
    }
    return null;
  }

  Future<void> restart() async
  {
    await Future.wait(this._isolates.map((isolate) => isolate.cancel())); 
  }
    
  Future<void> dispose() async
  {
    await Future.wait(this._isolates.map((isolate) => isolate.dispose()));
    IsolateRegistry.numberOfIsolates -= this._isolates.length;

    this._isolates.clear();
  }
}