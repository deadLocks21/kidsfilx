import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidflix/core/application/commands/update_unlock_code_command.dart';
import 'package:kidflix/core/application/queries/validate_unlock_code_query.dart';

class SettingsChangeCodePage extends ConsumerStatefulWidget {
  const SettingsChangeCodePage({super.key});

  @override
  ConsumerState<SettingsChangeCodePage> createState() =>
      _SettingsChangeCodeScreePage();
}

class _SettingsChangeCodeScreePage
    extends ConsumerState<SettingsChangeCodePage> {
  final TextEditingController _currentCodeController = TextEditingController();
  final TextEditingController _newCodeController = TextEditingController();
  final TextEditingController _confirmCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _currentCodeController.dispose();
    _newCodeController.dispose();
    _confirmCodeController.dispose();
    super.dispose();
  }

  ValidateUnlockCodeQuery get _validateQuery =>
      ref.read(validateUnlockCodeQueryProvider);
  UpdateUnlockCodeCommand get _updateCommand =>
      ref.read(updateUnlockCodeCommandProvider);

  void _changeCode() async {
    if (!mounted) {
      return;
    }
    final isCurrentCodeValid = await _validateQuery.validateCode(
      _currentCodeController.text,
    );

    if (!isCurrentCodeValid) {
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les codes ne correspondent pas !'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    try {
      // Utiliser la commande pour mettre à jour le code
      await _updateCommand.updateCode(
        _currentCodeController.text,
        _newCodeController.text,
      );

      if (!mounted) {
        return;
      }

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
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification du code: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
