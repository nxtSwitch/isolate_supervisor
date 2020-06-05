import 'dart:math';
import 'package:isolate_supervisor/isolate_supervisor.dart';

int defaultEntryPoint(IsolateContext context) => 42;

void defaultEmptyEntryPoint(IsolateContext context) {}

Future<void> defaultAsyncEntryPoint(IsolateContext context) async
{
  await Future.delayed(Duration(milliseconds: 10));
}

Stream defaultEmptyStreamEntryPoint(IsolateContext context) async* {}

Stream defaultStreamEntryPoint(IsolateContext context) async*
{
  yield 42;
}

Future<int> lockEntryPoint(IsolateContext context) async
{
  final name = context.arguments.nearest<String>();
  final numbers = context.arguments.whereType<int>();
  final lock = context.lock(name);
  
  await lock.acquire();
  await Future.delayed(Duration(milliseconds: numbers[0]));
  lock.release();

  return numbers[1];
}

Future<int> doubleLockEntryPoint(IsolateContext context) async
{
  final number = context.arguments.nearest<int>();
  final lock = context.lock('lock');

  await lock.acquire();
  await lock.acquire();

  await Future.delayed(Duration(milliseconds: 10));
  return number;
}

Future<int> lockNotReleasedEntryPoint(IsolateContext context) async
{
  final lock = context.lock();

  await lock.acquire();
  return context.arguments.nearest();
}

Future<int> longRunningEntryPoint(IsolateContext context) async
{
  final timeout = context.arguments.nearest<int>();
  final duration = Duration(milliseconds: timeout);
  
  return await Future.delayed(duration, () => timeout);
}

Stream<num> longRunningStreamEntryPoint(IsolateContext context) async*
{
  final timeout = context.arguments.nearest<int>();
  final duration = Duration(milliseconds: timeout);

  if (timeout == -1) {
    context.sink.addError(Exception());

    await Future.delayed(Duration(milliseconds: 10));
    return;
  }

  context.sink.add(timeout);
  yield await Future.delayed(duration, () => pow(timeout, 2));
}

Stream<num> bidirectionalEntryPoint(IsolateContext context) async*
{
  yield context.arguments.nearest();

  await for(final n in context.input) {
    yield n;
    if (n == 42) return;
  }
}
