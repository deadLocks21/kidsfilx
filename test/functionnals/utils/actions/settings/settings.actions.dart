import 'package:flutter_test/flutter_test.dart';

import '../../index.dart';
import 'settings.commands.dart';
import 'settings.finder.dart';

class SettingsActions extends ActionsInterface {
  SettingsActions(super.navigation, this._tester)
    : _finder = SettingsFinder(_tester);

  final WidgetTester _tester;
  // ignore: unused_field
  final SettingsFinder _finder;

  SettingsActions expectIAmOnSettings() {
    addCommand(ExpectIAmOnSettingsCommand(_tester));
    return this;
  }

  SettingsModalAddSourceActions clickOnAddSource() {
    addCommand(ClickOnAddSourceCommand(_tester));
    return navigation.settingsModalAddSource..commands.addAll(commands);
  }

  SettingsActions expectSourceDoesNotExist(
    String sourceName,
    String sourceUrl,
  ) {
    addCommand(ExpectSourceDoesNotExistCommand(_tester, sourceName, sourceUrl));
    return this;
  }

  SettingsActions expectSourceIsAdded(String sourceName, String sourceUrl) {
    addCommand(ExpectSourceIsAddedCommand(_tester, sourceName, sourceUrl));
    return this;
  }
}
