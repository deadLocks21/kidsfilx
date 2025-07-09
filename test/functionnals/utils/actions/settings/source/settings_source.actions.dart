import 'package:flutter_test/flutter_test.dart';

import '../../../index.dart';
import 'settings_source.finder.dart';

class SettingsSourceActions extends ActionsInterface {
  SettingsSourceActions(super.navigation, this._tester)
    : _finder = SettingsSourceFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  // ignore: unused_field
  final SettingsSourceFinder _finder;
}
