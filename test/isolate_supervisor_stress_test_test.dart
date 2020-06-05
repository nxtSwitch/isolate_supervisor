import 'dart:math';

import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

import './helpers/isolate_entry_points.dart';

void main([int numberOfIsolates]) 
{
  final count = 256;
  final random = Random();
  final results = List.generate(count, (index) => random.nextInt(100));

  group('A group of stress tests on ${numberOfIsolates ?? 'all'}:', () 
  {
    IsolateSupervisor supervisor;

    setUpAll(()
    {
      if (numberOfIsolates == null) {
        supervisor = IsolateSupervisor();
      }
      else {
        supervisor = IsolateSupervisor.spawn(count: numberOfIsolates);
      }   
    });

    tearDownAll(() 
    {
      supervisor?.dispose();
    });

    test('Single long running task', ()
    {
      expect(
        supervisor.compute(longRunningEntryPoint, [results[0]]), 
        completion(equals(results[0]))
      );
    });

    test('Single long running stream task', ()
    {
      expect(
        supervisor.launch(longRunningStreamEntryPoint, [results[0]]), 
        emitsInOrder([results[0], pow(results[0], 2), emitsDone])
      );
    });

    test('$count long running task', () async
    {
      final computes = [
        for (int n in results) supervisor.compute(longRunningEntryPoint, [n])
      ];
      expect(Future.wait(computes), completion(results));
    });

    test('$count long running stream task', () 
    {
      for (int n in results) {
        final matcher = emitsInOrder([n, pow(n, 2), emitsDone]);
        expect(supervisor.launch(longRunningStreamEntryPoint, [n]), matcher);
      }
    });

    test('$count long running stream error task', () 
    {
      for (int _ in results) {
        final matcher = emitsError(isException);
        expect(supervisor.launch(longRunningStreamEntryPoint, [-1]), matcher);
      }
    });

    test('Reset while performing tasks', () async
    {
      await supervisor?.dispose();
      supervisor = IsolateSupervisor();

      final computes = [
        for (int i = 0; i < count; ++i) supervisor.compute(defaultEntryPoint)
      ];

      await computes[0];
      await supervisor.reset();

      expect(Future.wait(computes), completion(containsAllInOrder([42, null])));
      await supervisor?.dispose();
    });

    test('Dispose while performing tasks', () async
    {
      await supervisor?.dispose();
      supervisor = IsolateSupervisor();
 
      final computes = [
        for (int i = 0; i < count; ++i) supervisor.compute(defaultEntryPoint)
      ];

      await computes[0];
      await supervisor.dispose();

      expect(Future.wait(computes), completion(containsAllInOrder([42, null])));
      await supervisor?.dispose();
    });
  });
}
