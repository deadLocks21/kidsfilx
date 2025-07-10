import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SettingsModalAddSourceFinder {
  SettingsModalAddSourceFinder(this.tester);

  final WidgetTester tester;

  final Finder urlInputFinder = find.byKey(
    const Key('settings_modal_add_source_url_input'),
  );
  final Finder addSourceButtonFinder = find.byKey(
    const Key('settings_modal_add_source_add_button'),
  );
  final Finder urlCheckMessageFinder = find.byKey(
    const Key('settings_modal_add_source_url_check_message'),
  );
}
