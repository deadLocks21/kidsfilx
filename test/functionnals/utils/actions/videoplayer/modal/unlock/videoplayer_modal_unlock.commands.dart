import 'package:flutter_test/flutter_test.dart';

import '../../../../index.dart';
import 'videoplayer_modal_unlock.finder.dart';

class TypeUnlockCodeCommand implements CommandInterface {
  TypeUnlockCodeCommand(this._tester, this._code)
    : _finder = VideoplayerModalUnlockFinder(_tester);

  final WidgetTester _tester;
  final String _code;
  final VideoplayerModalUnlockFinder _finder;

  @override
  Future<void> execute() async {
    await _tester.enterText(_finder.codeInputFinder, _code);
    await _tester.pump();
  }
}

class ClickUnlockButtonCommand implements CommandInterface {
  ClickUnlockButtonCommand(this._tester)
    : _finder = VideoplayerModalUnlockFinder(_tester);

  final WidgetTester _tester;
  final VideoplayerModalUnlockFinder _finder;

  @override
  Future<void> execute() async {
    await _tester.tap(_finder.unlockButtonFinder);
    await _tester.pumpAndSettle();
  }
}

class ClickCancelButtonCommand implements CommandInterface {
  ClickCancelButtonCommand(this._tester)
    : _finder = VideoplayerModalUnlockFinder(_tester);

  final WidgetTester _tester;
  final VideoplayerModalUnlockFinder _finder;

  @override
  Future<void> execute() async {
    await _tester.tap(_finder.cancelButtonFinder);
    await _tester.pumpAndSettle();
  }
}

class ExpectUnlockErrorIsVisibleCommand implements CommandInterface {
  ExpectUnlockErrorIsVisibleCommand(this._tester)
    : _finder = VideoplayerModalUnlockFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  final VideoplayerModalUnlockFinder _finder;

  @override
  Future<void> execute() async {
    expect(_finder.errorMessageFinder, findsOneWidget);
  }
}

class ExpectUnlockErrorIsNotVisibleCommand implements CommandInterface {
  ExpectUnlockErrorIsNotVisibleCommand(this._tester)
    : _finder = VideoplayerModalUnlockFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  final VideoplayerModalUnlockFinder _finder;

  @override
  Future<void> execute() async {
    expect(_finder.errorMessageFinder, findsNothing);
  }
}
