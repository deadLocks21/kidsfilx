import 'package:flutter_test/flutter_test.dart';

import '../utils/index.dart';

void main() {
  setupTestEnvironment();

  testWidgets('can change password successfully', (tester) async {
    final app = await pumpApp(tester);
    await app
        .goToSettings()
        .clickOnChangePassword()
        .changePassword(
          currentCode: '1234',
          newCode: '5678',
          confirmCode: '5678',
        )
        .clickOnGoBack()
        .clickLockButton()
        .clickUnlockButton()
        .typeCode('5678')
        .clickUnlock()
        .expectPlayerIsUnlocked()
        .execute();
  });

  testWidgets('shows error for wrong current code', (tester) async {
    final app = await pumpApp(tester);
    await app
        .goToSettings()
        .clickOnChangePassword()
        .changePasswordAndFail(
          currentCode: '0000',
          newCode: '5678',
          confirmCode: '5678',
        )
        .expectErrorMessage('Code actuel incorrect !')
        .execute();
  });

  testWidgets('shows error for invalid new code format', (tester) async {
    final app = await pumpApp(tester);
    await app
        .goToSettings()
        .clickOnChangePassword()
        .changePasswordAndFail(
          currentCode: '1234',
          newCode: '123',
          confirmCode: '123',
        )
        .expectErrorMessage(
          'Le nouveau code doit contenir exactement 4 chiffres !',
        )
        .execute();
  });

  testWidgets('shows error for non-matching confirmation code', (tester) async {
    final app = await pumpApp(tester);
    await app
        .goToSettings()
        .clickOnChangePassword()
        .changePasswordAndFail(
          currentCode: '1234',
          newCode: '5678',
          confirmCode: '8765',
        )
        .expectErrorMessage('Les codes ne correspondent pas !')
        .execute();
  });

  testWidgets('can go back from change password page', (tester) async {
    final app = await pumpApp(tester);
    await app.goToSettings().clickOnChangePassword().clickBack().execute();
  });
}
