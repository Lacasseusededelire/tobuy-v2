import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../../ia/services/gemini_service.dart';
import '../../models/shopping_list.dart';
import '../../models/shopping_item.dart';
import '../../models/suggestion.dart';

class ShoppingListProvider extends ChangeNotifier {
  ShoppingList _list = ShoppingList(
    id: '1',
    userId: 'user1',
    items: [],
    totalPrice: 0.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  List<Suggestion> _suggestions = [];
  final GeminiService _geminiService = GeminiService();

  ShoppingList get list => _list;
  List<Suggestion> get suggestions => _suggestions;

  void addItem(ShoppingItem item) {
    print('Ajout de l\'article: ${item.name}');
    _list.items.add(item);
    _list.totalPrice += item.totalItemPrice;
    _list.updatedAt = DateTime.now();
    _fetchSuggestions();
    _updateWidget();
    notifyListeners();
  }

  void updateItem(String itemId, ShoppingItem updatedItem) {
    print('Mise à jour de l\'article: ${updatedItem.name}');
    final index = _list.items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final oldItem = _list.items[index];
      _list.totalPrice -= oldItem.totalItemPrice;
      _list.items[index] = updatedItem;
      _list.totalPrice += updatedItem.totalItemPrice;
      _list.updatedAt = DateTime.now();
      _fetchSuggestions();
      _updateWidget();
      notifyListeners();
    }
  }

  void removeItem(String itemId) {
    final item = _list.items.firstWhere((i) => i.id == itemId);
    print('Suppression de l\'article: ${item.name}');
    _list.items.remove(item);
    _list.totalPrice -= item.totalItemPrice;
    _list.updatedAt = DateTime.now();
    _fetchSuggestions();
    _updateWidget();
    notifyListeners();
  }

  void addSuggestion(Suggestion suggestion) {
    final item = ShoppingItem(
      id: DateTime.now().toString(),
      name: suggestion.name,
      quantity: 1.0,
      unitPrice: suggestion.estimatedPrice,
      totalItemPrice: suggestion.estimatedPrice,
    );
    addItem(item);
  }

  Future<void> _fetchSuggestions() async {
    try {
      _suggestions = await _geminiService.getSuggestions(_list);
      print('Suggestions IA: ${_suggestions.map((s) => s.name).toList()}');
    } catch (e) {
      print('Erreur lors de l\'appel Gemini: $e');
      _suggestions = _list.items.any((i) => i.name.toLowerCase() == 'okok')
          ? [
              Suggestion(
                name: 'Sucre',
                reason: 'Nécessaire pour l\'okok',
                estimatedPrice: 500.0,
              ),
            ]
          : [];
    }
    notifyListeners();
  }

  Future<void> _updateWidget() async {
    final message = _list.items.isEmpty ? 'Aucun article' : '${_list.items.length} article(s)';
    print('Mise à jour du widget: $message');
    await HomeWidget.saveWidgetData<String>('title', 'ToBuy Widget');
    await HomeWidget.saveWidgetData<String>('message', message);
    await HomeWidget.updateWidget(
      name: 'ToBuyWidget',
      androidName: 'ToBuyWidget',
    );
  }
}