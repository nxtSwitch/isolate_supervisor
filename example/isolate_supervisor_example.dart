import 'package:isolate_supervisor/isolate_supervisor.dart';

void main() async
{
  final supervisor = IsolateSupervisor();

  final result = await supervisor.compute(fibEntryPoint, [42]);
  print(result);

  final results = supervisor.launch(streamEntryPoint, [42]);
  await for (final result in results) {
    print(result);
  }

  await supervisor.dispose();
}

int fibEntryPoint(IsolateContext context)
{
  int n = context.arguments.nearest();

  int fib (int n)
  {
    if (n < 2) return n;
    return fib(n - 2) + fib(n - 1);
  };

  return fib(n);
}

Stream<num> streamEntryPoint(IsolateContext context) async*
{
  int timeout = context.arguments.nearest();
  final duration = Duration(milliseconds: timeout);

  yield timeout;
  yield await Future.delayed(duration, () => timeout * timeout);
}