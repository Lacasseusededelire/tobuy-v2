import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/frontend/providers/app_providers.dart' as app_providers;
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/uuid_helper.dart';
import 'package:tobuy/ia/services/gemini_service.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _addItem(WidgetRef ref) async {
    final name = _nameController.text.trim();
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(app_providers.localRepositoryProvider);
      final listId = ref.read(app_providers.selectedListIdProvider);
      if (listId != null) {
        await repo.addItem(
          listId,
          ShoppingItem(
            id: UuidHelper.generate(),
            listId: listId,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: false,
            isDeleted: false,
          ),
        );
        ref.invalidate(app_providers.itemsProvider);
        ref.invalidate(app_providers.selectedListProvider);
        ref.invalidate(app_providers.shoppingListsProvider);
        print('Item ajouté: $name');
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune liste sélectionnée')),
        );
      }
    } catch (e) {
      print('Erreur ajout item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un article'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                final gemini = ref.read(geminiServiceProvider);
                final suggestions = await gemini.getAutocomplete(textEditingValue.text);
                return suggestions.take(4); // Limiter à 4 suggestions
              },
              onSelected: (String selection) {
                _nameController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _nameController.text = controller.text; // Synchroniser avec le controller
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l’ingrédient',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onFieldSubmitted(),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            title: Text(option),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _unitPriceController,
              decoration: const InputDecoration(
                labelText: 'Prix unitaire (FCFA)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48.0)),
                    onPressed: () => _addItem(ref),
                    child: const Text('Ajouter'),
                  ),
          ],
        ),
      ),
    );
  }
}