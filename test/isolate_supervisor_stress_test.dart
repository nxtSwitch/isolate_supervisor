import 'dart:math';
import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

void main() {
  group('A group of stress tests:', () 
  {
    Random random;
    IsolateSupervisor supervisor;

    setUpAll(() 
    {
      random = Random();
      supervisor = IsolateSupervisor();
    });

    tearDownAll(() async 
    {
      await supervisor.dispose();
    });

    test('Single long running task', ()
    {
      final n = random.nextInt(100);
      expect(supervisor.compute(longRunningTask, [n]), completion(equals(n)));
    });   

    test('512 long running task', () 
    {
      final results = List.generate(512, (index) => random.nextInt(100));
      final futures = [
        for (int n in results) supervisor.compute(longRunningTask, [n])
      ];

      expect(Future.wait(futures), completion(results));
    });

    test('Single long running stream task', () 
    {
      final n = random.nextInt(100);
      expect(
        supervisor.launch(longRunningStreamTask, [n]), 
        emitsInOrder([n, pow(n, 2), emitsDone])
      );
    });

    test('512 long running stream task', () 
    {
      final results = List.generate(512, (index) {
        int number = random.nextInt(100);
        return [number, number * number, emitsDone];
      });

      for (List a in results) {
        expect(
          supervisor.launch(longRunningStreamTask, [a[0]]), emitsInOrder(a));
      }
    });
  });
}

Future<num> longRunningTask(IsolateContext context) async
{
  final timeout = context.arguments.nearest<int>();
  final duration = Duration(milliseconds: timeout.toInt());

  return await Future.delayed(duration, () => timeout);
}

Stream<num> longRunningStreamTask(IsolateContext context) async*
{
  final timeout = context.arguments.nearest<int>();
  final duration = Duration(milliseconds: timeout);

  context.sink.add(timeout);
  yield await Future.delayed(duration, () => pow(timeout, 2));
}