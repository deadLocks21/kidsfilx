import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

void main() => runApp(const VideoPlayerApp());

class VideoPlayerApp extends StatelessWidget {
  const VideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lecteur Vidéo',
      home: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  Timer? _timer;
  Timer? _uiTimer;
  bool _isDragging = false;
  bool _isLocked = false;
  bool _showUI = true;
  final TextEditingController _codeController = TextEditingController();
  String _unlockCode = "1234";
  List<Map<String, dynamic>> _sources = [];
  Map<String, dynamic>? _currentSource;
  Map<String, dynamic>? _currentEpisode;
  List<Map<String, dynamic>> _downloadedEpisodes = [];

  @override
  void initState() {
    super.initState();
    // Masquer la barre de statut et la barre de navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Initialiser avec un contrôleur vide
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://timothe.hofmann.fr/tchoupi.mp4'),
    );
    _initializeVideoPlayerFuture =
        Future.value(); // Pas d'initialisation automatique
    _controller.setLooping(true);
    _startTimer();
    _loadUnlockCode();
    _loadSources();
    _loadDownloadedEpisodes();
  }

  Future<void> _loadUnlockCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlockCode = prefs.getString('unlock_code') ?? "1234";
    });
  }

  Future<void> _saveUnlockCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unlock_code', code);
    setState(() {
      _unlockCode = code;
    });
  }

  Future<void> _loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    final sourcesJson = prefs.getStringList('video_sources') ?? [];
    setState(() {
      _sources = sourcesJson.map((json) {
        final Map<String, dynamic> source = Map<String, dynamic>.from(
          jsonDecode(json) as Map,
        );
        return source;
      }).toList();
    });
    // Recharger les épisodes après avoir chargé les sources
    await _loadDownloadedEpisodes();
  }

  Future<void> _loadDownloadedEpisodes() async {
    final List<Map<String, dynamic>> allDownloaded = [];

    for (final source in _sources) {
      final prefs = await SharedPreferences.getInstance();
      final downloadedJson =
          prefs.getStringList('downloaded_episodes_${source['name']}') ?? [];
      final downloadedIndices = downloadedJson.map((e) => int.parse(e)).toSet();

      // Charger les fichiers téléchargés
      final filesJson = prefs.getString('downloaded_files_${source['name']}');
      Map<int, String> downloadedFiles = {};
      if (filesJson != null) {
        final Map<String, dynamic> filesMap = jsonDecode(filesJson);
        downloadedFiles = filesMap.map(
          (key, value) => MapEntry(int.parse(key), value as String),
        );
      }

      // Charger les métadonnées sauvegardées
      final metadataJson = prefs.getString(
        'episodes_metadata_${source['name']}',
      );
      Map<int, Map<String, dynamic>> episodesMetadata = {};
      if (metadataJson != null) {
        final Map<String, dynamic> metadataMap = jsonDecode(metadataJson);
        episodesMetadata = metadataMap.map(
          (key, value) =>
              MapEntry(int.parse(key), Map<String, dynamic>.from(value as Map)),
        );
      }

      if (downloadedIndices.isNotEmpty) {
        for (final index in downloadedIndices) {
          final localFile = downloadedFiles[index];
          final episodeMetadata = episodesMetadata[index];

          // Vérifier que le fichier local existe
          if (localFile != null && episodeMetadata != null) {
            final file = File(localFile);
            if (await file.exists()) {
              allDownloaded.add({
                'source': source,
                'episode': episodeMetadata,
                'sourceName': source['name'],
                'episodeName': episodeMetadata['name'] ?? 'Épisode $index',
                'url': localFile, // Utiliser le fichier local
                'localFile': true,
              });
            }
          }
        }
      }
    }

    setState(() {
      _downloadedEpisodes = allDownloaded;
    });

    // Nettoyer les épisodes orphelins (sans fichier)
    await _cleanupOrphanedEpisodes();
  }

  Future<void> _cleanupOrphanedEpisodes() async {
    for (final source in _sources) {
      final prefs = await SharedPreferences.getInstance();
      final downloadedJson =
          prefs.getStringList('downloaded_episodes_${source['name']}') ?? [];
      final downloadedIndices = downloadedJson.map((e) => int.parse(e)).toSet();

      final filesJson = prefs.getString('downloaded_files_${source['name']}');
      Map<int, String> downloadedFiles = {};
      if (filesJson != null) {
        final Map<String, dynamic> filesMap = jsonDecode(filesJson);
        downloadedFiles = filesMap.map(
          (key, value) => MapEntry(int.parse(key), value as String),
        );
      }

      final Set<int> validIndices = {};
      final Map<int, String> validFiles = {};

      for (final index in downloadedIndices) {
        final localFile = downloadedFiles[index];
        if (localFile != null) {
          final file = File(localFile);
          if (await file.exists()) {
            validIndices.add(index);
            validFiles[index] = localFile;
          }
        }
      }

      // Mettre à jour les listes avec seulement les fichiers valides
      if (validIndices.length != downloadedIndices.length) {
        final validIndicesList = validIndices.map((e) => e.toString()).toList();
        await prefs.setStringList(
          'downloaded_episodes_${source['name']}',
          validIndicesList,
        );

        final validFilesJson = jsonEncode(
          validFiles.map((key, value) => MapEntry(key.toString(), value)),
        );
        await prefs.setString(
          'downloaded_files_${source['name']}',
          validFilesJson,
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && !_isDragging) {
        setState(() {});
      }
    });
  }

  void _showAndAutoHideUI() {
    setState(() {
      _showUI = true;
    });
    _startUITimer(4); // 4 secondes pour les clics sur l'écran
  }

  void _showUIWithShortTimer() {
    setState(() {
      _showUI = true;
    });
    _startUITimer(1); // 1 seconde pour le bouton play
  }

  void _hideUI() {
    setState(() {
      _showUI = false;
    });
  }

  void _startUITimer(int seconds) {
    _uiTimer?.cancel();
    if (_controller.value.isPlaying) {
      _uiTimer = Timer(Duration(seconds: seconds), () {
        if (mounted && _controller.value.isPlaying) {
          _hideUI();
        }
      });
    }
  }

  @override
  void dispose() {
    // Restaurer l'affichage de la barre de statut et de navigation
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    _timer?.cancel();
    _uiTimer?.cancel();
    _controller.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showUnlockModal() {
    _codeController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Code de déverrouillage',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Entrez le code à 4 chiffres',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                onSubmitted: (value) => _validateCode(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: _validateCode,
              child: const Text(
                'Déverrouiller',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _validateCode() {
    if (_codeController.text == _unlockCode) {
      setState(() {
        _isLocked = false;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lecteur déverrouillé !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code incorrect !'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      _codeController.clear();
    }
  }

  void _openSettings() async {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Déverrouillez d\'abord le lecteur pour accéder aux paramètres',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(onCodeChanged: _saveUnlockCode),
      ),
    );

    // Recharger les épisodes téléchargés après être revenu des paramètres
    await _loadDownloadedEpisodes();
  }

  void _selectEpisode() {
    if (_downloadedEpisodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aucun épisode téléchargé trouvé (${_downloadedEpisodes.length}). Allez dans les paramètres pour télécharger des vidéos.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 20),
              ),
              // Title
              const Text(
                'Sélectionner un épisode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Episodes list
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _downloadedEpisodes.length,
                  itemBuilder: (context, index) {
                    final episode = _downloadedEpisodes[index];
                    final isSelected =
                        _currentEpisode != null &&
                        _currentEpisode!['url'] == episode['url'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 60,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<String?>(
                              future: _getThumbnailForEpisode(episode),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  );
                                }

                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.file(
                                    File(snapshot.data!),
                                    width: 60,
                                    height: 45,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.video_file,
                                        color: Colors.white70,
                                        size: 24,
                                      );
                                    },
                                  );
                                }

                                return const Icon(
                                  Icons.video_file,
                                  color: Colors.white70,
                                  size: 24,
                                );
                              },
                            ),
                          ),
                        ),
                        title: Text(
                          episode['episodeName'] ?? 'Épisode ${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          episode['sourceName'] ?? 'Source inconnue',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.red,
                                size: 24,
                              )
                            : null,
                        onTap: () {
                          _playEpisode(episode);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _playEpisode(Map<String, dynamic> episode) {
    _controller.dispose();

    final url = episode['url'] as String;
    final isLocalFile = episode['localFile'] == true;

    if (isLocalFile) {
      _controller = VideoPlayerController.file(File(url));
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);

    setState(() {
      _currentSource = episode['source'];
      _currentEpisode = episode['episode'];
    });
  }

  void _playNextEpisode() {
    if (_downloadedEpisodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun épisode téléchargé disponible'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Trouver l'index de l'épisode actuel
    int currentIndex = -1;
    for (int i = 0; i < _downloadedEpisodes.length; i++) {
      final episode = _downloadedEpisodes[i];
      if (_currentEpisode != null &&
          episode['episodeName'] == _currentEpisode!['name'] &&
          episode['sourceName'] == _currentSource?['name']) {
        currentIndex = i;
        break;
      }
    }

    // Passer à l'épisode suivant
    int nextIndex;
    if (currentIndex == -1 || currentIndex == _downloadedEpisodes.length - 1) {
      // Si pas d'épisode actuel ou dernier épisode, commencer par le premier
      nextIndex = 0;
    } else {
      // Sinon, passer au suivant
      nextIndex = currentIndex + 1;
    }

    final nextEpisode = _downloadedEpisodes[nextIndex];
    _playEpisode(nextEpisode);
  }

  Future<String?> _getThumbnailForEpisode(Map<String, dynamic> episode) async {
    try {
      final sourceName = episode['sourceName'] as String;
      final episodeName = episode['episodeName'] as String;
      final url = episode['url'] as String;

      // Chercher dans les miniatures sauvegardées
      final prefs = await SharedPreferences.getInstance();
      final thumbnailsJson = prefs.getString('thumbnails_$sourceName');

      if (thumbnailsJson != null) {
        final Map<String, dynamic> thumbnailsMap = jsonDecode(thumbnailsJson);
        final thumbnails = thumbnailsMap.map(
          (key, value) => MapEntry(int.parse(key), value as String),
        );

        // Chercher la miniature correspondante par nom d'épisode
        for (final entry in thumbnails.entries) {
          final thumbnailPath = entry.value;
          final file = File(thumbnailPath);
          if (await file.exists()) {
            // Vérifier si le nom du fichier contient le nom de l'épisode
            if (thumbnailPath.contains(
              episodeName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_'),
            )) {
              return thumbnailPath;
            }
          }
        }
      }

      // Si pas de miniature trouvée, essayer de la générer depuis le fichier local
      if (url.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        final thumbnailPath = '${directory.path}/thumbnails';
        final thumbnailDir = Directory(thumbnailPath);
        if (!await thumbnailDir.exists()) {
          await thumbnailDir.create(recursive: true);
        }

        final safeName = episodeName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final thumbnailFileName = 'thumbnail_${sourceName}_$safeName.jpg';
        final thumbnailFilePath = '$thumbnailPath/$thumbnailFileName';

        // Vérifier si la miniature existe déjà
        final existingThumbnail = File(thumbnailFilePath);
        if (await existingThumbnail.exists()) {
          return thumbnailFilePath;
        }

        // Générer la nouvelle miniature
        final thumbnail = await VideoThumbnail.thumbnailFile(
          video: url,
          thumbnailPath: thumbnailPath,
          imageFormat: ImageFormat.JPEG,
          quality: 75,
          maxWidth: 200,
          maxHeight: 150,
          timeMs: 1000,
        );

        if (thumbnail != null) {
          // Renommer le fichier généré avec un nom plus descriptif
          final generatedFile = File(thumbnail);
          if (await generatedFile.exists()) {
            await generatedFile.rename(thumbnailFilePath);
            return thumbnailFilePath;
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération de la miniature: $e');
    }

    return null;
  }

  double _getTopPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final orientation = mediaQuery.orientation;

    // En mode paysage, on utilise un padding plus petit
    if (orientation == Orientation.landscape) {
      // En paysage, on peut utiliser un padding plus minimal
      return 16;
    } else {
      // En mode portrait, on utilise le padding standard
      return mediaQuery.padding.top;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }
          return GestureDetector(
            onTap: () {
              if (_controller.value.isPlaying) {
                if (_showUI) {
                  // Si l'UI est déjà visible, la faire disparaître immédiatement
                  _hideUI();
                  _uiTimer?.cancel();
                } else {
                  // Si l'UI n'est pas visible, l'afficher
                  _showAndAutoHideUI();
                }
              }
            },
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  // Vidéo
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  // Titre et bouton paramètres avec padding adaptatif
                  Positioned(
                    top: _getTopPadding(context),
                    left: 16,
                    right: 16,
                    child: AnimatedOpacity(
                      opacity: (_showUI || !_controller.value.isPlaying)
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48), // Espace pour équilibrer
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentEpisode != null
                                        ? _currentEpisode!['name'] ?? 'Épisode'
                                        : 'Aucun épisode sélectionné',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_currentSource != null)
                                    Text(
                                      _currentSource!['name'] ?? 'Source',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.video_library,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _selectEpisode,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _openSettings,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Contrôles centraux
                  AnimatedOpacity(
                    opacity: (_showUI || !_controller.value.isPlaying)
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 64,
                          ),
                          iconSize: 64,
                          onPressed: () {
                            setState(() {
                              if (_isLocked) return;
                              if (_currentEpisode == null) {
                                _selectEpisode();
                                return;
                              }

                              if (_controller.value.isPlaying) {
                                _controller.pause();
                                _showUIWithShortTimer();
                              } else {
                                _controller.play();
                                _showUIWithShortTimer();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 16,
                    child: AnimatedOpacity(
                      opacity: (_showUI || !_controller.value.isPlaying)
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                // Temps actuel
                                Text(
                                  _controller.value.isInitialized
                                      ? _formatDuration(
                                          _controller.value.position,
                                        )
                                      : '0:00',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Curseur rouge
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.red,
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: Colors.red,
                                      overlayColor: Colors.red.withValues(
                                        alpha: 0.2,
                                      ),
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 10,
                                      ),
                                    ),
                                    child: Slider(
                                      value: _controller.value.isInitialized
                                          ? _controller
                                                .value
                                                .position
                                                .inMilliseconds
                                                .toDouble()
                                          : 0.0,
                                      min: 0.0,
                                      max: _controller.value.isInitialized
                                          ? _controller
                                                .value
                                                .duration
                                                .inMilliseconds
                                                .toDouble()
                                          : 1.0,
                                      onChanged: (value) {
                                        setState(() {
                                          _isDragging = true;
                                        });
                                      },
                                      onChangeEnd: (value) {
                                        _controller.seekTo(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                        setState(() {
                                          _isDragging = false;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Temps total
                                Text(
                                  _controller.value.isInitialized
                                      ? _formatDuration(
                                          _controller.value.duration,
                                        )
                                      : '0:00',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _netflixAction(
                                  _isLocked ? Icons.lock : Icons.lock_open,
                                  _isLocked ? 'Vérouiller' : 'Dévérouiller',
                                  () {
                                    if (_isLocked) {
                                      _showUnlockModal();
                                    } else {
                                      setState(() {
                                        _isLocked = true;
                                      });
                                    }
                                  },
                                ),
                                _netflixAction(Icons.skip_next, 'Suivant', () {
                                  if (_isLocked) return;
                                  _playNextEpisode();
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _netflixAction(IconData icon, String label, VoidCallback action) {
    return SizedBox(
      width: 128,
      child: GestureDetector(
        onTap: action,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final Function(String) onCodeChanged;

  const SettingsScreen({super.key, required this.onCodeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, dynamic>> _sources = [];
  Timer? _urlCheckTimer;
  bool _isCheckingUrl = false;
  bool _isUrlValid = false;
  String _urlCheckMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  @override
  void dispose() {
    _urlCheckTimer?.cancel();
    super.dispose();
  }

  void _onUrlChanged(String url, Function setDialogState) {
    _urlCheckTimer?.cancel();
    _urlCheckTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUrl(url, setDialogState);
    });
  }

  Future<void> _checkUrl(String url, [Function? setDialogState]) async {
    if (url.isEmpty) {
      if (setDialogState != null) {
        setDialogState(() {
          _isCheckingUrl = false;
          _isUrlValid = false;
          _urlCheckMessage = '';
        });
      } else {
        setState(() {
          _isCheckingUrl = false;
          _isUrlValid = false;
          _urlCheckMessage = '';
        });
      }
      return;
    }

    if (setDialogState != null) {
      setDialogState(() {
        _isCheckingUrl = true;
        _isUrlValid = false;
        _urlCheckMessage = 'Vérification en cours...';
      });
    } else {
      setState(() {
        _isCheckingUrl = true;
        _isUrlValid = false;
        _urlCheckMessage = 'Vérification en cours...';
      });
    }

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; KidsVideoPlayer/1.0)',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        // Vérifier si c'est du JSON
        if (contentType.contains('application/json') ||
            response.body.trim().startsWith('{')) {
          try {
            final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

            // Vérifier la structure attendue
            if (jsonData.containsKey('name') &&
                jsonData.containsKey('data') &&
                jsonData['data'] is List) {
              final dataList = jsonData['data'] as List;
              if (dataList.isNotEmpty) {
                // Vérifier que chaque élément de data a name et url
                bool isValidFormat = true;
                for (var item in dataList) {
                  if (item is Map<String, dynamic>) {
                    if (!item.containsKey('name') || !item.containsKey('url')) {
                      isValidFormat = false;
                      break;
                    }
                  } else {
                    isValidFormat = false;
                    break;
                  }
                }

                if (isValidFormat) {
                  if (setDialogState != null) {
                    setDialogState(() {
                      _isCheckingUrl = false;
                      _isUrlValid = true;
                      _urlCheckMessage =
                          'Source valide - ${dataList.length} épisode(s) détecté(s)';
                    });
                  } else {
                    setState(() {
                      _isCheckingUrl = false;
                      _isUrlValid = true;
                      _urlCheckMessage =
                          'Source valide - ${dataList.length} épisode(s) détecté(s)';
                    });
                  }
                } else {
                  if (setDialogState != null) {
                    setDialogState(() {
                      _isCheckingUrl = false;
                      _isUrlValid = false;
                      _urlCheckMessage =
                          'Format JSON invalide - Structure attendue: {name, data: [{name, url}]}';
                    });
                  } else {
                    setState(() {
                      _isCheckingUrl = false;
                      _isUrlValid = false;
                      _urlCheckMessage =
                          'Format JSON invalide - Structure attendue: {name, data: [{name, url}]}';
                    });
                  }
                }
              } else {
                if (setDialogState != null) {
                  setDialogState(() {
                    _isCheckingUrl = false;
                    _isUrlValid = false;
                    _urlCheckMessage = 'Source vide - Aucun épisode trouvé';
                  });
                } else {
                  setState(() {
                    _isCheckingUrl = false;
                    _isUrlValid = false;
                    _urlCheckMessage = 'Source vide - Aucun épisode trouvé';
                  });
                }
              }
            } else {
              if (setDialogState != null) {
                setDialogState(() {
                  _isCheckingUrl = false;
                  _isUrlValid = false;
                  _urlCheckMessage =
                      'Format JSON invalide - Champs "name" et "data" requis';
                });
              } else {
                setState(() {
                  _isCheckingUrl = false;
                  _isUrlValid = false;
                  _urlCheckMessage =
                      'Format JSON invalide - Champs "name" et "data" requis';
                });
              }
            }
          } catch (e) {
            if (setDialogState != null) {
              setDialogState(() {
                _isCheckingUrl = false;
                _isUrlValid = false;
                _urlCheckMessage = 'JSON invalide - Erreur de parsing';
              });
            } else {
              setState(() {
                _isCheckingUrl = false;
                _isUrlValid = false;
                _urlCheckMessage = 'JSON invalide - Erreur de parsing';
              });
            }
          }
        } else {
          if (setDialogState != null) {
            setDialogState(() {
              _isCheckingUrl = false;
              _isUrlValid = false;
              _urlCheckMessage = 'Format non supporté - JSON requis';
            });
          } else {
            setState(() {
              _isCheckingUrl = false;
              _isUrlValid = false;
              _urlCheckMessage = 'Format non supporté - JSON requis';
            });
          }
        }
      } else {
        if (setDialogState != null) {
          setDialogState(() {
            _isCheckingUrl = false;
            _isUrlValid = false;
            _urlCheckMessage = 'Erreur HTTP: ${response.statusCode}';
          });
        } else {
          setState(() {
            _isCheckingUrl = false;
            _isUrlValid = false;
            _urlCheckMessage = 'Erreur HTTP: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (setDialogState != null) {
        setDialogState(() {
          _isCheckingUrl = false;
          _isUrlValid = false;
          _urlCheckMessage = 'Impossible d\'accéder à l\'URL';
        });
      } else {
        setState(() {
          _isCheckingUrl = false;
          _isUrlValid = false;
          _urlCheckMessage = 'Impossible d\'accéder à l\'URL';
        });
      }
    }
  }

  Future<void> _loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    final sourcesJson = prefs.getStringList('video_sources') ?? [];
    setState(() {
      _sources = sourcesJson.map((json) {
        final Map<String, dynamic> source = Map<String, dynamic>.from(
          jsonDecode(json) as Map,
        );
        return source;
      }).toList();
    });
  }

  Future<void> _saveSources() async {
    final prefs = await SharedPreferences.getInstance();
    final sourcesJson = _sources.map((source) => jsonEncode(source)).toList();
    await prefs.setStringList('video_sources', sourcesJson);
  }

  void _addSource() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController urlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                  ),
                  // Title
                  const Text(
                    'Ajouter une source',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Form fields
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Nom de la source',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'URL de la source',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isUrlValid ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _isCheckingUrl
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : _isUrlValid
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : urlController.text.isNotEmpty
                          ? const Icon(Icons.error, color: Colors.red)
                          : null,
                    ),
                    onChanged: (value) {
                      _onUrlChanged(value, setDialogState);
                    },
                  ),
                  // URL check message
                  if (_urlCheckMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isUrlValid
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isUrlValid
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isUrlValid ? Icons.check_circle : Icons.info,
                            color: _isUrlValid ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _urlCheckMessage,
                              style: TextStyle(
                                color: _isUrlValid ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (nameController.text.isNotEmpty &&
                                  urlController.text.isNotEmpty &&
                                  _isUrlValid)
                              ? () {
                                  setState(() {
                                    _sources.add({
                                      'name': nameController.text,
                                      'url': urlController.text,
                                    });
                                  });
                                  _saveSources();
                                  Navigator.of(context).pop();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Ajouter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _removeSource(int index) {
    setState(() {
      _sources.removeAt(index);
    });
    _saveSources();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Sources', [
            ..._sources.asMap().entries.map((entry) {
              final index = entry.key;
              final source = entry.value;
              return ListTile(
                leading: const Icon(Icons.link, color: Colors.white),
                title: Text(
                  source['name'] ?? 'Source ${index + 1}',
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  source['url'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.video_library,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                VideoSelectionScreen(source: source),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeSource(index),
                    ),
                  ],
                ),
              );
            }),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.white),
              title: const Text(
                'Ajouter une source',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Scanner une URL pour les épisodes',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: _addSource,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Sécurité', [
            _buildActionTile(
              'Changer le code de verrouillage',
              'Modifier le code à 4 chiffres',
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangeCodeScreen(onCodeChanged: widget.onCodeChanged),
                  ),
                );
              },
              Icons.lock,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    VoidCallback onTap,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
      onTap: onTap,
    );
  }
}

class ChangeCodeScreen extends StatefulWidget {
  final Function(String) onCodeChanged;

  const ChangeCodeScreen({super.key, required this.onCodeChanged});

  @override
  State<ChangeCodeScreen> createState() => _ChangeCodeScreenState();
}

class _ChangeCodeScreenState extends State<ChangeCodeScreen> {
  final TextEditingController _currentCodeController = TextEditingController();
  final TextEditingController _newCodeController = TextEditingController();
  final TextEditingController _confirmCodeController = TextEditingController();
  String _currentCode = "1234";

  @override
  void initState() {
    super.initState();
    _loadCurrentCode();
  }

  Future<void> _loadCurrentCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentCode = prefs.getString('unlock_code') ?? "1234";
    });
  }

  @override
  void dispose() {
    _currentCodeController.dispose();
    _newCodeController.dispose();
    _confirmCodeController.dispose();
    super.dispose();
  }

  void _changeCode() {
    // Vérifier le code actuel
    if (_currentCodeController.text != _currentCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code actuel incorrect !'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Vérifier que le nouveau code fait 4 chiffres
    if (_newCodeController.text.length != 4 ||
        !RegExp(r'^\d{4}$').hasMatch(_newCodeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le nouveau code doit contenir exactement 4 chiffres !',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Vérifier la confirmation
    if (_newCodeController.text != _confirmCodeController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les codes ne correspondent pas !'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Sauvegarder le nouveau code
    widget.onCodeChanged(_newCodeController.text);

    // Fermer l'écran
    Navigator.of(context).pop();

    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code modifié avec succès !'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Changer le code',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Code actuel
            TextField(
              controller: _currentCodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'Code actuel',
                labelStyle: TextStyle(color: Colors.white70),
                counterText: "",
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Nouveau code
            TextField(
              controller: _newCodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'Nouveau code',
                labelStyle: TextStyle(color: Colors.white70),
                counterText: "",
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Confirmation du nouveau code
            TextField(
              controller: _confirmCodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'Confirmer le nouveau code',
                labelStyle: TextStyle(color: Colors.white70),
                counterText: "",
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Bouton de validation
            ElevatedButton(
              onPressed: _changeCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Changer le code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Informations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Le code doit contenir exactement 4 chiffres',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // Espace supplémentaire en bas
          ],
        ),
      ),
    );
  }
}

class VideoSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> source;

  const VideoSelectionScreen({super.key, required this.source});

  @override
  State<VideoSelectionScreen> createState() => _VideoSelectionScreenState();
}

class _VideoSelectionScreenState extends State<VideoSelectionScreen> {
  List<Map<String, dynamic>> _episodes = [];
  bool _isLoading = true;
  bool _isDownloadingAll = false;
  final Set<int> _downloadingEpisodes = {};
  Set<int> _downloadedEpisodes = {};
  Map<int, String> _thumbnails = {};
  final Map<int, bool> _generatingThumbnails = {};
  Map<int, String> _downloadedFiles = {};
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
    _loadDownloadedEpisodes();
    _loadThumbnails();
    _loadDownloadedFiles();
  }

  Future<void> _loadEpisodes() async {
    try {
      final response = await http
          .get(
            Uri.parse(widget.source['url']),
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; KidsVideoPlayer/1.0)',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = jsonData['data'] as List;

        setState(() {
          _episodes = dataList.map((item) {
            return Map<String, dynamic>.from(item as Map);
          }).toList();
          _isLoading = false;
        });

        // Générer les miniatures pour les premiers épisodes
        for (int i = 0; i < _episodes.length && i < 5; i++) {
          _generateThumbnail(i);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Erreur lors du chargement des épisodes');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Impossible de charger les épisodes');
    }
  }

  Future<void> _loadDownloadedEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedJson =
        prefs.getStringList('downloaded_episodes_${widget.source['name']}') ??
        [];
    setState(() {
      _downloadedEpisodes = downloadedJson.map((e) => int.parse(e)).toSet();
    });
  }

  Future<void> _saveDownloadedEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedJson = _downloadedEpisodes
        .map((e) => e.toString())
        .toList();
    await prefs.setStringList(
      'downloaded_episodes_${widget.source['name']}',
      downloadedJson,
    );

    // Sauvegarder aussi les métadonnées des épisodes téléchargés
    final Map<String, dynamic> episodesMetadata = {};
    for (final index in _downloadedEpisodes) {
      if (index < _episodes.length) {
        episodesMetadata[index.toString()] = _episodes[index];
      }
    }
    final metadataJson = jsonEncode(episodesMetadata);
    await prefs.setString(
      'episodes_metadata_${widget.source['name']}',
      metadataJson,
    );
  }

  Future<void> _loadThumbnails() async {
    final prefs = await SharedPreferences.getInstance();
    final thumbnailsJson = prefs.getString(
      'thumbnails_${widget.source['name']}',
    );
    if (thumbnailsJson != null) {
      final Map<String, dynamic> thumbnailsMap = jsonDecode(thumbnailsJson);
      setState(() {
        _thumbnails = thumbnailsMap.map(
          (key, value) => MapEntry(int.parse(key), value as String),
        );
      });
    }
  }

  Future<void> _saveThumbnails() async {
    final prefs = await SharedPreferences.getInstance();
    final thumbnailsJson = jsonEncode(
      _thumbnails.map((key, value) => MapEntry(key.toString(), value)),
    );
    await prefs.setString(
      'thumbnails_${widget.source['name']}',
      thumbnailsJson,
    );
  }

  Future<void> _loadDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final filesJson = prefs.getString(
      'downloaded_files_${widget.source['name']}',
    );
    if (filesJson != null) {
      final Map<String, dynamic> filesMap = jsonDecode(filesJson);
      setState(() {
        _downloadedFiles = filesMap.map(
          (key, value) => MapEntry(int.parse(key), value as String),
        );
      });
    }
  }

  Future<void> _saveDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final filesJson = jsonEncode(
      _downloadedFiles.map((key, value) => MapEntry(key.toString(), value)),
    );
    await prefs.setString(
      'downloaded_files_${widget.source['name']}',
      filesJson,
    );
  }

  Future<void> _generateThumbnail(int index) async {
    if (_generatingThumbnails[index] == true ||
        _thumbnails.containsKey(index)) {
      return;
    }
    setState(() {
      _generatingThumbnails[index] = true;
    });

    try {
      final episode = _episodes[index];
      final url = episode['url'] as String;

      final directory = await getApplicationDocumentsDirectory();
      final thumbnailPath = '${directory.path}/thumbnails';
      final thumbnailDir = Directory(thumbnailPath);
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: url,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
        maxWidth: 200,
        maxHeight: 150,
        timeMs: 1000, // Prendre la miniature à 1 seconde
      );

      if (thumbnail != null) {
        setState(() {
          _thumbnails[index] = thumbnail;
          _generatingThumbnails[index] = false;
        });
        await _saveThumbnails();
      } else {
        setState(() {
          _generatingThumbnails[index] = false;
        });
      }
    } catch (e) {
      setState(() {
        _generatingThumbnails[index] = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadEpisode(int index) async {
    if (_downloadingEpisodes.contains(index)) return;

    setState(() {
      _downloadingEpisodes.add(index);
    });

    try {
      final episode = _episodes[index];
      final url = episode['url'] as String;
      final name = episode['name'] as String;

      // Créer le dossier de téléchargement
      final directory = await getApplicationDocumentsDirectory();
      final downloadPath = '${directory.path}/videos';
      final downloadDir = Directory(downloadPath);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Nom du fichier local
      final fileName =
          '${widget.source['name']}_${index}_${name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.mp4';
      final filePath = '$downloadPath/$fileName';

      // Télécharger le fichier
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).round();
            print('Progression: $progress%');
            // Ici on pourrait afficher la progression si nécessaire
          }
        },
      );

      // Vérifier que le fichier existe
      final file = File(filePath);
      if (await file.exists()) {
        setState(() {
          _downloadedEpisodes.add(index);
          _downloadedFiles[index] = filePath;
          _downloadingEpisodes.remove(index);
        });

        await _saveDownloadedEpisodes();
        await _saveDownloadedFiles();

        _showSuccess('Épisode "$name" téléchargé !');
      } else {
        throw Exception('Fichier non créé');
      }
    } catch (e) {
      setState(() {
        _downloadingEpisodes.remove(index);
      });
      _showError('Erreur lors du téléchargement: ${e.toString()}');
    }
  }

  Future<void> _downloadAllEpisodes() async {
    if (_isDownloadingAll) return;

    setState(() {
      _isDownloadingAll = true;
    });

    try {
      for (int i = 0; i < _episodes.length; i++) {
        if (!_downloadedEpisodes.contains(i)) {
          await _downloadEpisode(i);
          // Petit délai entre les téléchargements
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      setState(() {
        _isDownloadingAll = false;
      });

      _showSuccess('Tous les épisodes ont été téléchargés !');
    } catch (e) {
      setState(() {
        _isDownloadingAll = false;
      });
      _showError('Erreur lors du téléchargement de tous les épisodes');
    }
  }

  void _deleteEpisode(int index) async {
    try {
      // Supprimer le fichier local
      if (_downloadedFiles.containsKey(index)) {
        final file = File(_downloadedFiles[index]!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _downloadedEpisodes.remove(index);
        _downloadedFiles.remove(index);
      });

      await _saveDownloadedEpisodes();
      await _saveDownloadedFiles();
      _showSuccess('Épisode supprimé');
    } catch (e) {
      _showError('Erreur lors de la suppression: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          widget.source['name'] ?? 'Sélection vidéos',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isLoading && _episodes.isNotEmpty)
            IconButton(
              icon: Icon(
                _isDownloadingAll ? Icons.stop : Icons.download,
                color: Colors.white,
              ),
              onPressed: _isDownloadingAll ? null : _downloadAllEpisodes,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _episodes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    color: Colors.grey[600],
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun épisode trouvé',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _episodes.length,
              itemBuilder: (context, index) {
                // Générer la miniature si elle n'existe pas encore
                if (!_thumbnails.containsKey(index) &&
                    _generatingThumbnails[index] != true) {
                  _generateThumbnail(index);
                }
                final episode = _episodes[index];
                final name =
                    episode['name'] as String? ?? 'Épisode ${index + 1}';
                final url = episode['url'] as String? ?? '';
                final isDownloaded = _downloadedEpisodes.contains(index);
                final isDownloading = _downloadingEpisodes.contains(index);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDownloaded ? Colors.green : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _generatingThumbnails[index] == true
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : _thumbnails.containsKey(index)
                            ? Image.file(
                                File(_thumbnails[index]!),
                                width: 80,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    isDownloaded
                                        ? Icons.check_circle
                                        : Icons.video_file,
                                    color: isDownloaded
                                        ? Colors.green
                                        : Colors.white70,
                                    size: 32,
                                  );
                                },
                              )
                            : Icon(
                                isDownloaded
                                    ? Icons.check_circle
                                    : Icons.video_file,
                                color: isDownloaded
                                    ? Colors.green
                                    : Colors.white70,
                                size: 32,
                              ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            url,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDownloaded)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '✓',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDownloading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                            ),
                          )
                        else if (isDownloaded)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEpisode(index),
                          )
                        else
                          IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                            onPressed: () => _downloadEpisode(index),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
