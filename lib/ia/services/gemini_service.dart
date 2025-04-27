import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tobuy/constants/api_keys.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/suggestion.dart';

class GeminiService {
  final String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Récupère des suggestions d'aliments pour des plats camerounais basées sur une liste de courses
  Future<List<Suggestion>> getSuggestions(ShoppingList shoppingList) async {
    try {
      final items = shoppingList.items.map((item) => item.name).join(', ');
      final prompt = "Analyse la liste d’achats suivante : $items. Suggère des aliments manquants pour des plats camerounais, avec une raison et un prix estimé pour chaque suggestion. Formatte la réponse comme suit : 'Nom - Raison - Prix'.";
      final response = await _sendPrompt(prompt);
      return _parseSuggestions(response);
    } catch (e) {
      print('Erreur dans getSuggestions : $e');
      return [];
    }
  }

  // Récupère des suggestions d'autocomplétion pour une requête alimentaire donnée
  Future<List<String>> getAutocomplete(String query) async {
    try {
      final prompt = "Pour l’aliment '$query', propose des variations ou préparations courantes au Cameroun. Retourne une liste séparée par des virgules.";
      final response = await _sendPrompt(prompt);
      return response.split(', ').map((s) => s.trim()).toList();
    } catch (e) {
      print('Erreur dans getAutocomplete : $e');
      return [];
    }
  }

  // Récupère les ingrédients nécessaires pour un plat spécifique dans un budget donné
  Future<List<ShoppingItem>> getRecipeIngredients(double budget, String dish) async {
    try {
      final prompt = "Pour $budget FCFA, liste les ingrédients nécessaires pour préparer $dish au Cameroun, avec les quantités et les prix unitaires pour chaque ingrédient. Assure-toi que le total ne dépasse pas le budget. Formatte la réponse comme suit : 'Nom - Quantité - Prix'.";
      final response = await _sendPrompt(prompt);
      return _parseRecipeIngredients(response);
    } catch (e) {
      print('Erreur dans getRecipeIngredients : $e');
      return [];
    }
  }

  Future<String> _sendPrompt(String prompt) async {
    // Effectue une requête POST vers l'API Gemini
    final response = await http.post(
      Uri.parse('$apiUrl?key=$geminiApiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      // Décode la réponse et extrait le contenu textuel
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'].trim();
    } else {
      throw Exception('Erreur API Gemini : ${response.statusCode} - ${response.body}');
    }
  }

  // Analyse la réponse de l'API pour créer une liste d'objets Suggestion
  List<Suggestion> _parseSuggestions(String response) {
    final lines = response.split('\n');
    List<Suggestion> suggestions = [];
    for (var line in lines) {
      if (line.isNotEmpty) {
        // Divise la ligne en parties (nom, raison, prix)
        final parts = line.split(' - ');
        if (parts.length == 3) {
          // Crée un objet Suggestion et l'ajoute à la liste
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

  // Analyse la réponse de l'API pour créer une liste d'objets ShoppingItem
  List<ShoppingItem> _parseRecipeIngredients(String response) {
    final lines = response.split('\n');
    List<ShoppingItem> items = [];
    for (var line in lines) {
      if (line.isNotEmpty) {
        final parts = line.split(' - ');
        if (parts.length == 3) {
          // Extrait le nom, la quantité et le prix unitaire
          final name = parts[0].trim();
          final quantity = double.tryParse(parts[1].split(' ')[0]) ?? 1.0;
          final unitPrice = double.tryParse(parts[2].trim()) ?? 0.0;
          // Crée un objet ShoppingItem et l'ajoute à la liste
          items.add(ShoppingItem(
            id: '',
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            totalItemPrice: quantity * unitPrice,
          ));
        }
      }
    }
    return items;
  }
}