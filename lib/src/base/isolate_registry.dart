import 'isolate_process.dart';

/// This class provides an interface for registry.
abstract class IsolateRegistry
{
  /// Registers process.
  void register(IsolateProcess process);

  /// Removes process from the registry.
  void unregister(IsolateProcess process);
}
