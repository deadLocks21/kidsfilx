import 'package:flutter_test/flutter_test.dart';

import '../../../index.dart';
import 'settings_modal_add_source.finder.dart';

class SettingsModalAddSourceActions extends ActionsInterface {
  SettingsModalAddSourceActions(super.navigation, this._tester)
    : _finder = SettingsModalAddSourceFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  // ignore: unused_field
  final SettingsModalAddSourceFinder _finder;
}
