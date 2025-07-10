import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SettingsFinder {
  SettingsFinder(this.tester);

  final WidgetTester tester;

  final Finder titleFinder = find.byKey(const Key('settings_title'));
  final Finder addSourceButtonFinder = find.byKey(
    const Key('settings_add_source_button'),
  );
}
