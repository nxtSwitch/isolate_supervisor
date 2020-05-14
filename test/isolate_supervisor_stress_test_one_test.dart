import 'dart:math';
import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

Future<int> longRunningTask(IsolateContext context) async
{
  final timeout = context.arguments.nearest<int>();
  final duration = Duration(milliseconds: timeout.toInt());
  
  return await Future.delayed(duration, () => timeout);
}

Stream<num> longRunningStreamTask(IsolateContext context) async*
{
  final timeout = context.arguments.nearest<int>();
  final duration = Duration(milliseconds: timeout);

  if (timeout == -1) {
    context.sink.addError(Exception());

    await Future.delayed(Duration(milliseconds: 100));
    return;
  }

  context.sink.add(timeout);
  yield await Future.delayed(duration, () => pow(timeout, 2));
}

void main() 
{
  final count = 256;
  final random = Random();
  final results = List.generate(count, (index) => random.nextInt(100));
  final first = results[0];

  group('A group of stress tests (one isolate):', () 
  {
    IsolateSupervisor supervisor;

    setUpAll(() => supervisor = IsolateSupervisor.spawn(count: 1));
    tearDownAll(() => supervisor?.dispose());

    test('Single long running task', ()
    {
      expect(
        supervisor.compute(longRunningTask, [first]), 
        completion(equals(first))
      );
    });

    test('Single long running stream task', ()
    {
      expect(
        supervisor.launch(longRunningStreamTask, [first]), 
        emitsInOrder([first, pow(first, 2), emitsDone])
      );
    });

    test('$count long running task', ()
    {
      final computes = [
        for (int n in results) supervisor.compute(longRunningTask, [n])
      ];
      expect(Future.wait(computes), completion(results));
    });

    test('$count long running stream task', () 
    {
      for (int n in results) {
        final matcher = emitsInOrder([n, pow(n, 2), emitsDone]);
        expect(supervisor.launch(longRunningStreamTask, [n]), matcher);
      }
    });

    test('$count long running stream error task', () 
    {
      for (int _ in results) {
        final matcher = emitsError(isException);
        expect(supervisor.launch(longRunningStreamTask, [-1]), matcher);
      }
    });
  });
}