import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidflix/shared/dependancy_injection.dart';
import 'package:kidflix/ui/videoplayer/videoplayer.page.dart';

void main() {
  if (!kDebugMode) {
    DependancyInjection.setEnvironment(Environment.production);
  }

  runApp(const ProviderScope(child: VideoPlayerApp()));
}

class VideoPlayerApp extends StatelessWidget {
  const VideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lecteur Vidéo',
      home: VideoplayerPage(),
    );
  }
}
