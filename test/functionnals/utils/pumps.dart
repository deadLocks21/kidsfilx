import 'package:flutter_test/flutter_test.dart';
import 'package:kidflix/main.dart';

import 'index.dart';

Future<VideoplayerActions> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const VideoPlayerApp());
  await tester.pumpAndSettle();

  return (PageObjects(tester)).videoplayer;
}