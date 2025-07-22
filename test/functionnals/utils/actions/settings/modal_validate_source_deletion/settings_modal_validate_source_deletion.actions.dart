import 'package:flutter_test/flutter_test.dart';

import '../../../index.dart';
import 'settings_modal_validate_source_deletion.commands.dart';

class SettingsModalValidateSourceDeletionActions extends ActionsInterface {
  SettingsModalValidateSourceDeletionActions(super.navigation, this._tester);

  final WidgetTester _tester;

  SettingsActions clickOnCancel() {
    addCommand(ClickOnCancelCommand(_tester));
    return navigation.settings..commands.addAll(commands);
  }

  SettingsActions clickOnValidateDelete() {
    addCommand(ClickOnValidateDeleteCommand(_tester));
    return navigation.settings..commands.addAll(commands);
  }
}
