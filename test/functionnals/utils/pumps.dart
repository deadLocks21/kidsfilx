import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidflix/core/domain/model/source.dart';
import 'package:kidflix/infrastructure/source/in-memory.source_url.repository.dart';
import 'package:kidflix/infrastructure/source/provider.source_url.repository.dart';
import 'package:kidflix/main.dart';

import 'index.dart';

Future<VideoplayerActions> pumpApp(
  WidgetTester tester, {
  List<Source>? sources,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sourceUrlRepositoryProvider.overrideWith(
          (ref) =>
              InMemorySourceUrlRepository(initialSources: sources, delay: 200),
        ),
      ],
      child: const VideoPlayerApp(),
    ),
  );
  await tester.pumpAndSettle();

  return (PageObjects(tester)).videoplayer;
}
