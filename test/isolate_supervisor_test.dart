import 'isolate_supervisor_locks_test.dart' as locks_test;
import 'isolate_supervisor_execute_test.dart' as execute_test;
import 'isolate_supervisor_common_test.dart' as common_test;
import 'isolate_supervisor_stress_test_test.dart' as stress_test_test;

void main() 
{
  common_test.main();
  execute_test.main();

  stress_test_test.main();
  stress_test_test.main(1);

  locks_test.main();
}
