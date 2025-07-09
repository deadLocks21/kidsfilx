import 'package:flutter_test/flutter_test.dart';

import 'types.dart';
import 'actions/videoplayer/videoplayer.actions.dart' as videoplayer_actions;
import 'actions/videoplayer/modal/chose_episode/videoplayer_modal_chose_episode.actions.dart'
    as videoplayer_modal_chose_episode_actions;
import 'actions/videoplayer/modal/unlock/videoplayer_modal_unlock.actions.dart'
    as videoplayer_modal_unlock_actions;
import 'actions/settings/settings.actions.dart' as settings_actions;
import 'actions/settings/modal_add_source/settings_modal_add_source.actions.dart'
    as settings_modal_add_source_actions;
import 'actions/settings/change_password/settings_change_password.actions.dart'
    as settings_change_password_actions;
import 'actions/settings/source/settings_source.actions.dart'
    as settings_source_actions;

class PageObjects implements NavigationInterface {
  PageObjects(this.tester);

  final WidgetTester tester;

  @override
  videoplayer_actions.VideoplayerActions get videoplayer =>
      videoplayer_actions.VideoplayerActions(this, tester);

  @override
  videoplayer_modal_chose_episode_actions.VideoplayerModalChooseEpisodeActions
  get videoplayerModalChooseEpisode =>
      videoplayer_modal_chose_episode_actions.VideoplayerModalChooseEpisodeActions(
        this,
        tester,
      );

  @override
  videoplayer_modal_unlock_actions.VideoplayerModalUnlockActions
  get videoplayerModalUnlock =>
      videoplayer_modal_unlock_actions.VideoplayerModalUnlockActions(
        this,
        tester,
      );

  @override
  settings_actions.SettingsActions get settings =>
      settings_actions.SettingsActions(this, tester);

  @override
  settings_modal_add_source_actions.SettingsModalAddSourceActions
  get settingsModalAddSource =>
      settings_modal_add_source_actions.SettingsModalAddSourceActions(
        this,
        tester,
      );

  @override
  settings_change_password_actions.SettingsChangePasswordActions
  get settingsChangePassword =>
      settings_change_password_actions.SettingsChangePasswordActions(
        this,
        tester,
      );

  @override
  settings_source_actions.SettingsSourceActions get settingsSource =>
      settings_source_actions.SettingsSourceActions(this, tester);
}
