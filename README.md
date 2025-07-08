# Kidflix - Lecteur Vidéo pour Enfants

Un lecteur vidéo simple et convivial développé avec Flutter, spécialement conçu pour les enfants.

## Fonctionnalités

- ✅ Lecture de vidéos depuis une URL réseau
- ✅ Interface utilisateur intuitive avec contrôles intégrés
- ✅ Barre de progression interactive avec navigation et bouton play/pause
- ✅ Affichage du temps de lecture actuel et total
- ✅ Indicateur de chargement pendant l'initialisation
- ✅ Lecture en boucle automatique
- ✅ Gestion appropriée des ressources (dispose)
- ✅ Interface adaptée aux enfants avec des couleurs vives

## Installation

1. Assurez-vous d'avoir Flutter installé sur votre système
2. Clonez ce repository
3. Exécutez `flutter pub get` pour installer les dépendances
4. Lancez l'application avec `flutter run`

## Dépendances

- `video_player: ^2.10.0` - Pour la lecture de vidéos

## Structure du Code

Le projet suit la structure recommandée par la documentation Flutter pour les lecteurs vidéo :

- `VideoPlayerApp` : Widget principal de l'application
- `VideoPlayerScreen` : Écran contenant le lecteur vidéo
- `VideoPlayerController` : Contrôleur pour gérer la lecture vidéo

## Utilisation

L'application charge automatiquement une vidéo depuis l'URL configurée. L'utilisateur peut :

- Voir un indicateur de chargement pendant l'initialisation
- Utiliser le bouton play/pause intégré dans la barre de contrôle
- Naviguer dans la vidéo avec la barre de progression
- Voir le temps de lecture actuel et la durée totale
- Profiter de la lecture en boucle automatique

## Personnalisation

Pour changer la vidéo, modifiez l'URL dans le `VideoPlayerController.networkUrl()` :

```dart
_controller = VideoPlayerController.networkUrl(
  Uri.parse('VOTRE_URL_VIDEO_ICI'),
);
```

## Tests

Le projet inclut une suite de tests complète :

### Tests de Base
```bash
flutter test test/widget_test.dart
```

### Tests Avancés
```bash
flutter test test/video_player_test.dart
```

### Tous les Tests
```bash
flutter test
```

### Tests avec Couverture
```bash
flutter test --coverage
```

Voir `test/README.md` pour plus de détails sur l'écriture et l'exécution des tests.

## Support des Plateformes

- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Desktop (Linux, macOS, Windows)

## Licence

Ce projet est sous licence MIT.
