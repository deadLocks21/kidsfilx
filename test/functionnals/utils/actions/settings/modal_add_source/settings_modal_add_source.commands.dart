import 'package:flutter/widgets.dart';
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
