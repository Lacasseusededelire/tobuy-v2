import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/models/suggestion.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/uuid_helper.dart';
import 'package:tobuy/constants/api_keys.dart';

class GeminiService {
  final Dio dio;

  GeminiService({required this.dio});

  Future<List<Suggestion>> getSuggestions(List<String> currentItems) async {
    try {
      final items = currentItems.join(', ');
      final prompt =
          "Analyse la liste d’achats suivante : $items. Suggère des aliments manquants pour des plats camerounais, avec une raison et un prix estimé pour chaque suggestion. Formatte la réponse comme suit : 'Nom - Raison - Prix'.";
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
        options: Options(headers: {'Authorization': 'Bearer $kGeminiApiKey'}),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        },
      );
      final rawResponse = (response.data['candidates'][0]['content']['parts'][0]['text'] as String)
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return _parseSuggestions(rawResponse);
    } catch (e) {
      print('Erreur Gemini (suggestions): $e');
      return [];
    }
  }

  Future<List<String>> getAutocomplete(String query) async {
    try {
      final prompt =
          "Pour l’aliment '$query', propose des variations ou préparations courantes au Cameroun. Retourne une liste séparée par des virgules.";
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
        options: Options(headers: {'Authorization': 'Bearer $kGeminiApiKey'}),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        },
      );
      final rawResponse = (response.data['candidates'][0]['content']['parts'][0]['text'] as String)
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return rawResponse.split(', ').map((s) => s.trim()).toList();
    } catch (e) {
      print('Erreur Gemini (autocomplete): $e');
      return [];
    }
  }

  Future<List<Suggestion>> getIngredientsForDish(String dish, double budget) async {
    try {
      final prompt =
          "Pour $budget FCFA, liste les ingrédients nécessaires pour préparer $dish au Cameroun, avec les quantités et les prix unitaires pour chaque ingrédient. Assure-toi que le total ne dépasse pas le budget. Formatte la réponse comme suit : 'Nom - Quantité - Prix'.";
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
        options: Options(headers: {'Authorization': 'Bearer $kGeminiApiKey'}),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        },
      );
      final rawResponse = (response.data['candidates'][0]['content']['parts'][0]['text'] as String)
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return _parseIngredients(rawResponse);
    } catch (e) {
      print('Erreur Gemini (ingredients): $e');
      return [];
    }
  }

  List<Suggestion> _parseSuggestions(String response) {
    final lines = response.split('\n');
    List<Suggestion> suggestions = [];
    for (var line in lines) {
      if (line.isNotEmpty) {
        final parts = line.split(' - ');
        if (parts.length == 3) {
          suggestions.add(Suggestion(
            name: parts[0].trim(),
            reason: parts[1].trim(),
            estimatedPrice: double.tryParse(parts[2].trim()) ?? 0.0,
          ));
        }
      }
    }
    return suggestions;
  }

  List<Suggestion> _parseIngredients(String response) {
    final lines = response.split('\n');
    List<Suggestion> items = [];
    for (var line in lines) {
      if (line.isNotEmpty) {
        final parts = line.split(' - ');
        if (parts.length == 3) {
          final name = parts[0].trim();
          final quantity = double.tryParse(parts[1].split(' ')[0]) ?? 1.0;
          final unitPrice = double.tryParse(parts[2].trim()) ?? 0.0;
          items.add(Suggestion(
            name: name,
            reason: 'Ingrédient pour la recette',
            estimatedPrice: unitPrice * quantity,
          ));
        }
      }
    }
    return items;
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(dio: Dio());
});