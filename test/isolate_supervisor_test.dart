import 'isolate_supervisor_locks_test.dart' as locks_test;
import 'isolate_supervisor_stress_test_test.dart' as stress_test_test;
import 'isolate_supervisor_stress_test_one_test.dart' as stress_test_one_test;

void main() 
{
  locks_test.main();
  stress_test_test.main();
  stress_test_one_test.main();
}