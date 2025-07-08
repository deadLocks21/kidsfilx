import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    // Masquer la barre de statut et la barre de navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://timothe.hofmann.fr/tchoupi.mp4'),
    );
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _startTimer();
    _loadUnlockCode();
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    
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

  void _openSettings() {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déverrouillez d\'abord le lecteur pour accéder aux paramètres'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(onCodeChanged: _saveUnlockCode),
      ),
    );
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
                      opacity: (_showUI || !_controller.value.isPlaying) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48), // Espace pour équilibrer
                          Expanded(
                            child: Center(
                              child: Text(
                                '"Has This Ever Happened To You?"',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
  bool _autoPlay = true;
  bool _loopVideo = true;
  bool _showSubtitles = false;
  double _volume = 1.0;
  String _selectedQuality = 'Auto';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Paramètres',
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
          _buildSection(
            'Lecture',
            [
              _buildSwitchTile(
                'Lecture automatique',
                'Démarrer la vidéo automatiquement',
                _autoPlay,
                (value) => setState(() => _autoPlay = value),
                Icons.play_arrow,
              ),
              _buildSwitchTile(
                'Lecture en boucle',
                'Rejouer la vidéo automatiquement',
                _loopVideo,
                (value) => setState(() => _loopVideo = value),
                Icons.repeat,
              ),
              _buildSwitchTile(
                'Sous-titres',
                'Afficher les sous-titres',
                _showSubtitles,
                (value) => setState(() => _showSubtitles = value),
                Icons.subtitles,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Audio',
            [
              _buildSliderTile(
                'Volume',
                _volume,
                (value) => setState(() => _volume = value),
                Icons.volume_up,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Qualité',
            [
              _buildDropdownTile(
                'Qualité vidéo',
                _selectedQuality,
                ['Auto', '1080p', '720p', '480p', '360p'],
                (value) => setState(() => _selectedQuality = value!),
                Icons.high_quality,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Sécurité',
            [
              _buildActionTile(
                'Changer le code de verrouillage',
                'Modifier le code à 4 chiffres',
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangeCodeScreen(
                        onCodeChanged: widget.onCodeChanged,
                      ),
                    ),
                  );
                },
                Icons.lock,
              ),
            ],
          ),
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

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.red,
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    ValueChanged<double> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Slider(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.red,
        inactiveColor: Colors.white24,
      ),
      trailing: Text(
        '${(value * 100).toInt()}%',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        underline: Container(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
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
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70),
      ),
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
    if (_newCodeController.text.length != 4 || !RegExp(r'^\d{4}$').hasMatch(_newCodeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nouveau code doit contenir exactement 4 chiffres !'),
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
                  Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                    size: 24,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Le code doit contenir exactement 4 chiffres',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
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
