import 'package:flutter_test/flutter_test.dart';

import '../../index.dart';
import 'settings.finder.dart';

class ClickOnAddSourceCommand extends CommandInterface {
  ClickOnAddSourceCommand(this.tester)
    : _finder = SettingsFinder(tester);

  final WidgetTester tester;
  final SettingsFinder _finder;

  @override
  Future<void> execute() async {
    await tester.tap(_finder.addSourceButtonFinder);
    await tester.pumpAndSettle();
  }
}

class ExpectIAmOnSettingsCommand extends CommandInterface {
  ExpectIAmOnSettingsCommand(this.tester)
    : _finder = SettingsFinder(tester);

  final WidgetTester tester;
  final SettingsFinder _finder;

  @override
  Future<void> execute() async {
    expect(_finder.titleFinder, findsOneWidget);
  }
}