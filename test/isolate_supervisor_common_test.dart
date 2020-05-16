import 'dart:io';

import 'package:test/test.dart';
import 'package:isolate_supervisor/isolate_supervisor.dart';

import './helpers/isolate_entry_points.dart';

void main() 
{
  final count = 5120;
  final availableProcessors = Platform.numberOfProcessors - 1;

  group('A group of common tests:', () 
  {
    test('Default constructor', () async
    {  
      final supervisor = IsolateSupervisor();
      expect(IsolateSupervisor.numberOfIsolates(), equals(availableProcessors));
      await supervisor.dispose();
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
      final supervisor = IsolateSupervisor();
      await supervisor.dispose();

      expect(IsolateSupervisor.numberOfIsolates(), equals(0));
      expect(
        supervisor.compute(defaultEntryPoint), 
        throwsA(isA<IsolateNoIsolateAvailableException>()));
      expect(
        supervisor.launch(defaultEntryPoint), 
        emitsError(isA<IsolateNoIsolateAvailableException>()));
    });

    test('IsolateSupervisor.dispose() while performing tasks', () async
    {  
      final supervisor = IsolateSupervisor();
 
      final computes = [
        for (int i = 0; i < count; ++i) 
          supervisor.compute(longRunningEntryPoint, [1])
      ];

      await Future.delayed(Duration(milliseconds: 1000));
      await supervisor.dispose();

      expect(Future.wait(computes), completion(containsAllInOrder([1, null])));
    });

    test('IsolateSupervisor.reset()', () async
    {  
      final supervisor = IsolateSupervisor();
      await supervisor.reset();

      expect(IsolateSupervisor.numberOfIsolates(), equals(availableProcessors));
      await supervisor.dispose();
    });

    test('IsolateSupervisor.reset() while performing tasks', () async
    {
      final supervisor = IsolateSupervisor();
 
      final computes = [
        for (int i = 0; i < count; ++i) 
          supervisor.compute(longRunningEntryPoint, [1])
      ];

      await Future.delayed(Duration(milliseconds: 1000));
      await supervisor.reset();

      expect(Future.wait(computes), completion(containsAllInOrder([1, null])));
      await supervisor.dispose();
    });

    test('Invalid entry point function', () async
    {  
      final supervisor = IsolateSupervisor.spawn(lazily: true);

      expect(
        supervisor.compute(null), 
        throwsA(isA<IsolateInvalidEntryPointException>()));

      expect(
        supervisor.launch(null), 
        emitsError(isA<IsolateInvalidEntryPointException>()));

      await supervisor.dispose();
    });
  });
}

