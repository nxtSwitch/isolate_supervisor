import 'dart:math';

import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

Future<void> taskWithoutLock(IsolateContext context) async
{
  await Future.delayed(Duration(milliseconds: 100));
}

Future<void> taskWithLock(IsolateContext context) async
{
  final lock = await context.lock();
  await Future.delayed(Duration(milliseconds: 100));
  lock.release();
}

Future<int> taskWithNotReleasedLock(IsolateContext context) async
{
  await context.lock();
  return context.arguments.nearest();
}

Future<String> taskWithNamedLock(IsolateContext context) async
{
  String name = context.arguments[0];

  await context.lock(name);
  await Future.delayed(Duration(milliseconds: 100));

  return context.arguments.nearest();
}

void main() 
{
  final count = 64;

  group('A group of locks tests:', () 
  {
    IsolateSupervisor supervisor;

    setUpAll(() => supervisor = IsolateSupervisor.spawn(count: 4));
    tearDownAll(() => supervisor?.dispose());

    test('Tasks with locks', () async
    {
      final computes = [
        for (int i = 0; i < count; ++i) supervisor.compute(taskWithLock)
      ];

      final stopwatch = Stopwatch()..start();
      await Future.wait(computes);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(count * 100));
    });

    test('Tasks without locks', () async
    {
      final computes = [
        for (int i = 0; i < count; ++i) supervisor.compute(taskWithoutLock)
      ];

      final stopwatch = Stopwatch()..start();
      await Future.wait(computes);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(count * 100));
    });

    test('Tasks with not released locks', () async
    {
      final random = Random();
      final results = List.generate(count, (index) => random.nextInt(100));

      final computes = [
        for (int n in results) supervisor.compute(taskWithNotReleasedLock, [n])
      ];

      expect(Future.wait(computes), completion(results));
    });

    test('Tasks with named locks', () async
    {
      final odd = List.filled(count ~/ 2, 'odd');
      final even = List.filled(count ~/ 2, 'even');
      final names = [...odd, ...even]..shuffle();

      final computes = [
        for (final name in names) supervisor.compute(taskWithNamedLock, [name])
      ];

      final stopwatch = Stopwatch()..start();
      await Future.wait(computes);
      stopwatch.stop();

      final elapsedMilliseconds = stopwatch.elapsedMilliseconds;

      expect(Future.wait(computes), completion(names));
      expect(elapsedMilliseconds, lessThanOrEqualTo(count * 100));
    });
  });
}
