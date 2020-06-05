import 'dart:math';

import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

import './helpers/isolate_entry_points.dart';

void main() 
{
  final count = 64;

  group('A group of locks tests:', () 
  {
    IsolateSupervisor supervisor;

    setUpAll(() => supervisor = IsolateSupervisor.spawn(count: 6));
    tearDownAll(() => supervisor?.dispose());

    test('Tasks with locks', () async
    {
      final computes = [
        for (int i = 0; i < count; ++i) 
          supervisor.compute(lockEntryPoint, [10, 0, ''])
      ];

      final stopwatch = Stopwatch()..start();
      await Future.wait(computes);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(count * 10));
    });

    test('Tasks with double lock', () async
    {
      final computes = [
        for (int i = 0; i < count; ++i) 
          supervisor.compute(doubleLockEntryPoint, [10])
      ];
      expect(Future.wait(computes), completion(List.filled(count, 10)));
    });

    test('Tasks without locks', () async
    {
      final computes = [
        for (int i = 0; i < count; ++i) supervisor.compute(defaultEntryPoint)
      ];

      final stopwatch = Stopwatch()..start();
      await Future.wait(computes);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(count * 10));
    });

    test('Tasks with not released locks', () async
    {
      final random = Random();
      final results = List.generate(count, (index) => random.nextInt(100));

      final computes = [
        for (int n in results) 
          supervisor.compute(lockNotReleasedEntryPoint, [n])
      ];

      expect(Future.wait(computes), completion(results));
    });

    test('Tasks with named locks', () async
    {
      final locks = ['a', 'b', 'c'];
      final names = List.generate(count, (i) => locks[i % 3]);

      names.shuffle();
      final results = names.map((c) => c.codeUnitAt(0));

      final computes = [
        for (final name in names) 
          supervisor.compute(lockEntryPoint, [100, name.codeUnitAt(0), name])
      ];

      final stopwatch = Stopwatch()..start();
      await Future.wait(computes);
      stopwatch.stop();

      expect(Future.wait(computes), completion(results));
      expect(
        stopwatch.elapsedMilliseconds, 
        inInclusiveRange(count * 100 / 4, count * 100 / 2)
      );
    });

    test('Reset tasks with locks', () async
    {
      final canceled = [
        for (int i = 0; i < count; ++i) 
          supervisor.compute(lockEntryPoint, [10000, i, 'lock'])
      ];

      await Future.delayed(Duration(milliseconds: 500));
      await supervisor.reset();

      final computes = [
        for (int i = 0; i < count; ++i) 
          supervisor.compute(lockEntryPoint, [0, i, 'lock'])
      ];

      expect(Future.wait(canceled), completion(List.filled(count, null)));
      expect(Future.wait(computes), completion(List.generate(count, (i) => i)));
    });
  });
}

