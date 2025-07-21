import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../index.dart';
import 'settings_modal_add_source.finder.dart';

class TypeSourceCommand extends CommandInterface {
  TypeSourceCommand(this.tester, this.source)
    : _finder = SettingsModalAddSourceFinder(tester);

  final WidgetTester tester;
  final SettingsModalAddSourceFinder _finder;
  final String source;

  @override
  Future<void> execute() async {
    await tester.enterText(_finder.urlInputFinder, source);
    await tester.pump(const Duration(milliseconds: 600));
  }
}

class ClickOnAddSourceCommand extends CommandInterface {
  ClickOnAddSourceCommand(this.tester)
    : _finder = SettingsModalAddSourceFinder(tester);

  final WidgetTester tester;
  final SettingsModalAddSourceFinder _finder;

  @override
  Future<void> execute() async {
    await tester.tap(_finder.addSourceButtonFinder);
    await tester.pumpAndSettle();
  }
}

class WaitForCommand extends CommandInterface {
  WaitForCommand(this.tester, this.milliseconds);

  final WidgetTester tester;
  final int milliseconds;

  @override
  Future<void> execute() async {
    await tester.pump(Duration(milliseconds: milliseconds));
  }
}

class ExpectAddSourceButtonIsDisabledCommand extends CommandInterface {
  ExpectAddSourceButtonIsDisabledCommand(this.tester)
    : _finder = SettingsModalAddSourceFinder(tester);

  final WidgetTester tester;
  final SettingsModalAddSourceFinder _finder;

  @override
  Future<void> execute() async {
    final widget = tester.widget<ElevatedButton>(_finder.addSourceButtonFinder);
    expect(widget.enabled, isFalse);
  }
}

class ExpectSourceURLIsValidCommand extends CommandInterface {
  ExpectSourceURLIsValidCommand(this.tester)
    : _finder = SettingsModalAddSourceFinder(tester);

  final WidgetTester tester;
  final SettingsModalAddSourceFinder _finder;

  @override
  Future<void> execute() async {
    final widget = tester.widget<Text>(_finder.urlCheckMessageFinder);
    expect(
      widget.data,
      matches(RegExp(r'Source valide - [0-9]+ épisode\(s\) détecté\(s\)')),
    );
  }
}

class ExpectSourceURLIsInvalidCommand extends CommandInterface {
  ExpectSourceURLIsInvalidCommand(this.tester)
    : _finder = SettingsModalAddSourceFinder(tester);

  final WidgetTester tester;
  final SettingsModalAddSourceFinder _finder;

  @override
  Future<void> execute() async {
    final widget = tester.widget<Text>(_finder.urlCheckMessageFinder);
    expect(widget.data, matches('Source non trouvée'));
  }
}

class ExpectSourceValidationIsLoadingCommand extends CommandInterface {
  ExpectSourceValidationIsLoadingCommand(this.tester)
    : _finder = SettingsModalAddSourceFinder(tester);

  final WidgetTester tester;
  final SettingsModalAddSourceFinder _finder;

  @override
  Future<void> execute() async {
    final widget = tester.widget<Text>(_finder.urlCheckMessageFinder);
    expect(widget.data, matches('Vérification en cours...'));
  }
}
