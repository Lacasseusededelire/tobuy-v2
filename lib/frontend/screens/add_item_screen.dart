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
      final localRepo = ref.read(app_providers.localRepositoryProvider);
      final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
      final listId = ref.read(app_providers.selectedListIdProvider);
      final isOnline = await ref.read(app_providers.connectivityProvider.future);
      if (listId != null) {
        final item = ShoppingItem(
          id: UuidHelper.generate(),
          listId: listId,
          name: name,
          quantity: quantity,
          unitPrice: unitPrice,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: false,
          isDeleted: false,
        );
        await localRepo.addItem(listId, item);
        await localRepo.addItemNameToHistory(name);
        if (isOnline) {
          try {
            await remoteRepo.addItem(listId, item, isOnline: isOnline);
            print('Item ajouté sur le serveur: $name');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item ajouté et synchronisé avec le serveur.')),
            );
          } catch (e) {
            print('Erreur ajout item serveur: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item ajouté localement, synchronisation en attente.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mode hors ligne : item ajouté localement, synchronisation en attente.')),
          );
        }
        ref.invalidate(app_providers.itemsProvider);
        ref.invalidate(app_providers.selectedListProvider);
        ref.invalidate(app_providers.shoppingListsProvider);
        print('Item ajouté localement: $name');
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
    final localRepo = ref.read(app_providers.localRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un article'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                final isOnline = await ref.read(app_providers.connectivityProvider.future);
                if (isOnline) {
                  try {
                    final gemini = ref.read(geminiServiceProvider);
                    final suggestions = await gemini.getAutocomplete(textEditingValue.text);
                    for (var suggestion in suggestions) {
                      await localRepo.addItemNameToHistory(suggestion);
                    }
                    return suggestions.take(4);
                  } catch (e) {
                    print('Erreur autocomplétion serveur: $e');
                    final suggestions = await localRepo.getItemNameSuggestions(textEditingValue.text);
                    return suggestions;
                  }
                } else {
                  final suggestions = await localRepo.getItemNameSuggestions(textEditingValue.text);
                  return suggestions;
                }
              },
              onSelected: (String selection) {
                _nameController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                controller.text = _nameController.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Nom de l’ingrédient',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                  onSubmitted: (_) => onFieldSubmitted(),
                  onChanged: (value) {
                    _nameController.text = value;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    color: Theme.of(context).colorScheme.surface,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            title: Text(
                              option,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
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
              decoration: InputDecoration(
                labelText: 'Quantité',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _unitPriceController,
              decoration: InputDecoration(
                labelText: 'Prix unitaire (FCFA)',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48.0),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () => _addItem(ref),
                    child: const Text('Ajouter'),
                  ),
          ],
        ),
      ),
    );
  }
}