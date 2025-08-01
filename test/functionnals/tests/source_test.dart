import 'package:flutter_test/flutter_test.dart';

import '../../builders/index.dart';
import '../utils/index.dart';

void main() {
  setupTestEnvironment();

  group('Add/delete source', () {
    testWidgets('add a valid source', (tester) async {
      final app = await pumpApp(tester);
      await app
          .goToSettings()
          .expectIAmOnSettings()
          .expectSourceDoesNotExist(
            'Tchoupi Volume 1',
            'https://kidflix.example.com/tchoupi/volume1.json',
          )
          .clickOnAddSource()
          .typeSource('https://kidflix.example.com/tchoupi/volume1.json')
          .expectSourceValidationIsLoading()
          .waitFor(250)
          .expectSourceURLIsValid()
          .clickOnAddSource()
          .expectSourceIsAdded(
            'Tchoupi Volume 1',
            'https://kidflix.example.com/tchoupi/volume1.json',
          )
          .execute();
    });

    testWidgets('cannot add an invalid source', (tester) async {
      final app = await pumpApp(tester);
      await app
          .goToSettings()
          .expectIAmOnSettings()
          .clickOnAddSource()
          .typeSource('https://kidflix.example.com/tchoupi/volume0.json')
          .waitFor(250)
          .expectSourceURLIsInvalid()
          .expectAddSourceButtonIsDisabled()
          .execute();
    });

    testWidgets('can delete a source', (tester) async {
      final app = await pumpApp(tester, addedSources: [aSource().build()]);
      await app
          .goToSettings()
          .expectSourceExists(
            'Tchoupi Volume 1',
            'https://kidflix.example.com/tchoupi/volume1.json',
          )
          .clickOnDeleteSource('Tchoupi Volume 1')
          .clickOnValidateDelete()
          .expectSourceIsDeleted(
            'Tchoupi Volume 1',
            'https://kidflix.example.com/tchoupi/volume1.json',
          )
          .execute();
    });
  });
}
