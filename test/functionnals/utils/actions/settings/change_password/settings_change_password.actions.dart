import 'package:flutter_test/flutter_test.dart';

import '../../../index.dart';
import 'settings_change_password.commands.dart';
import 'settings_change_password.finder.dart';

class SettingsChangePasswordActions extends ActionsInterface {
  SettingsChangePasswordActions(super.navigation, this._tester)
    : _finder = SettingsChangePasswordFinder(_tester);

  final WidgetTester _tester;
  // ignore: unused_field
  final SettingsChangePasswordFinder _finder;

  SettingsChangePasswordActions enterCurrentCode(String code) {
    addCommand(EnterCurrentCodeCommand(_tester, code));
    return this;
  }

  SettingsChangePasswordActions enterNewCode(String code) {
    addCommand(EnterNewCodeCommand(_tester, code));
    return this;
  }

  SettingsChangePasswordActions enterConfirmCode(String code) {
    addCommand(EnterConfirmCodeCommand(_tester, code));
    return this;
  }

  SettingsActions clickSubmit() {
    addCommand(ClickSubmitCommand(_tester));
    return navigation.settings..commands.addAll(commands);
  }

  SettingsActions clickBack() {
    addCommand(ClickBackCommand(_tester));
    return navigation.settings..commands.addAll(commands);
  }

  SettingsChangePasswordActions expectErrorMessage(String message) {
    addCommand(ExpectErrorMessageCommand(_tester, message));
    return this;
  }

  SettingsActions changePassword({
    required String currentCode,
    required String newCode,
    required String confirmCode,
  }) {
    enterCurrentCode(currentCode);
    enterNewCode(newCode);
    enterConfirmCode(confirmCode);
    clickSubmit();
    return navigation.settings..commands.addAll(commands);
  }

  SettingsChangePasswordActions changePasswordAndFail({
    required String currentCode,
    required String newCode,
    required String confirmCode,
  }) {
    enterCurrentCode(currentCode);
    enterNewCode(newCode);
    enterConfirmCode(confirmCode);
    clickSubmit();
    return this;
  }
}
