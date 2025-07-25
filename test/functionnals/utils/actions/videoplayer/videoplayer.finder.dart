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
  final Finder episodesButtonFinder = find.byKey(
    const Key('videoplayer_episodes_button'),
  );
  final Finder settingsButtonFinder = find.byKey(
    const Key('videoplayer_settings_button'),
  );
  final Finder lockButtonFinder = find.byKey(
    const Key('videoplayer_lock_button'),
  );
  final Finder unlockButtonFinder = find.byKey(
    const Key('videoplayer_unlock_button'),
  );
  final Finder nextButtonFinder = find.byKey(
    const Key('videoplayer_next_button'),
  );
}
