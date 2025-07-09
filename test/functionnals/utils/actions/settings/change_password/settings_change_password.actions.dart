import 'package:flutter_test/flutter_test.dart';

import '../../../index.dart';
import 'settings_change_password.finder.dart';

class SettingsChangePasswordActions extends ActionsInterface {
  SettingsChangePasswordActions(super.navigation, this._tester)
    : _finder = SettingsChangePasswordFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  // ignore: unused_field
  final SettingsChangePasswordFinder _finder;
}
