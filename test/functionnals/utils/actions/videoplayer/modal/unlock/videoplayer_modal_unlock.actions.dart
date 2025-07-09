import 'package:flutter_test/flutter_test.dart';

import '../../../../index.dart';
import 'videoplayer_modal_unlock.finder.dart';

class VideoplayerModalUnlockActions extends ActionsInterface {
  VideoplayerModalUnlockActions(super.navigation, this._tester)
    : _finder = VideoplayerModalUnlockFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  // ignore: unused_field
  final VideoplayerModalUnlockFinder _finder;
}
