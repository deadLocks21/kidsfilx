import 'package:flutter/services.dart';

class AppLockService {
  static const MethodChannel _channel = MethodChannel('fr.dtfh.kidflix/app_lock');
  static bool _isNativeAvailable = true;

  /// Démarre le mode verrouillage d'application
  static Future<bool> startLockTask() async {
    if (!_isNativeAvailable) {
      return false;
    }
    try {
      final bool result = await _channel.invokeMethod('startLockTask');
      return result;
    } on PlatformException catch (e) {
      if (e.code == 'MissingPluginException') {
        _isNativeAvailable = false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Arrête le mode verrouillage d'application
  static Future<bool> stopLockTask() async {
    if (!_isNativeAvailable) {
      return true;
    }
    try {
      final bool result = await _channel.invokeMethod('stopLockTask');
      return result;
    } on PlatformException catch (e) {
      if (e.code == 'MissingPluginException') {
        _isNativeAvailable = false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si l'application est en mode verrouillage
  static Future<bool> isLockTaskMode() async {
    if (!_isNativeAvailable) {
      return false;
    }
    try {
      final bool result = await _channel.invokeMethod('isLockTaskMode');
      return result;
    } on PlatformException catch (e) {
      if (e.code == 'MissingPluginException') {
        _isNativeAvailable = false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static bool get isNativeAvailable => _isNativeAvailable;
} 