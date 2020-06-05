import 'dart:io';

import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

import './helpers/isolate_entry_points.dart';

void main() 
{
  final availableProcessors = Platform.numberOfProcessors - 1;

  IsolateSupervisor supervisor;

  tearDown(() async => await supervisor?.dispose());

  group('A group of common tests:', () 
  {
    test('Default constructor', () async
    {  
      supervisor = IsolateSupervisor();
      expect(IsolateSupervisor.numberOfIsolates, equals(availableProcessors));
    });

    test('Spawn constructor with an count equal to 0', ()
    {  
      expect(
        () => IsolateSupervisor.spawn(count: 0), 
        throwsA(isA<IsolateInvalidCountException>()));
    });

    test('Spawn constructor with an count less than 0', ()
    {  
      expect(
        () => IsolateSupervisor.spawn(count: -1), 
        throwsA(isA<IsolateInvalidCountException>()));
    });

    test('IsolateSupervisor.dispose()', () async
    {  
      supervisor = IsolateSupervisor();
      await supervisor.dispose();

      expect(IsolateSupervisor.numberOfIsolates, equals(0));
      expect(
        () => supervisor.execute(defaultEntryPoint), 
        throwsA(isA<IsolateNoIsolateAvailableException>()));
    });

    test('IsolateSupervisor.reset()', () async
    {  
      supervisor = IsolateSupervisor();
      await supervisor.reset();

      expect(IsolateSupervisor.numberOfIsolates, equals(availableProcessors));
    });
  });
}

