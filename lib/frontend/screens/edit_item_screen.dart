import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/frontend/providers/app_providers.dart' as app_providers;
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/ia/services/gemini_service.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final ShoppingItem item;

  const EditItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.item.name;
    _quantityController.text = widget.item.quantity.toString();
    _unitPriceController.text = widget.item.unitPrice.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _updateItem(WidgetRef ref) async {
    if (_formKey.currentState!.validate()) {
      try {
        final localRepo = ref.read(app_providers.localRepositoryProvider);
        final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
        final isOnline = await ref.read(app_providers.connectivityProvider.future);
        await localRepo.updateItem(
          widget.item.id,
          name: _nameController.text.trim(),
          quantity: double.parse(_quantityController.text),
          unitPrice: double.parse(_unitPriceController.text),
        );
        await localRepo.addItemNameToHistory(_nameController.text.trim());
        if (isOnline) {
          try {
            await remoteRepo.updateItem(
              widget.item.id,
              name: _nameController.text.trim(),
              quantity: double.parse(_quantityController.text),
              unitPrice: double.parse(_unitPriceController.text),
              isOnline: isOnline,
            );
            print('Item modifié sur le serveur: ${widget.item.name}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item modifié et synchronisé avec le serveur.')),
            );
          } catch (e) {
            print('Erreur modification item serveur: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item modifié localement, synchronisation en attente.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mode hors ligne : item modifié localement, synchronisation en attente.')),
          );
        }
        ref.invalidate(app_providers.itemsProvider);
        ref.invalidate(app_providers.selectedListProvider);
        ref.invalidate(app_providers.shoppingListsProvider);
        print('Item modifié localement: ${widget.item.name}');
        Navigator.pop(context);
      } catch (e) {
        print('Erreur modification item: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localRepo = ref.read(app_providers.localRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'article'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Nom de l’ingrédient',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                    ),
                    validator: (value) {
                      final currentValue = _nameController.text.trim();
                      if (currentValue.isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => onFieldSubmitted(),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Veuillez entrer une quantité valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitPriceController,
                decoration: InputDecoration(
                  labelText: 'Prix unitaire (FCFA)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Veuillez entrer un prix valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () => _updateItem(ref),
                child: const Text('Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}