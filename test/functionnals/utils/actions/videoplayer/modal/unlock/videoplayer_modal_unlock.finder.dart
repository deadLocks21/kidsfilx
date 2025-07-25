import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class VideoplayerModalUnlockFinder {
  VideoplayerModalUnlockFinder(this.tester);

  final WidgetTester tester;

  final Finder modalFinder = find.byType(AlertDialog);
  final Finder titleFinder = find.text('Code de déverrouillage');
  final Finder subtitleFinder = find.text('Entrez le code à 4 chiffres');
  final Finder codeInputFinder = find.byKey(const Key('unlock_code_input'));
  final Finder cancelButtonFinder = find.text('Annuler');
  final Finder unlockButtonFinder = find.text('Déverrouiller');
  final Finder errorMessageFinder = find.text('Code incorrect !');
}
