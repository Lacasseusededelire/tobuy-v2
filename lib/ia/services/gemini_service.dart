import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/models/suggestion.dart';
import 'package:tobuy/constants/api_keys.dart';

class GeminiService {
  final Dio dio;

  GeminiService({required this.dio}) {
    if (kGeminiApiKey.isEmpty) {
      throw Exception('Clé API Gemini non configurée');
    }
  }

  Future<List<String>> getAutocomplete(String query) async {
    try {
      final prompt =
          "Pour l’ingrédient '$query', propose jusqu’à 4 variantes ou types d’ingrédients courants au Cameroun (ex. pour 'plantains', suggère 'banane plantains, plantains mûrs, plantains non mûrs'). Retourne une liste séparée par des virgules.";
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
        queryParameters: {'key': kGeminiApiKey},
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
          .replaceAll('```', '')
          .trim();
      print('Autocomplete Gemini reçu: $rawResponse');
      final suggestions = rawResponse.split(', ').map((s) => s.trim()).toList();
      return suggestions.take(4).toList(); // Limiter à 4 suggestions
    } catch (e) {
      print('Erreur Gemini (autocomplete): $e');
      return [];
    }
  }

  Future<List<Suggestion>> getIngredientsForDish(String dish, double budget) async {
    try {
      final prompt =
          "Pour $budget FCFA à ne pas excéder, liste les ingrédients nécessaires pour préparer $dish au Cameroun, avec les quantités et les prix unitaires en FCFA pour chaque ingrédient. Assure-toi que le total ne dépasse pas le budget. Pour chaque ingrédient, inclus une brève raison (max 10 mots) combinant son utilité dans la recette et ses bienfaits nutritionnels. Formatte le nom de chaque ingrédient en italique Markdown (ex. *Viande*). Formatte la réponse comme suit : 'Nom - Quantité - PrixUnitaire - Raison'.";
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
        queryParameters: {'key': kGeminiApiKey},
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
          .replaceAll('```', '')
          .trim();
      print('Ingrédients Gemini reçus pour $dish: $rawResponse');
      return _parseIngredients(rawResponse);
    } catch (e) {
      print('Erreur Gemini (ingredients): $e');
      return [];
    }
  }

  List<Suggestion> _parseIngredients(String response) {
    final lines = response.split('\n');
    List<Suggestion> items = [];
    for (var line in lines) {
      if (line.isNotEmpty) {
        final parts = line.split(' - ');
        if (parts.length == 4) {
          final name = parts[0].trim();
          final quantity = double.tryParse(parts[1].split(' ')[0]) ?? 1.0;
          final unitPrice = double.tryParse(parts[2].trim().replaceAll(' FCFA', '')) ?? 0.0;
          final reason = parts[3].trim();
          items.add(Suggestion(
            name: name,
            reason: reason,
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: unitPrice * quantity,
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