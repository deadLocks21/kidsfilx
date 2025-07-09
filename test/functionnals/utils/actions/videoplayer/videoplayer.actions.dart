import 'package:flutter_test/flutter_test.dart';

import '../../index.dart';
import 'videoplayer.commands.dart';
import 'videoplayer.finder.dart';

class VideoplayerActions extends ActionsInterface {
  VideoplayerActions(super.navigation, this._tester)
    : _finder = VideoplayerFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  // ignore: unused_field
  final VideoplayerFinder _finder;

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
}
