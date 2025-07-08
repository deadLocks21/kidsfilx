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
  bool _shuffleEpisodes = false;

  @override
  void initState() {
    super.initState();
    // Masquer complètement la barre de statut et la barre de navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Configuration supplémentaire pour masquer l'heure et les notifications
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Initialiser avec un contrôleur vide
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://timothe.hofmann.fr/tchoupi.mp4'),
    );
    _initializeVideoPlayerFuture =
        Future.value(); // Pas d'initialisation automatique
    _controller.setLooping(true);
    _startTimer();
    _loadUnlockCode();
    _initAsync();
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

  Future<bool> _loadAutoLoadOption() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('auto_load_first_episode') ?? false;
    return value;
  }

  Future<void> _checkAndAutoLoadEpisode(bool autoLoad) async {
    // Attendre que les épisodes soient chargés
    await _loadDownloadedEpisodes();
    // Vérifier l'option d'auto-chargement
    if (autoLoad && _downloadedEpisodes.isNotEmpty) {
      _playEpisode(_downloadedEpisodes.first);
    }
  }

  Future<void> _initAsync() async {
    await _loadSources();
    await _loadShuffleOption();
    final autoLoad = await _loadAutoLoadOption();
    await _checkAndAutoLoadEpisode(autoLoad);
  }

  Future<void> _loadShuffleOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shuffleEpisodes = prefs.getBool('shuffle_episodes') ?? false;
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

    // Appliquer le mélange si l'option est activée
    if (_shuffleEpisodes && _downloadedEpisodes.isNotEmpty) {
      _downloadedEpisodes.shuffle();
      setState(() {});
    }

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

    // Restaurer le style par défaut de l'interface système
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
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
        builder: (context) => SettingsScreen(
          onCodeChanged: _saveUnlockCode,
          onShuffleChanged: (bool value) async {
            setState(() {
              _shuffleEpisodes = value;
            });
            if (value) {
              if (_downloadedEpisodes.isNotEmpty) {
                _downloadedEpisodes.shuffle();
                setState(() {});
              }
            } else {
              await _loadDownloadedEpisodes();
            }
          },
        ),
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
            'Aucun épisode téléchargé. Allez dans les paramètres pour télécharger des vidéos.',
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
                        _currentSource != null &&
                        episode['episodeName'] == _currentEpisode!['name'] &&
                        episode['sourceName'] == _currentSource!['name'];

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
      _showError('Erreur lors de la récupération de la miniature: $e');
    }

    return null;
  }

  double _getTopPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final orientation = mediaQuery.orientation;

    // En mode paysage, on utilise un padding plus petit
    if (orientation == Orientation.landscape) {
      // En paysage, on peut utiliser un padding plus minimal
      return 0;
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
                  // Titre avec padding adaptatif
                  Positioned(
                    top: _getTopPadding(context),
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: (_showUI || !_controller.value.isPlaying)
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromARGB(180, 0, 0, 0),
                              Color.fromARGB(100, 0, 0, 0),
                              Color.fromARGB(0, 0, 0, 0),
                            ],
                            stops: [0.0, 0.7, 1.0],
                          ),
                        ),
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 16,
                        ),
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
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: (_showUI || !_controller.value.isPlaying)
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color.fromARGB(180, 0, 0, 0),
                              Color.fromARGB(100, 0, 0, 0),
                              Color.fromARGB(0, 0, 0, 0),
                            ],
                            stops: [0.0, 0.7, 1.0],
                          ),
                        ),
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 16,
                          bottom: 16,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                                            Duration(
                                              milliseconds: value.toInt(),
                                            ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _netflixAction(
                                    Icons.video_library,
                                    'Épisodes',
                                    () {
                                      if (_isLocked) return;
                                      _selectEpisode();
                                    },
                                  ),
                                  _netflixAction(
                                    Icons.settings,
                                    'Paramètres',
                                    () {
                                      if (_isLocked) return;
                                      _openSettings();
                                    },
                                  ),
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
                                  _netflixAction(
                                    Icons.skip_next,
                                    'Suivant',
                                    () {
                                      if (_isLocked) return;
                                      _playNextEpisode();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
      width: 92,
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
  final Function(bool) onShuffleChanged;

  const SettingsScreen({
    super.key,
    required this.onCodeChanged,
    required this.onShuffleChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, dynamic>> _sources = [];
  Timer? _urlCheckTimer;
  bool _isCheckingUrl = false;
  bool _isUrlValid = false;
  String _urlCheckMessage = '';

  // Ajout : option Lecture
  bool _autoLoadFirstEpisode = false;
  bool _shuffleEpisodes = false;

  @override
  void initState() {
    super.initState();
    _loadSources();
    _loadShuffleOption();
    _loadAutoLoadOption();
  }

  @override
  void dispose() {
    _urlCheckTimer?.cancel();
    super.dispose();
  }

  void _onUrlChanged(
    String url,
    Function setDialogState,
    Function(String?) onSourceNameDetected,
  ) {
    _urlCheckTimer?.cancel();
    _urlCheckTimer = Timer(const Duration(milliseconds: 500), () async {
      final sourceName = await _checkUrl(url, setDialogState);
      onSourceNameDetected(sourceName);
    });
  }

  Future<String?> _checkUrl(String url, [Function? setDialogState]) async {
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
      return null;
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
              final sourceName = jsonData['name'] as String?;

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
                  return sourceName;
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
    return null;
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

  Future<bool> _loadAutoLoadOption() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('auto_load_first_episode') ?? false;
    setState(() {
      _autoLoadFirstEpisode = value;
    });
    return value;
  }

  Future<void> _saveAutoLoadOption(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_load_first_episode', value);
    setState(() {
      _autoLoadFirstEpisode = value;
    });
  }

  Future<void> _loadShuffleOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shuffleEpisodes = prefs.getBool('shuffle_episodes') ?? false;
    });
  }

  Future<void> _saveShuffleOption(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shuffle_episodes', value);
    setState(() {
      _shuffleEpisodes = value;
    });
    widget.onShuffleChanged(value);
  }

  Future<void> _saveSources() async {
    final prefs = await SharedPreferences.getInstance();
    final sourcesJson = _sources.map((source) => jsonEncode(source)).toList();
    await prefs.setStringList('video_sources', sourcesJson);
  }

  void _addSource() {
    final TextEditingController urlController = TextEditingController();
    String? detectedSourceName;

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
                    controller: urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'URL de la source JSON',
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
                      _onUrlChanged(value, setDialogState, (sourceName) {
                        detectedSourceName = sourceName;
                      });
                    },
                  ),
                  // Source name display
                  if (detectedSourceName != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nom détecté: $detectedSourceName',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                              (urlController.text.isNotEmpty &&
                                  _isUrlValid &&
                                  detectedSourceName != null)
                              ? () {
                                  setState(() {
                                    _sources.add({
                                      'name': detectedSourceName!,
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _removeSource(int index) async {
    final source = _sources[index];
    final sourceName = source['name'] as String?;

    if (sourceName != null) {
      // Supprimer tous les fichiers téléchargés pour cette source
      await _deleteAllEpisodesForSource(sourceName);

      // Supprimer toutes les données associées à cette source
      await _deleteSourceData(sourceName);
    }

    setState(() {
      _sources.removeAt(index);
    });
    _saveSources();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Source "$sourceName" et tous ses épisodes supprimés'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteAllEpisodesForSource(String sourceName) async {
    try {
      // Récupérer la liste des fichiers téléchargés pour cette source
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getString('downloaded_files_$sourceName');

      if (filesJson != null) {
        final Map<String, dynamic> filesMap = jsonDecode(filesJson);
        final downloadedFiles = filesMap.map(
          (key, value) => MapEntry(int.parse(key), value as String),
        );

        // Supprimer chaque fichier
        for (final filePath in downloadedFiles.values) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }

        // Supprimer les miniatures
        final thumbnailsJson = prefs.getString('thumbnails_$sourceName');
        if (thumbnailsJson != null) {
          final Map<String, dynamic> thumbnailsMap = jsonDecode(thumbnailsJson);
          final thumbnails = thumbnailsMap.map(
            (key, value) => MapEntry(int.parse(key), value as String),
          );

          for (final thumbnailPath in thumbnails.values) {
            final thumbnailFile = File(thumbnailPath);
            if (await thumbnailFile.exists()) {
              await thumbnailFile.delete();
            }
          }
        }
      }
    } catch (e) {
      _showError('Erreur lors de la suppression des fichiers: $e');
    }
  }

  Future<void> _deleteSourceData(String sourceName) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Supprimer toutes les données associées à cette source
      await prefs.remove('downloaded_episodes_$sourceName');
      await prefs.remove('downloaded_files_$sourceName');
      await prefs.remove('episodes_metadata_$sourceName');
      await prefs.remove('thumbnails_$sourceName');
    } catch (e) {
      _showError('Erreur lors de la suppression des données: $e');
    }
  }

  void _showDeleteConfirmation(int index) {
    final source = _sources[index];
    final sourceName = source['name'] as String? ?? 'Source ${index + 1}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Confirmer la suppression',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Êtes-vous sûr de vouloir supprimer cette source ?',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Source: $sourceName',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette action supprimera également tous les épisodes téléchargés pour cette source. Cette opération est irréversible.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
              onPressed: () {
                Navigator.of(context).pop();
                _removeSource(index);
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
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
          _buildSection('Lecture', [
            SwitchListTile(
              value: _autoLoadFirstEpisode,
              onChanged: (value) => _saveAutoLoadOption(value),
              title: const Text(
                'Charger automatiquement le premier épisode',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Lance le premier épisode téléchargé au démarrage',
                style: TextStyle(color: Colors.white70),
              ),
              activeColor: Colors.red,
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.white24,
            ),
            SwitchListTile(
              value: _shuffleEpisodes,
              onChanged: (value) => _saveShuffleOption(value),
              title: const Text(
                'Mélanger les épisodes au démarrage',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Réorganise aléatoirement la liste des épisodes à chaque lancement',
                style: TextStyle(color: Colors.white70),
              ),
              activeColor: Colors.red,
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.white24,
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
          const SizedBox(height: 24),
          _buildSection('Sources', [
            ListTile(
              leading: const Icon(Icons.add, color: Colors.white),
              title: const Text(
                'Ajouter une source',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Scanner une URL JSON pour les épisodes',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: _addSource,
            ),
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
                      onPressed: () => _showDeleteConfirmation(index),
                    ),
                  ],
                ),
              );
            }),
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
  bool _shouldStopDownload = false;
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

        final onlineEpisodes = dataList.map((item) {
          return Map<String, dynamic>.from(item as Map);
        }).toList();

        // Charger les épisodes téléchargés qui ne sont plus en ligne
        await _loadDownloadedEpisodes();
        await _loadDownloadedFiles();

        // Créer une liste combinée
        final List<Map<String, dynamic>> combinedEpisodes = [];

        // Ajouter d'abord les épisodes en ligne
        for (int i = 0; i < onlineEpisodes.length; i++) {
          final episode = onlineEpisodes[i];
          final isDownloaded = _downloadedEpisodes.contains(i);
          combinedEpisodes.add({
            ...episode,
            'index': i,
            'isOnline': true,
            'isDownloaded': isDownloaded,
          });
        }

        // Ajouter les épisodes téléchargés qui ne sont plus en ligne
        final Set<int> onlineIndices = Set.from(
          Iterable.generate(onlineEpisodes.length),
        );
        for (final downloadedIndex in _downloadedEpisodes) {
          if (!onlineIndices.contains(downloadedIndex)) {
            // Cet épisode est téléchargé mais n'est plus en ligne
            final localFile = _downloadedFiles[downloadedIndex];
            if (localFile != null) {
              final file = File(localFile);
              if (await file.exists()) {
                // Récupérer les métadonnées sauvegardées
                final prefs = await SharedPreferences.getInstance();
                final metadataJson = prefs.getString(
                  'episodes_metadata_${widget.source['name']}',
                );
                if (metadataJson != null) {
                  final Map<String, dynamic> metadataMap = jsonDecode(
                    metadataJson,
                  );
                  final episodeMetadata =
                      metadataMap[downloadedIndex.toString()];
                  if (episodeMetadata != null) {
                    combinedEpisodes.add({
                      ...episodeMetadata,
                      'index': downloadedIndex,
                      'isOnline': false,
                      'isDownloaded': true,
                      'localFile': localFile,
                    });
                  }
                }
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _episodes = combinedEpisodes;
            _isLoading = false;
          });
        }

        // Générer les miniatures pour les premiers épisodes
        for (int i = 0; i < _episodes.length && i < 5; i++) {
          // Utiliser Future.microtask pour éviter l'appel de setState pendant le build
          Future.microtask(() => _generateThumbnail(i));
        }
      } else {
        // Si l'URL n'est plus accessible, charger seulement les épisodes téléchargés
        await _loadOfflineEpisodes();
      }
    } catch (e) {
      // En cas d'erreur, charger seulement les épisodes téléchargés
      await _loadOfflineEpisodes();
    }
  }

  Future<void> _loadOfflineEpisodes() async {
    await _loadDownloadedEpisodes();
    await _loadDownloadedFiles();

    final List<Map<String, dynamic>> offlineEpisodes = [];

    for (final downloadedIndex in _downloadedEpisodes) {
      final localFile = _downloadedFiles[downloadedIndex];
      if (localFile != null) {
        final file = File(localFile);
        if (await file.exists()) {
          // Récupérer les métadonnées sauvegardées
          final prefs = await SharedPreferences.getInstance();
          final metadataJson = prefs.getString(
            'episodes_metadata_${widget.source['name']}',
          );
          if (metadataJson != null) {
            final Map<String, dynamic> metadataMap = jsonDecode(metadataJson);
            final episodeMetadata = metadataMap[downloadedIndex.toString()];
            if (episodeMetadata != null) {
              offlineEpisodes.add({
                ...episodeMetadata,
                'index': downloadedIndex,
                'isOnline': false,
                'isDownloaded': true,
                'localFile': localFile,
              });
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _episodes = offlineEpisodes;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDownloadedEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedJson =
        prefs.getStringList('downloaded_episodes_${widget.source['name']}') ??
        [];
    if (mounted) {
      setState(() {
        _downloadedEpisodes = downloadedJson.map((e) => int.parse(e)).toSet();
      });
    }
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
      if (mounted) {
        setState(() {
          _thumbnails = thumbnailsMap.map(
            (key, value) => MapEntry(int.parse(key), value as String),
          );
        });
      }
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
      if (mounted) {
        setState(() {
          _downloadedFiles = filesMap.map(
            (key, value) => MapEntry(int.parse(key), value as String),
          );
        });
      }
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
    if (mounted) {
      setState(() {
        _generatingThumbnails[index] = true;
      });
    }

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
        if (mounted) {
          setState(() {
            _thumbnails[index] = thumbnail;
            _generatingThumbnails[index] = false;
          });
        }
        await _saveThumbnails();
      } else {
        if (mounted) {
          setState(() {
            _generatingThumbnails[index] = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generatingThumbnails[index] = false;
        });
      }
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

    if (mounted) {
      setState(() {
        _downloadingEpisodes.add(index);
      });
    }

    try {
      // Vérifier si l'arrêt a été demandé avant de commencer
      if (_shouldStopDownload) {
        if (mounted) {
          setState(() {
            _downloadingEpisodes.remove(index);
          });
        }
        return;
      }

      // Trouver l'épisode correspondant dans la liste combinée
      final episode = _episodes.firstWhere(
        (ep) => ep['index'] == index,
        orElse: () => _episodes[index],
      );
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
        onReceiveProgress: (received, total) {},
      );

      // Vérifier si l'arrêt a été demandé après le téléchargement
      if (_shouldStopDownload) {
        // Supprimer le fichier partiellement téléchargé
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        if (mounted) {
          setState(() {
            _downloadingEpisodes.remove(index);
          });
        }
        return;
      }

      // Vérifier que le fichier existe
      final file = File(filePath);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _downloadedEpisodes.add(index);
            _downloadedFiles[index] = filePath;
            _downloadingEpisodes.remove(index);
          });
        }

        await _saveDownloadedEpisodes();
        await _saveDownloadedFiles();
      } else {
        throw Exception('Fichier non créé');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingEpisodes.remove(index);
        });
      }
      _showError('Erreur lors du téléchargement: ${e.toString()}');
    }
  }

  Future<void> _downloadAllEpisodes() async {
    if (_isDownloadingAll) return;

    if (mounted) {
      setState(() {
        _isDownloadingAll = true;
        _shouldStopDownload = false;
      });
    }

    try {
      for (int i = 0; i < _episodes.length; i++) {
        // Vérifier si l'arrêt a été demandé
        if (_shouldStopDownload) {
          break;
        }
        
        if (!_downloadedEpisodes.contains(i)) {
          await _downloadEpisode(i);
          
          // Vérifier à nouveau si l'arrêt a été demandé après chaque téléchargement
          if (_shouldStopDownload) {
            break;
          }
          
          // Petit délai entre les téléchargements
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (mounted) {
        setState(() {
          _isDownloadingAll = false;
          _shouldStopDownload = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloadingAll = false;
          _shouldStopDownload = false;
        });
      }
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

      if (mounted) {
        setState(() {
          _downloadedEpisodes.remove(index);
          _downloadedFiles.remove(index);
        });
      }

      await _saveDownloadedEpisodes();
      await _saveDownloadedFiles();
      _showSuccess('Épisode supprimé');
    } catch (e) {
      _showError('Erreur lors de la suppression: ${e.toString()}');
    }
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Supprimer tous les épisodes',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Êtes-vous sûr de vouloir supprimer tous les épisodes téléchargés ?',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette action supprimera définitivement tous les fichiers téléchargés. Cette opération est irréversible.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllEpisodes();
              },
              child: const Text(
                'Supprimer tout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllEpisodes() async {
    try {
      // Supprimer tous les fichiers téléchargés
      for (final entry in _downloadedFiles.entries) {
        final file = File(entry.value);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Supprimer toutes les miniatures
      for (final thumbnailPath in _thumbnails.values) {
        final thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }

      if (mounted) {
        setState(() {
          _downloadedEpisodes.clear();
          _downloadedFiles.clear();
          _thumbnails.clear();
        });
      }

      await _saveDownloadedEpisodes();
      await _saveDownloadedFiles();
      await _saveThumbnails();

      _showSuccess('Tous les épisodes ont été supprimés');
    } catch (e) {
      _showError('Erreur lors de la suppression: ${e.toString()}');
    }
  }

  void _stopAllDownloads() {
    setState(() {
      _shouldStopDownload = true;
      _isDownloadingAll = false;
    });
    
    // Arrêter tous les téléchargements individuels en cours
    _downloadingEpisodes.clear();
    
    _showSuccess('Arrêt des téléchargements en cours...');
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
          if (!_isLoading && _episodes.isNotEmpty && _downloadedEpisodes.length < _episodes.length)
            IconButton(
              icon: Icon(
                _isDownloadingAll ? Icons.stop : Icons.download,
                color: Colors.white,
              ),
              onPressed: _isDownloadingAll ? _stopAllDownloads : _downloadAllEpisodes,
            ),
          if (_downloadedEpisodes.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep,
                color: Colors.red,
              ),
              onPressed: _showDeleteAllConfirmation,
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
                final episode = _episodes[index];
                final episodeIndex = episode['index'] as int? ?? index;
                final name =
                    episode['name'] as String? ?? 'Épisode ${episodeIndex + 1}';
                final url = episode['url'] as String? ?? '';
                final isOnline = episode['isOnline'] as bool? ?? true;
                final isDownloaded = _downloadedEpisodes.contains(episodeIndex);
                final isDownloading = _downloadingEpisodes.contains(
                  episodeIndex,
                );

                // Générer la miniature si elle n'existe pas encore
                if (!_thumbnails.containsKey(episodeIndex) &&
                    _generatingThumbnails[episodeIndex] != true) {
                  // Utiliser Future.microtask pour éviter l'appel de setState pendant le build
                  Future.microtask(() => _generateThumbnail(episodeIndex));
                }

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
                  child: Stack(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _generatingThumbnails[episodeIndex] == true
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  )
                                : _thumbnails.containsKey(episodeIndex)
                                ? Image.file(
                                    File(_thumbnails[episodeIndex]!),
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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isOnline)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'HORS LIGNE',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
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
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteEpisode(episodeIndex),
                              )
                            else if (isOnline)
                              IconButton(
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                ),
                                onPressed: () => _downloadEpisode(episodeIndex),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
