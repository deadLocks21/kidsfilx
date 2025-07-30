import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import 'package:kidflix/core/application/queries/generate_thumbnail_query.dart';
import 'package:kidflix/core/application/queries/get_thumbnails_for_source_query.dart';
import 'package:kidflix/core/application/commands/delete_thumbnails_for_source_command.dart';
import 'package:kidflix/core/domain/model/thumbnail.dart';

class SettingsSourcePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> source;

  const SettingsSourcePage({super.key, required this.source});

  @override
  ConsumerState<SettingsSourcePage> createState() => _SettingsSourcePageState();
}

class _SettingsSourcePageState extends ConsumerState<SettingsSourcePage> {
  List<Map<String, dynamic>> _episodes = [];
  bool _isLoading = true;
  bool _isDownloadingAll = false;
  bool _shouldStopDownload = false;
  final Set<int> _downloadingEpisodes = {};
  Set<int> _downloadedEpisodes = {};
  Map<int, Thumbnail> _thumbnails = {};
  final Map<int, bool> _generatingThumbnails = {};
  Map<int, String> _downloadedFiles = {};
  final Dio _dio = Dio();

  // Getters pour les queries et commandes
  GetThumbnailsForSourceQuery get _getThumbnailsForSourceQuery =>
      ref.read(getThumbnailsForSourceQueryProvider);
  GenerateThumbnailQuery get _generateThumbnailQuery =>
      ref.read(generateThumbnailQueryProvider);
  DeleteThumbnailsForSourceCommand get _deleteThumbnailsForSourceCommand =>
      ref.read(deleteThumbnailsForSourceCommandProvider);

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
    try {
      final thumbnails = await _getThumbnailsForSourceQuery.execute(widget.source['name']);
      
      if (mounted) {
        setState(() {
          _thumbnails = {
            for (final thumbnail in thumbnails)
              thumbnail.episodeIndex: thumbnail
          };
        });
      }
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
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
    if (_generatingThumbnails[index] == true || _thumbnails.containsKey(index)) {
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
      final name = episode['name'] as String;

      final thumbnail = await _generateThumbnailQuery.execute(
        sourceName: widget.source['name'],
        episodeName: name,
        videoUrl: url,
        episodeIndex: index,
      );

      if (mounted) {
        setState(() {
          _thumbnails[index] = thumbnail;
          _generatingThumbnails[index] = false;
        });
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
      try {
        await _deleteThumbnailsForSourceCommand.execute(widget.source['name']);
      } catch (e) {
        // Ignorer les erreurs de suppression des thumbnails
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
          if (!_isLoading &&
              _episodes.isNotEmpty &&
              _downloadedEpisodes.length < _episodes.length)
            IconButton(
              icon: Icon(
                _isDownloadingAll ? Icons.stop : Icons.download,
                color: Colors.white,
              ),
              onPressed: _isDownloadingAll
                  ? _stopAllDownloads
                  : _downloadAllEpisodes,
            ),
          if (_downloadedEpisodes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
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
                                    File(_thumbnails[episodeIndex]!.filePath),
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
