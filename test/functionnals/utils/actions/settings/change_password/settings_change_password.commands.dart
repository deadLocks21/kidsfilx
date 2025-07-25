import 'package:flutter_test/flutter_test.dart';

import '../../../index.dart';
import 'settings_change_password.finder.dart';

class EnterCurrentCodeCommand extends CommandInterface {
  EnterCurrentCodeCommand(this.tester, this.code)
    : _finder = SettingsChangePasswordFinder(tester);

  final WidgetTester tester;
  final String code;
  final SettingsChangePasswordFinder _finder;

  @override
  Future<void> execute() async {
    await tester.enterText(_finder.currentCodeFieldFinder, code);
    await tester.pumpAndSettle();
  }
}

class EnterNewCodeCommand extends CommandInterface {
  EnterNewCodeCommand(this.tester, this.code)
    : _finder = SettingsChangePasswordFinder(tester);

  final WidgetTester tester;
  final String code;
  final SettingsChangePasswordFinder _finder;

  @override
  Future<void> execute() async {
    await tester.enterText(_finder.newCodeFieldFinder, code);
    await tester.pumpAndSettle();
  }
}

class EnterConfirmCodeCommand extends CommandInterface {
  EnterConfirmCodeCommand(this.tester, this.code)
    : _finder = SettingsChangePasswordFinder(tester);

  final WidgetTester tester;
  final String code;
  final SettingsChangePasswordFinder _finder;

  @override
  Future<void> execute() async {
    await tester.enterText(_finder.confirmCodeFieldFinder, code);
    await tester.pumpAndSettle();
  }
}

class ClickSubmitCommand extends CommandInterface {
  ClickSubmitCommand(this.tester)
    : _finder = SettingsChangePasswordFinder(tester);

  final WidgetTester tester;
  final SettingsChangePasswordFinder _finder;

  @override
  Future<void> execute() async {
    await tester.tap(_finder.submitButtonFinder);
    await tester.pumpAndSettle();
  }
}

class ClickBackCommand extends CommandInterface {
  ClickBackCommand(this.tester)
    : _finder = SettingsChangePasswordFinder(tester);

  final WidgetTester tester;
  final SettingsChangePasswordFinder _finder;

  @override
  Future<void> execute() async {
    await tester.tap(_finder.backButtonFinder);
    await tester.pumpAndSettle();
  }
}

class ExpectErrorMessageCommand extends CommandInterface {
  ExpectErrorMessageCommand(this.tester, this.message)
    : _finder = SettingsChangePasswordFinder(tester);

  final WidgetTester tester;
  final String message;
  final SettingsChangePasswordFinder _finder;

  @override
  Future<void> execute() async {
    expect(_finder.errorMessageFinder(message), findsOneWidget);
  }
}
