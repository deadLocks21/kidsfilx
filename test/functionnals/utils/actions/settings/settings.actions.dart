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

  SettingsActions expectSourceExists(String sourceName, String sourceUrl) {
    addCommand(ExpectSourceExistsCommand(_tester, sourceName, sourceUrl));
    return this;
  }

  SettingsModalValidateSourceDeletionActions clickOnDeleteSource(
    String sourceName,
  ) {
    addCommand(ClickOnDeleteSourceCommand(_tester, sourceName));
    return navigation.settingsModalValidateSourceDeletion
      ..commands.addAll(commands);
  }

  SettingsActions expectSourceIsAdded(String sourceName, String sourceUrl) {
    return expectSourceExists(sourceName, sourceUrl);
  }

  SettingsActions expectSourceIsDeleted(String sourceName, String sourceUrl) {
    return expectSourceDoesNotExist(sourceName, sourceUrl);
  }

  SettingsChangePasswordActions clickOnChangePassword() {
    addCommand(ClickOnChangePasswordCommand(_tester));
    return navigation.settingsChangePassword..commands.addAll(commands);
  }

  VideoplayerActions clickOnGoBack() {
    addCommand(ClickOnGoBackCommand(_tester));
    return navigation.videoplayer..commands.addAll(commands);
  }
}
