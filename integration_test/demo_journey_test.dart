import 'package:integration_test/integration_test.dart';

import '../test/support/demo_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerDemoJourney(useRealStorage: true);
}
