import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidflix/core/domain/model/source.dart';
import 'package:kidflix/infrastructure/source/in-memory.source.repository.dart';
import 'package:kidflix/infrastructure/source_url/in-memory.source_url.repository.dart';
import 'package:kidflix/infrastructure/source/provider.source.repository.dart';
import 'package:kidflix/infrastructure/source_url/provider.source_url.repository.dart';
import 'package:kidflix/infrastructure/unlock_code/in-memory.unlock-code.repository.dart';
import 'package:kidflix/infrastructure/unlock_code/provider.unlock-code.repository.dart';
import 'package:kidflix/main.dart';

import 'index.dart';

Future<VideoplayerActions> pumpApp(
  WidgetTester tester, {
  List<Source>? addedSources,
  List<Source>? sources,
  String? unlockCode = '1234',
}) async {
  InMemoryUnlockCodeRepository.reset();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sourceUrlRepositoryProvider.overrideWith(
          (ref) =>
              InMemorySourceUrlRepository(initialSources: sources, delay: 200),
        ),
        sourceRepositoryProvider.overrideWith(
          (ref) => InMemorySourceRepository(initialSources: addedSources ?? []),
        ),
        unlockCodeRepositoryProvider.overrideWith(
          (ref) => InMemoryUnlockCodeRepository(initialCode: unlockCode),
        ),
      ],
      child: const VideoPlayerApp(),
    ),
  );
  await tester.pumpAndSettle();

  return (PageObjects(tester)).videoplayer;
}
