import 'package:flutter_test/flutter_test.dart';

import '../utils/index.dart';

void main() {
  setupTestEnvironment();

  group('Videoplayer', () {
    testWidgets('aucun épisode n\'est sélectionné au démarrage', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await app
          .expectNoEpisodeIsSelected()
          .expectPlayerIsNotPlaying()
          .execute();
    });
  });
}
