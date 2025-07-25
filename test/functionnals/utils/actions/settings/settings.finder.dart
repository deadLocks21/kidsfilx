import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SettingsFinder {
  SettingsFinder(this.tester);

  final WidgetTester tester;

  final Finder titleFinder = find.byKey(const Key('settings_title'));
  final Finder addSourceButtonFinder = find.byKey(
    const Key('settings_add_source_button'),
  );
  final Finder sourceTileFinder = find.byKey(const Key('settings_source_tile'));
  final Finder sourceTitleFinder = find.byKey(
    const Key('settings_source_title'),
  );
  final Finder deleteSourceButtonFinder = find.byKey(
    const Key('settings_delete_source_button'),
  );
  final Finder changePasswordButtonFinder = find.byKey(
    const Key('settings_change_password_button'),
  );
  final Finder goBackButtonFinder = find.byKey(
    const Key('settings_go_back_button'),
  );

  Finder deleteSourceButtonForSource(String sourceName) {
    final allSourceTiles = find.byKey(const Key('settings_source_tile'));

    for (final tile in allSourceTiles.evaluate()) {
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byWidget(tile.widget),
          matching: sourceTitleFinder,
        ),
      );
      if (title.data == sourceName) {
        return find.descendant(
          of: find.byWidget(tile.widget),
          matching: deleteSourceButtonFinder,
        );
      }
    }

    // If no matching source is found, return an empty finder
    return find.byKey(const Key('non_existent_key'));
  }
}
