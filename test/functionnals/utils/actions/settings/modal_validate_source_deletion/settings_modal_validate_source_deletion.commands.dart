import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../index.dart';

class ClickOnCancelCommand extends CommandInterface {
  ClickOnCancelCommand(this.tester);

  final WidgetTester tester;

  @override
  Future<void> execute() async {
    await tester.tap(
      find.byKey(
        const Key('settings_modal_validate_source_deletion_cancel_button'),
      ),
    );
    await tester.pumpAndSettle();
  }
}

class ClickOnValidateDeleteCommand extends CommandInterface {
  ClickOnValidateDeleteCommand(this.tester);

  final WidgetTester tester;

  @override
  Future<void> execute() async {
    await tester.tap(
      find.byKey(
        const Key(
          'settings_modal_validate_source_deletion_delete_source_button',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}
