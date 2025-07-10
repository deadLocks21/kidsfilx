import 'package:flutter_test/flutter_test.dart';
import 'package:kidflix/shared/dependancy_injection.dart';

void setupTestEnvironment() {
  setUpAll(() {
    DependancyInjection.setEnvironment(Environment.test);
  });

  tearDownAll(() {});
}
