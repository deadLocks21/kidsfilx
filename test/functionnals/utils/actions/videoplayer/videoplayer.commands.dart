import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import '../../index.dart';
import 'videoplayer.finder.dart';

class ExpectEpisodeIsSelectedCommand extends CommandInterface {
  ExpectEpisodeIsSelectedCommand(this.tester, this.episode)
    : _finder = VideoplayerFinder(tester);

  final WidgetTester tester;
  final VideoplayerFinder _finder;
  final String episode;

  @override
  Future<void> execute() async {
    final widget = tester.widget<Text>(_finder.titleFinder);
    expect(widget.data, episode);
  }
}

class ExpectNoEpisodeIsSelectedCommand extends CommandInterface {
  ExpectNoEpisodeIsSelectedCommand(this.tester)
    : _finder = VideoplayerFinder(tester);

  final WidgetTester tester;
  final VideoplayerFinder _finder;

  @override
  Future<void> execute() async {
    final widget = tester.widget<Text>(_finder.titleFinder);
    expect(widget.data, 'Aucun épisode sélectionné');
  }
}

class ExpectPlayerIsPlayingCommand extends CommandInterface {
  ExpectPlayerIsPlayingCommand(this.tester)
    : _finder = VideoplayerFinder(tester);

  final WidgetTester tester;
  final VideoplayerFinder _finder;

  @override
  Future<void> execute() async {
    expect(_finder.playButtonFinder, findsNothing);
    expect(_finder.pauseButtonFinder, findsOneWidget);

    final video = tester.widget<VideoPlayer>(_finder.videoFinder);
    expect(video.controller.value.isPlaying, isTrue);
  }
}

class ExpectPlayerIsNotPlayingCommand extends CommandInterface {
  ExpectPlayerIsNotPlayingCommand(this.tester)
    : _finder = VideoplayerFinder(tester);

  final WidgetTester tester;
  final VideoplayerFinder _finder;

  @override
  Future<void> execute() async {
    expect(_finder.playButtonFinder, findsOneWidget);
    expect(_finder.pauseButtonFinder, findsNothing);

    final video = tester.widget<VideoPlayer>(_finder.videoFinder);
    expect(video.controller.value.isPlaying, isFalse);
  }
}

class GoToSettingsCommand extends CommandInterface {
  GoToSettingsCommand(this.tester) : _finder = VideoplayerFinder(tester);

  final WidgetTester tester;
  final VideoplayerFinder _finder;

  @override
  Future<void> execute() async {
    await tester.tap(_finder.settingsButtonFinder);
    await tester.pumpAndSettle();
  }
}

class ClickLockButtonCommand extends CommandInterface {
  ClickLockButtonCommand(this.tester) : _finder = VideoplayerFinder(tester);

  final WidgetTester tester;
  final VideoplayerFinder _finder;

  @override
  Future<void> execute() async {
    await tester.tap(_finder.lockButtonFinder);
    await tester.pumpAndSettle();
  }
}

class ClickUnlockButtonCommand extends CommandInterface {
  ClickUnlockButtonCommand(this.tester) : _finder = VideoplayerFinder(tester);

  final WidgetTester tester;
  final VideoplayerFinder _finder;

  @override
  Future<void> execute() async {
    await tester.tap(_finder.unlockButtonFinder);
    await tester.pumpAndSettle();
  }
}

class ExpectPlayerIsLockedCommand extends CommandInterface {
  ExpectPlayerIsLockedCommand(this.tester)
    : _finder = VideoplayerFinder(tester);

  final WidgetTester tester;
  final VideoplayerFinder _finder;

  @override
  Future<void> execute() async {
    expect(_finder.lockButtonFinder, findsNothing);
    expect(_finder.unlockButtonFinder, findsOneWidget);
  }
}

class ExpectPlayerIsUnlockedCommand extends CommandInterface {
  ExpectPlayerIsUnlockedCommand(this.tester)
    : _finder = VideoplayerFinder(tester);

  final WidgetTester tester;
  final VideoplayerFinder _finder;

  @override
  Future<void> execute() async {
    expect(_finder.lockButtonFinder, findsOneWidget);
    expect(_finder.unlockButtonFinder, findsNothing);
  }
}
