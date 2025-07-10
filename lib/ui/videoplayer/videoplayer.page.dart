import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kidflix/ui/settings/settings.page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'services/app_lock.service.dart';

class VideoplayerPage extends StatefulWidget {
  const VideoplayerPage({super.key});

  @override
  State<VideoplayerPage> createState() => _VideoplayerPageState();
}

class _VideoplayerPageState extends State<VideoplayerPage> {
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
    _controller.setLooping(false); // Désactiver la boucle
    _controller.addListener(
      _onVideoEnd,
    ); // Ajouter un listener pour détecter la fin
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

  void _onVideoEnd() {
    // Vérifier si la vidéo est terminée
    if (_controller.value.position >= _controller.value.duration &&
        _controller.value.duration > Duration.zero) {
      // Passer à l'épisode suivant et continuer la lecture
      _playNextEpisode();
      // Démarrer la lecture automatiquement après un court délai
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _controller.value.isInitialized) {
          _controller.play();
        }
      });
    }
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
    _controller.removeListener(_onVideoEnd); // Retirer le listener
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

  void _validateCode() async {
    if (_codeController.text == _unlockCode) {
      setState(() {
        _isLocked = false;
      });

      // Essayer d'arrêter le lock task natif, mais ne pas bloquer si ça échoue
      try {
        await AppLockService.stopLockTask();
      } catch (e) {
        print('Erreur lors de l\'arrêt du lock task: $e');
      }

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
        builder: (context) => SettingsPage(
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
    _controller.setLooping(false); // Désactiver la boucle
    _controller.addListener(
      _onVideoEnd,
    ); // Ajouter le listener pour détecter la fin

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
                      child: VideoPlayer(
                        _controller,
                        key: const Key('videoplayer_video'),
                      ),
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
                                key: const Key('videoplayer_title'),
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
                          key: Key(
                            _controller.value.isPlaying
                                ? 'videoplayer_pause_button'
                                : 'videoplayer_play_button',
                          ),
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
                                    const Key('videoplayer_episodes_button'),
                                    Icons.video_library,
                                    'Épisodes',
                                    () {
                                      if (_isLocked) return;
                                      _selectEpisode();
                                    },
                                  ),
                                  _netflixAction(
                                    const Key('videoplayer_settings_button'),
                                    Icons.settings,
                                    'Paramètres',
                                    () {
                                      if (_isLocked) return;
                                      _openSettings();
                                    },
                                  ),
                                  _netflixAction(
                                    const Key('videoplayer_lock_button'),
                                    _isLocked ? Icons.lock : Icons.lock_open,
                                    _isLocked ? 'Vérouiller' : 'Dévérouiller',
                                    () async {
                                      if (_isLocked) {
                                        _showUnlockModal();
                                      } else {
                                        final success =
                                            await AppLockService.startLockTask();
                                        if (success) {
                                          setState(() {
                                            _isLocked = true;
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Mode verrouillage système activé',
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        } else {
                                          // Fallback: verrouillage logiciel si le verrouillage système échoue
                                          setState(() {
                                            _isLocked = true;
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppLockService.isNativeAvailable
                                                    ? 'Mode verrouillage logiciel activé'
                                                    : 'Mode verrouillage activé (système non disponible)',
                                              ),
                                              backgroundColor: Colors.orange,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  _netflixAction(
                                    const Key('videoplayer_next_button'),
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

  Widget _netflixAction(
    Key key,
    IconData icon,
    String label,
    VoidCallback action,
  ) {
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
              key: key,
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
