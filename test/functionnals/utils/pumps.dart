import 'package:flutter_test/flutter_test.dart';
import 'package:kidflix/main.dart';

import 'index.dart';

Future<VideoplayerActions> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const VideoPlayerApp());
  await tester.pumpAndSettle();

  return (PageObjects(tester)).videoplayer;
}

// Future<VideoplayerActions> pumpAppWithData(WidgetTester tester) async {
//   await tester.pumpWidget(const VideoPlayerApp());
//   await tester.pumpAndSettle();

//   final app = (PageObjects(tester)).videoplayer;

//   app.

//   return ;
// }