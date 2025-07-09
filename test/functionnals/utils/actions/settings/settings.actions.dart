import 'package:flutter_test/flutter_test.dart';

import '../../index.dart';
import 'settings.finder.dart';

class SettingsActions extends ActionsInterface {
  SettingsActions(super.navigation, this._tester)
    : _finder = SettingsFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  // ignore: unused_field
  final SettingsFinder _finder;
}
