import 'package:flutter_test/flutter_test.dart';

import '../../../../index.dart';
import 'videoplayer_modal_chose_episode.finder.dart';

class VideoplayerModalChooseEpisodeActions extends ActionsInterface {
  VideoplayerModalChooseEpisodeActions(super.navigation, this._tester)
    : _finder = VideoplayerModalChooseEpisodeFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  // ignore: unused_field
  final VideoplayerModalChooseEpisodeFinder _finder;
}
