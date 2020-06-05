import 'package:isolate_supervisor/isolate_supervisor.dart';

void main() async
{
  final supervisor = IsolateSupervisor();

  final task = await supervisor.execute(communicationEntryPoint);
  await task.wait;

  task.send('Hello');
  print(await task.output.first);

  final sum = await task.output.reduce((prev, number) => prev + number);
  print('Sum: $sum');

  await task.done;
  await supervisor.dispose();
}

Stream<String> communicationEntryPoint(IsolateContext context) async*
{
  String hello = await context.input.first;
  yield '${context.isolateName}: $hello World!';

  List.generate(42, (index) => context.sink.add(index));
}
