# Isolate Supervisor

This library constructs higher-level isolate interfaces on top of [dart:isolate](https://api.dart.dev/stable/2.8.2/dart-isolate/dart-isolate-library.html) library.

## Usage

To use this library, just create an instance of **IsolateSupervisor** like:

```dart
  final supervisor = IsolateSupervisor();

  //or you can also define how many isolates to spawn:
  final supervisor = IsolateSupervisor.spawn(count: 2, lazily: true));
```

As a task, we need to define our entry point function:

> Any top-level function or static method is a valid entry point for an isolate.

```dart
  Future<int> entryPoint(IsolateContext context) async
  {
    int timeout = context.arguments.nearest();
    final duration = Duration(milliseconds: timeout);

    return await Future.delayed(duration, () => timeout);
  }

  // returns multiple values
  Stream<num> streamEntryPoint(IsolateContext context) async*
  {
    int timeout = context.arguments.nearest();
    final duration = Duration(milliseconds: timeout);

    yield timeout;
    yield await Future.delayed(duration, () => timeout * timeout);
  }
```

And execute your tasks:

```dart
  final result = await supervisor.compute(entryPoint, [42]);
  print(result);

  final results = supervisor.launch(streamEntryPoint, [42]);
  await for (final result in results) {
    print(result);
  }
```

## IsolateContext Interface

- **sink** is the isolate output sink.

- **input** is the isolate input stream.

- **lock** is a method that returns the primitive lock object.

- **arguments** is a arguments collection passed into the isolate.

- **isolateName** is the name used to identify isolate in debuggers or loggers.

## Locks

At any time, a lock can be held by a single isolate, or by no isolate at all. If a isolate attempts to hold a lock that’s already held by some other isolate, execution of the first isolate is halted until the lock is released.

```dart
  Future<String> lockEntryPoint(IsolateContext context) async
  {
    final name = context.arguments[0];
    final lock = context.lock('sample');

    await lock.acquire(); // will block if lock is already held
      await Future.delayed(Duration(milliseconds: 100));
    lock.release();

    return name;
  }
```

## Communication example

```dart
  void main() async
  {
    final supervisor = IsolateSupervisor();

    final task = await supervisor.execute(communicationEntryPoint);
    await task.wait;

    task.send('Hello');
    print(await task.output.first);

    await task.done;
    await supervisor.dispose();
  }

  Stream<String> communicationEntryPoint(IsolateContext context) async*
  {
    String hello = await context.input.first;
    yield '${context.isolateName}: $hello World!';
  }
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/nxtSwitch/isolate_supervisor/issues).
