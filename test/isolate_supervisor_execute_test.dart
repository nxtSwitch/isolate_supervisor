import 'dart:async';

import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

import './helpers/isolate_entry_points.dart';

void main() 
{
  IsolateSupervisor supervisor;
  tearDown(() async => await supervisor?.dispose());

  group('A group of execute methods tests:', () 
  {
    test('Invalid entry point function', () async
    {  
      supervisor = IsolateSupervisor.spawn(lazily: true);

      expect(
        () => supervisor.execute(null), 
        throwsA(isA<IsolateInvalidEntryPointException>()));

      expect(
        () => supervisor.compute(null), 
        throwsA(isA<IsolateInvalidEntryPointException>()));

      expect(
        () => supervisor.launch(null), 
        throwsA(isA<IsolateInvalidEntryPointException>()));
    });

    test('Compute method', () async
    {  
      supervisor = IsolateSupervisor.spawn(lazily: true);

      expect(await supervisor.compute(defaultEntryPoint), 42);
      expect(await supervisor.compute(defaultEmptyEntryPoint), isNull);
      expect(await supervisor.compute(defaultAsyncEntryPoint), isNull);
    });

    test('Launch method', () async
    {
      final emits42 = emitsInOrder([42, emitsDone]);
      final emitsNull = emitsInOrder([null, emitsDone]);

      supervisor = IsolateSupervisor.spawn(lazily: true);
      
      expect(supervisor.launch(defaultEntryPoint), emits42);
      expect(supervisor.launch(defaultEmptyEntryPoint), emitsNull);
      expect(supervisor.launch(defaultAsyncEntryPoint), emitsNull);

      expect(supervisor.launch(defaultEmptyStreamEntryPoint), emitsDone);

      expect(supervisor.launch(defaultStreamEntryPoint), emits42);
    });

    test('Execute method', () async
    {  
      final emits42 = emitsInOrder([42, emitsDone]);
      final emitsNull = emitsInOrder([null, emitsDone]);

      IsolateTask task;
      supervisor = IsolateSupervisor.spawn(lazily: true);

      task = supervisor.execute(defaultEntryPoint);

      expect(task.isCompleted, false);
      expect(task.output, emits42);

      await task.done;
      expect(task.isCompleted, true);
      expect(task.output, emitsDone);

      task = supervisor.execute(defaultEmptyEntryPoint);
      expect(task.output, emitsNull);

      task = supervisor.execute(defaultAsyncEntryPoint);
      expect(task.output, emitsNull);

      task = supervisor.execute(defaultEmptyStreamEntryPoint);
      expect(task.output, emitsDone);

      task = supervisor.execute(defaultStreamEntryPoint);
      expect(task.output, emits42);
    });

    test('Cancel task', () async
    {
      supervisor = IsolateSupervisor.spawn(lazily: true);

      final task = supervisor.execute(longRunningEntryPoint, [10000]);
      await task.cancel();

      expect(task.isCanceled, true);
      expect(task.output, emitsDone);
    });

    test('Pause task method', () async
    {
      supervisor = IsolateSupervisor.spawn(lazily: true);

      final task = supervisor.execute(longRunningEntryPoint, [100]);

      task.pause();
      expect(task.isPaused, true);

      expect(
        task.done.timeout(Duration(seconds: 1)), 
        throwsA(isA<TimeoutException>()));
    });

    test('Resume task method', () async
    {
      supervisor = IsolateSupervisor.spawn(lazily: true);

      final emits42 = emitsInOrder([42, emitsDone]);
      final task = supervisor.execute(defaultEntryPoint);

      task.pause();
      expect(task.isPaused, true);

      task.resume();
      expect(task.isPaused, false);
      expect(task.output, emits42);
    });

    test('Pause after complete task', () async
    {
      supervisor = IsolateSupervisor.spawn(lazily: true);

      final task = supervisor.execute(longRunningEntryPoint, [100]);
      await task.done;

      task.pause();
      expect(task.isPaused, false);
    });

    test('Send to task', () async
    {
      int count = 0;
      supervisor = IsolateSupervisor.spawn(lazily: true);

      final task = supervisor.execute(bidirectionalEntryPoint, [count]);
      expect(task.send(0), false);

      await task.wait;
      await for(final n in task.output) {
        expect(count, n);
        task.send(++count);
      }
  
      await task.done;
      expect(task.send(0), false);
    });
  });
}
