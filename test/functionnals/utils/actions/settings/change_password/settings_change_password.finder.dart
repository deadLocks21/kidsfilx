import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SettingsChangePasswordFinder {
  SettingsChangePasswordFinder(this.tester);

  final WidgetTester tester;

  // Finders pour les éléments de la page
  final Finder titleFinder = find.byKey(
    const Key('settings_change_password_title'),
  );
  final Finder backButtonFinder = find.byKey(
    const Key('settings_change_password_back_button'),
  );
  final Finder currentCodeFieldFinder = find.byKey(
    const Key('settings_change_password_current_code_field'),
  );
  final Finder newCodeFieldFinder = find.byKey(
    const Key('settings_change_password_new_code_field'),
  );
  final Finder confirmCodeFieldFinder = find.byKey(
    const Key('settings_change_password_confirm_code_field'),
  );
  final Finder submitButtonFinder = find.byKey(
    const Key('settings_change_password_submit_button'),
  );

  Finder errorMessageFinder(String message) => find.text(message);
  Finder successMessageFinder(String message) => find.text(message);
}
