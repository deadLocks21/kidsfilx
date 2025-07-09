import 'package:flutter_test/flutter_test.dart';

import '../../index.dart';
import 'videoplayer.finder.dart';

class VideoplayerActions extends ActionsInterface {
  VideoplayerActions(super.navigation, this._tester)
    : _finder = VideoplayerFinder(_tester);

  // ignore: unused_field
  final WidgetTester _tester;
  // ignore: unused_field
  final VideoplayerFinder _finder;
}
