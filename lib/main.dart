import 'package:flutter/material.dart';
import 'package:kidflix/presentation/videoplayer/videoplayer.page.dart';

void main() => runApp(const VideoPlayerApp());

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
