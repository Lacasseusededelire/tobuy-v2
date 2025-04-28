import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tobuy/ia/services/gemini_service.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/suggestion.dart';

void main() {
  group('GeminiService', () {
    late GeminiService service;

    setUp(() {
      service = GeminiService();
    });

    test('getSuggestions returns a list of suggestions', () async {
      // Créer une liste de courses pour le test
      final shoppingList = ShoppingList(
        id: '1',
        userId: 'test_user',
        items: [
          ShoppingItem(
            id: '1',
            name: 'Tomate',
            quantity: 2,
            unitPrice: 100,
            totalItemPrice: 200,
          ),
          ShoppingItem(
            id: '2',
            name: 'Oignon',
            quantity: 1,
            unitPrice: 50,
            totalItemPrice: 50,
          ),
        ],
        totalPrice: 250,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Appeler la méthode et attendre la réponse de l'API
      final suggestions = await service.getSuggestions(shoppingList);

      // Vérifier que la liste n'est pas vide
      expect(suggestions, isNotEmpty);

      // Vérifier que les suggestions ont le format attendu
      for (var suggestion in suggestions) {
        expect(suggestion.name, isNotEmpty);
        expect(suggestion.reason, isNotEmpty);
        expect(suggestion.estimatedPrice, greaterThanOrEqualTo(0.0));
      }
    });

    test('getAutocomplete returns a list of autocomplete suggestions', () async {
      // Définir une requête de test
      final query = 'Poisson';

      // Appeler la méthode et attendre la réponse de l'API
      final suggestions = await service.getAutocomplete(query);

      // Vérifier que la liste n'est pas vide
      expect(suggestions, isNotEmpty);

      // Vérifier que chaque suggestion est une chaîne non vide
      for (var suggestion in suggestions) {
        expect(suggestion, isNotEmpty);
      }
    });

    test('getRecipeIngredients returns a list of ShoppingItem', () async {
      // Définir un budget et un plat pour le test
      final budget = 1000.0;
      final dish = 'Ndolé';

      // Appeler la méthode et attendre la réponse de l'API
      final items = await service.getRecipeIngredients(budget, dish);

      // Vérifier que la liste n'est pas vide
      expect(items, isNotEmpty);

      // Vérifier que les éléments ont le format attendu
      double totalCost = 0.0;
      for (var item in items) {
        expect(item.name, isNotEmpty);
        expect(item.quantity, greaterThan(0.0));
        expect(item.unitPrice, greaterThanOrEqualTo(0.0));
        expect(item.totalItemPrice, equals(item.quantity * item.unitPrice));
        totalCost += item.totalItemPrice;
      }

      // Vérifier que le coût total ne dépasse pas le budget
      expect(totalCost, lessThanOrEqualTo(budget));
    });
  });
}