import 'package:flutter_test/flutter_test.dart';

import '../utils/index.dart';

void main() {
  setupTestEnvironment();

  group('Videoplayer', () {
    // testWidgets('aucun épisode n\'est sélectionné au démarrage', (
    //   tester,
    // ) async {
    //   final app = await pumpApp(tester);
    //   await app
    //       .expectNoEpisodeIsSelected()
    //       .expectPlayerIsNotPlaying()
    //       .execute();
    // });

    testWidgets('go to settings', (tester) async {
      final app = await pumpApp(tester);
      await app
          .goToSettings()
          .expectIAmOnSettings()
          .clickOnAddSource()
          .typeSource('https://timothe.hofmann.fr/tchoupi-volume1.json')
          .expectSourceURLIsValid()
          .execute();
    });
  });
}
