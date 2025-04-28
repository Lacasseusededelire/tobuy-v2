import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobuy/frontend/providers/shopping_list_provider.dart';
import 'package:tobuy/frontend/widgets/shopping_item_card.dart';
import 'package:tobuy/frontend/widgets/suggestion_card.dart';
import 'package:tobuy/frontend/widgets/total_price_display.dart';
import 'package:tobuy/frontend/widgets/theme_toggle_button.dart';
import 'package:tobuy/frontend/screens/add_item_screen.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:tobuy/models/suggestion.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pipChannel = MethodChannel('com.example.tobuy/pip');
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _enterPipMode() async {
    try {
      await _pipChannel.invokeMethod('enterPipMode');
      print('Mode PiP déclenché');
    } catch (e) {
      print('Erreur PiP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur PiP: $e')),
      );
    }
  }

  void _showRecipeDialog(BuildContext context, ShoppingListProvider provider) {
    final dishController = TextEditingController();
    final budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Suggérer des ingrédients'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dishController,
                decoration: const InputDecoration(
                  labelText: 'Plat (ex. Ndolé)',
                ),
              ),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget (FCFA)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final dish = dishController.text.trim();
                final budget = double.tryParse(budgetController.text.trim()) ?? 1000.0;
                if (dish.isNotEmpty) {
                  final items = await provider.getRecipeIngredients(budget, dish);
                  for (var item in items) {
                    provider.addItem(item);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShoppingListProvider>(context);
    final items = provider.list.items.where((item) {
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    final suggestions = provider.suggestions.take(3).toList(); // Limiter à 3 suggestions

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Liste d\'Achats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture),
            onPressed: _enterPipMode,
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher un aliment',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Liste des aliments
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Liste de courses (${items.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ShoppingItemCard(
                  item: item,
                  onDelete: () => provider.removeItem(item.id),
                );
              },
            ),
            // Suggestions IA
            if (suggestions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Suggestions IA',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return SuggestionCard(
                        suggestion: suggestion,
                        onAccept: () => provider.addSuggestion(suggestion),
                      );
                    },
                  ),
                ],
              ),
            // Bouton pour suggérer des ingrédients
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  _showRecipeDialog(context, provider);
                },
                child: const Text('Suggérer des ingrédients pour un plat'),
              ),
            ),
            // Affichage du prix total
            TotalPriceDisplay(totalPrice: provider.list.totalPrice),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AddItemScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeScaleTransition(animation: animation, child: child);
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}