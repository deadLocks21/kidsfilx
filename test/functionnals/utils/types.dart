abstract class NavigationInterface {
  dynamic get videoplayer;

  dynamic get videoplayerModalChooseEpisode;

  dynamic get videoplayerModalUnlock;

  dynamic get settings;

  dynamic get settingsModalAddSource;

  dynamic get settingsModalValidateSourceDeletion;

  dynamic get settingsChangePassword;

  dynamic get settingsSource;
}

abstract class CommandInterface {
  Future<void> execute();
}
