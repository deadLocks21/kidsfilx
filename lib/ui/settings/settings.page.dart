import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidflix/core/application/commands/save_all_sources_command.dart';
import 'package:kidflix/core/application/queries/check_source_url_is_valid_query.dart';
import 'package:kidflix/core/application/queries/get_all_sources_query.dart';
import 'package:kidflix/core/domain/model/source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidflix/ui/settings/change_password/settings_change_password.page.dart';
import 'package:kidflix/ui/settings/source/settings_source.dart';

class SettingsPage extends ConsumerStatefulWidget {
  final Function(bool) onShuffleChanged;

  const SettingsPage({super.key, required this.onShuffleChanged});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  List<Source> _sources = [];
  Timer? _urlCheckTimer;
  bool _isCheckingUrl = false;
  bool _isUrlValid = false;
  String _urlCheckMessage = '';
  late CheckSourceUrlIsValidQuery checkSourceUrlIsValidQuery;

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

  Future<String?> _checkUrl(String url, Function setDialogState) async {
    if (url.isEmpty) {
      setDialogState(() {
        _isCheckingUrl = false;
        _isUrlValid = false;
        _urlCheckMessage = '';
      });
      return null;
    }

    setDialogState(() {
      _isCheckingUrl = true;
      _isUrlValid = false;
      _urlCheckMessage = 'Vérification en cours...';
    });

    final result = await checkSourceUrlIsValidQuery(url);

    setDialogState(() {
      _isCheckingUrl = false;
      _isUrlValid = result.isValid;
      _urlCheckMessage = result.message;
    });

    return result.sourceName;
  }

  Future<void> _loadSources() async {
    final getAllSourcesQuery = ref.read(getAllSourcesQueryProvider);
    final sources = await getAllSourcesQuery();
    setState(() {
      _sources = sources;
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
    final saveAllSourcesCommand = ref.read(saveAllSourcesCommandProvider);
    await saveAllSourcesCommand(_sources);
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
                    key: const Key('settings_modal_add_source_url_input'),
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
                          color: _isCheckingUrl
                              ? Colors.white
                              : _isUrlValid
                              ? Colors.green
                              : Colors.red,
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
                          : _isCheckingUrl
                          ? const Icon(Icons.local_dining, color: Colors.white)
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
                        color: _isCheckingUrl
                            ? Colors.white.withValues(alpha: 0.1)
                            : _isUrlValid
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isCheckingUrl
                              ? Colors.white.withValues(alpha: 0.3)
                              : _isUrlValid
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isCheckingUrl
                                ? Icons.local_dining
                                : _isUrlValid
                                ? Icons.check_circle
                                : Icons.info,
                            color: _isCheckingUrl
                                ? Colors.white
                                : _isUrlValid
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              key: Key(
                                'settings_modal_add_source_url_check_message',
                              ),
                              _urlCheckMessage,
                              style: TextStyle(
                                color: _isCheckingUrl
                                    ? Colors.white
                                    : _isUrlValid
                                    ? Colors.green
                                    : Colors.red,
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
                          key: const Key(
                            'settings_modal_add_source_add_button',
                          ),
                          onPressed:
                              (urlController.text.isNotEmpty &&
                                  _isUrlValid &&
                                  detectedSourceName != null)
                              ? () {
                                  setState(() {
                                    _sources.add(
                                      Source(
                                        name: detectedSourceName!,
                                        url: urlController.text,
                                        episodeCount: 0,
                                      ),
                                    );
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
    final sourceName = source.name;

    setState(() {
      _sources.removeAt(index);
    });

    // Supprimer tous les fichiers téléchargés pour cette source
    await _deleteAllEpisodesForSource(sourceName);

    // Supprimer toutes les données associées à cette source
    await _deleteSourceData(sourceName);

    _saveSources();
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
    final sourceName = source.name;

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
                key: Key(
                  'settings_modal_validate_source_deletion_cancel_button',
                ),
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
                key: Key(
                  'settings_modal_validate_source_deletion_delete_source_button',
                ),
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
    checkSourceUrlIsValidQuery = ref.watch(checkSourceUrlIsValidQueryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Paramètres',
          key: Key('settings_title'),
          style: TextStyle(color: Colors.white),
        ),
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
                    builder: (context) => SettingsChangeCodePage(),
                  ),
                );
              },
              Icons.lock,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Sources', [
            ListTile(
              key: const Key('settings_add_source_button'),
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
                key: Key('settings_source_tile'),
                leading: const Icon(Icons.link, color: Colors.white),
                title: Text(
                  source.name,
                  key: Key('settings_source_title'),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  source.url,
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
                            builder: (context) => SettingsSourcePage(
                              source: {
                                'name': source.name,
                                'url': source.url,
                                'episodeCount': source.episodeCount,
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      key: Key('settings_delete_source_button'),
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
