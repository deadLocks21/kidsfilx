import 'package:flutter_test/flutter_test.dart';

import '../../index.dart';
import 'videoplayer.commands.dart';
import 'videoplayer.finder.dart';

class VideoplayerActions extends ActionsInterface {
  VideoplayerActions(super.navigation, this._tester)
    : _finder = VideoplayerFinder(_tester);

  final WidgetTester _tester;
  // ignore: unused_field
  final VideoplayerFinder _finder;

  SettingsActions goToSettings() {
    addCommand(GoToSettingsCommand(_tester));
    return navigation.settings..commands.addAll(commands);
  }

  VideoplayerActions expectEpisodeIsSelected(String episode) {
    addCommand(ExpectEpisodeIsSelectedCommand(_tester, episode));
    return this;
  }

  VideoplayerActions expectNoEpisodeIsSelected() {
    addCommand(ExpectNoEpisodeIsSelectedCommand(_tester));
    return this;
  }

  VideoplayerActions expectPlayerIsPlaying() {
    addCommand(ExpectPlayerIsPlayingCommand(_tester));
    return this;
  }

  VideoplayerActions expectPlayerIsNotPlaying() {
    addCommand(ExpectPlayerIsNotPlayingCommand(_tester));
    return this;
  }

  VideoplayerActions clickLockButton() {
    addCommand(ClickLockButtonCommand(_tester));
    return this;
  }

  VideoplayerModalUnlockActions clickUnlockButton() {
    addCommand(ClickUnlockButtonCommand(_tester));
    return navigation.videoplayerModalUnlock..commands.addAll(commands);
  }

  VideoplayerActions expectPlayerIsLocked() {
    addCommand(ExpectPlayerIsLockedCommand(_tester));
    return this;
  }

  VideoplayerActions expectPlayerIsUnlocked() {
    addCommand(ExpectPlayerIsUnlockedCommand(_tester));
    return this;
  }

  VideoplayerModalUnlockActions unlockWithCode(String code) {
    addCommand(ClickLockButtonCommand(_tester));
    return navigation.videoplayerModalUnlock
      ..typeCode(code)
      ..clickUnlock();
  }
}
