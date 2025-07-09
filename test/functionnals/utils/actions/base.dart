import 'package:flutter_test/flutter_test.dart';

import '../index.dart';

abstract class ActionsInterface {
  ActionsInterface(this._navigation);

  final NavigationInterface _navigation;

  NavigationInterface get navigation => _navigation;
  final List<CommandInterface> commands = [];

  Future<void> execute() async {
    for (final command in commands) {
      await command.execute();
    }
    commands.clear();
  }

  void addCommand(CommandInterface command) {
    commands.add(command);
  }
}
