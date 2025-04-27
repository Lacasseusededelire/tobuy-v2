import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/shopping_item_card.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/total_price_display.dart';
import '../widgets/theme_toggle_button.dart';
import 'add_item_screen.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const _pipChannel = MethodChannel('com.example.tobuy/pip');

  Future<void> _enterPipMode() async {
    try {
      await _pipChannel.invokeMethod('enterPipMode');
    } catch (e) {
      print('Erreur PiP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppingListProvider = Provider.of<ShoppingListProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Liste d\'Achats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture),
            onPressed: _enterPipMode, // Bouton pour activer PiP
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: shoppingListProvider.list.items.length,
              itemBuilder: (context, index) {
                final item = shoppingListProvider.list.items[index];
                return ShoppingItemCard(
                  item: item,
                  onDelete: () => shoppingListProvider.removeItem(item.id),
                );
              },
            ),
          ),
          if (shoppingListProvider.suggestions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Suggestions IA',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ...shoppingListProvider.suggestions.map((suggestion) => SuggestionCard(
                      suggestion: suggestion,
                      onAccept: () => shoppingListProvider.addSuggestion(suggestion),
                    )),
              ],
            ),
          TotalPriceDisplay(totalPrice: shoppingListProvider.list.totalPrice),
        ],
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