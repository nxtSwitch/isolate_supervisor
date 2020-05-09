import 'dart:math';
import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

void main() {
  group('A group of stress tests:', () {
    IsolateSupervisor supervisor;

    setUpAll(() => supervisor = IsolateSupervisor());
    tearDownAll(() async => await supervisor.dispose());

    test('Single long running task', () =>
      expect(supervisor.compute(longRunningTask, 3), completion(equals(3))));

    test('32 long running task', () 
    {
      final random = Random();
      final results = List.generate(32, (index) => random.nextInt(3));

      final futures = [
        for (int number in results) supervisor.compute(longRunningTask, number)
      ];

      expect(Future.wait(futures), completion(results));
    });

    test('Single long running stream task', () => expect(
      supervisor.launch(longRunningStreamTask, 3), 
      emitsInOrder([3, 9, emitsDone])
    ));

    test('100 long running stream task', () 
    {
      final random = Random();
      final results = List.generate(100, (index) {
        final number = random.nextInt(3);
        return [number, number * number, emitsDone];
      });

      for (List a in results) {
        expect(supervisor.launch(longRunningStreamTask, a[0]), emitsInOrder(a));
      }
    });
  });
}

Future<int> longRunningTask(IsolateContext context) async => 
  await Future.delayed(Duration(seconds: context.args), () => context.args);

Stream<int> longRunningStreamTask(IsolateContext context) async*
{
  final duration = Duration(milliseconds: context.args * 100);

  yield context.args;
  yield await Future.delayed(duration, () => context.args * context.args);
}
  