import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class VideoplayerFinder {
  VideoplayerFinder(this.tester);

  final WidgetTester tester;

  final Finder titleFinder = find.byKey(const Key('videoplayer_title'));
  final Finder videoFinder = find.byKey(const Key('videoplayer_video'));
  final Finder playButtonFinder = find.byKey(
    const Key('videoplayer_play_button'),
  );
  final Finder pauseButtonFinder = find.byKey(
    const Key('videoplayer_pause_button'),
  );
}
