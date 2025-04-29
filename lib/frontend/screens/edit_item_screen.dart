import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/frontend/providers/app_providers.dart' as app_providers;
import 'package:tobuy/models/shopping_item.dart';

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
    _unitPriceController.text = widget.item.unitPrice?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'article'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom de l\'article'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantité'),
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
                decoration: const InputDecoration(labelText: 'Prix unitaire (FCFA)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Veuillez entrer un prix valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final repo = ref.read(app_providers.localRepositoryProvider);
                      await repo.updateItem(
                        widget.item.id,
                        name: _nameController.text.trim(),
                        quantity: double.parse(_quantityController.text),
                        unitPrice: _unitPriceController.text.isEmpty ? null : double.parse(_unitPriceController.text),
                      );
                      ref.invalidate(app_providers.itemsProvider);
                      ref.invalidate(app_providers.selectedListProvider);
                      ref.invalidate(app_providers.shoppingListsProvider);
                      print('Item modifié: ${widget.item.name}, HomeScreen doit être rechargé');
                      Navigator.pop(context);
                    } catch (e) {
                      print('Erreur modification item: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
                child: const Text('Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}