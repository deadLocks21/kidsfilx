import 'package:flutter_test/flutter_test.dart';

import '../../../../index.dart';
import 'videoplayer_modal_unlock.finder.dart';
import 'videoplayer_modal_unlock.commands.dart';

class VideoplayerModalUnlockActions extends ActionsInterface {
  VideoplayerModalUnlockActions(super.navigation, this._tester)
    : _finder = VideoplayerModalUnlockFinder(_tester);

  final WidgetTester _tester;
  // ignore: unused_field
  final VideoplayerModalUnlockFinder _finder;

  VideoplayerModalUnlockActions typeCode(String code) {
    addCommand(TypeUnlockCodeCommand(_tester, code));
    return this;
  }

  VideoplayerActions clickUnlock() {
    addCommand(ClickUnlockButtonCommand(_tester));
    return navigation.videoplayer..commands.addAll(commands);
  }

  VideoplayerModalUnlockActions clickUnlockAndFail() {
    addCommand(ClickUnlockButtonCommand(_tester));
    return this;
  }

  VideoplayerActions clickCancel() {
    addCommand(ClickCancelButtonCommand(_tester));
    return navigation.videoplayer..commands.addAll(commands);
  }

  VideoplayerModalUnlockActions expectErrorIsVisible() {
    addCommand(ExpectUnlockErrorIsVisibleCommand(_tester));
    return this;
  }

  VideoplayerModalUnlockActions expectErrorIsNotVisible() {
    addCommand(ExpectUnlockErrorIsNotVisibleCommand(_tester));
    return this;
  }
}
