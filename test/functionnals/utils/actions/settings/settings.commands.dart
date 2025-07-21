import 'package:flutter_test/flutter_test.dart';

import '../../index.dart';
import 'settings.finder.dart';

class ClickOnAddSourceCommand extends CommandInterface {
  ClickOnAddSourceCommand(this.tester) : _finder = SettingsFinder(tester);

  final WidgetTester tester;
  final SettingsFinder _finder;

  @override
  Future<void> execute() async {
    await tester.tap(_finder.addSourceButtonFinder);
    await tester.pumpAndSettle();
  }
}

class ExpectIAmOnSettingsCommand extends CommandInterface {
  ExpectIAmOnSettingsCommand(this.tester) : _finder = SettingsFinder(tester);

  final WidgetTester tester;
  final SettingsFinder _finder;

  @override
  Future<void> execute() async {
    expect(_finder.titleFinder, findsOneWidget);
  }
}

class ExpectSourceDoesNotExistCommand extends CommandInterface {
  ExpectSourceDoesNotExistCommand(this.tester, this.sourceName, this.sourceUrl);

  final WidgetTester tester;
  final String sourceName;
  final String sourceUrl;

  @override
  Future<void> execute() async {
    expect(find.text(sourceName), findsNothing);
    expect(find.text(sourceUrl), findsNothing);
  }
}

class ExpectSourceIsAddedCommand extends CommandInterface {
  ExpectSourceIsAddedCommand(this.tester, this.sourceName, this.sourceUrl);

  final WidgetTester tester;
  final String sourceName;
  final String sourceUrl;

  @override
  Future<void> execute() async {
    expect(find.text(sourceName), findsAtLeast(1));
    expect(find.text(sourceUrl), findsAtLeast(1));
  }
}
