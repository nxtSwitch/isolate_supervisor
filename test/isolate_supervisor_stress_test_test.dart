import 'dart:math';
import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

import './helpers/isolate_entry_points.dart';

void main() 
{
  final count = 256;
  final random = Random();
  final results = List.generate(count, (index) => random.nextInt(100));
  final first = results[0];

  group('A group of stress tests:', () 
  {
    IsolateSupervisor supervisor;

    setUpAll(() => supervisor = IsolateSupervisor());
    tearDownAll(() => supervisor?.dispose());

    test('Single long running task', ()
    {
      expect(
        supervisor.compute(longRunningEntryPoint, [first]), 
        completion(equals(first))
      );
    });

    test('Single long running stream task', ()
    {
      expect(
        supervisor.launch(longRunningStreamEntryPoint, [first]), 
        emitsInOrder([first, pow(first, 2), emitsDone])
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
  });
}
