import 'package:flutter_test/flutter_test.dart';

import '../utils/index.dart';

void main() {
  setupTestEnvironment();

  testWidgets('can lock and unlock with default code', (tester) async {
    final app = await pumpApp(tester);
    await app
        .expectPlayerIsUnlocked()
        .clickLockButton()
        .expectPlayerIsLocked()
        .clickUnlockButton()
        .typeCode('1234')
        .clickUnlock()
        .expectPlayerIsUnlocked()
        .execute();
  });

  testWidgets('can unlock with custom code', (tester) async {
    final app = await pumpApp(tester, unlockCode: '5678');
    await app
        .clickLockButton()
        .clickUnlockButton()
        .typeCode('5678')
        .clickUnlock()
        .expectPlayerIsUnlocked()
        .execute();
  });

  testWidgets('cannot unlock with wrong code', (tester) async {
    final app = await pumpApp(tester);
    await app
        .clickLockButton()
        .expectPlayerIsLocked()
        .clickUnlockButton()
        .typeCode('0000')
        .clickUnlock()
        .expectPlayerIsLocked()
        .execute();
  });

  testWidgets('can cancel unlock modal', (tester) async {
    final app = await pumpApp(tester);
    await app
        .clickLockButton()
        .expectPlayerIsLocked()
        .clickUnlockButton()
        .clickCancel()
        .expectPlayerIsLocked()
        .execute();
  });

  testWidgets('can change unlock code and use new code', (tester) async {
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
        .clickLockButton()
        .clickUnlockButton()
        .typeCode('1234')
        .clickUnlockAndFail()
        .clickCancel()
        .expectPlayerIsLocked()
        .execute();
  });
}
