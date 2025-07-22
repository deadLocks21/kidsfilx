import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kidflix/core/domain/services/source_url.repository.dart';

class HttpSourceRepository implements SourceUrlRepository {
  @override
  Future<SourceValidationResult> validateUrl(String sourceUrl) async {
    if (sourceUrl.isEmpty) {
      return SourceValidationResult(isValid: false, message: 'Source vide');
    }

    try {
      final response = await http
          .get(Uri.parse(sourceUrl), headers: {'User-Agent': 'Kidflix/1.0'})
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
                  return SourceValidationResult(
                    isValid: true,
                    sourceName: sourceName,
                    message:
                        'Source valide - ${dataList.length} épisode(s) détecté(s)',
                  );
                } else {
                  return SourceValidationResult(
                    isValid: false,
                    message:
                        'Format JSON invalide - Structure attendue: {name, data: [{name, url}]}',
                  );
                }
              } else {
                return SourceValidationResult(
                  isValid: false,
                  message: 'Source vide - Aucun épisode trouvé',
                );
              }
            } else {
              return SourceValidationResult(
                isValid: false,
                message:
                    'Format JSON invalide - Champs "name" et "data" requis',
              );
            }
          } catch (e) {
            return SourceValidationResult(
              isValid: false,
              message: 'JSON invalide - Erreur de parsing',
            );
          }
        } else {
          return SourceValidationResult(
            isValid: false,
            message: 'Format non supporté - JSON requis',
          );
        }
      } else {
        return SourceValidationResult(
          isValid: false,
          message: 'Erreur HTTP: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SourceValidationResult(
        isValid: false,
        message: 'Impossible d\'accéder à l\'URL',
      );
    }
  }
}
