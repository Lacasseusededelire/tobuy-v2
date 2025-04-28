import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/frontend/providers/shopping_list_provider.dart';
import 'package:uuid/uuid.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  List<String> _autocompleteSuggestions = ['Plantains frits', 'Plantains bouillis'];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ShoppingListProvider>(context, listen: false);
      final item = ShoppingItem(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        quantity: double.parse(_quantityController.text),
        unitPrice: double.parse(_unitPriceController.text),
        totalItemPrice: double.parse(_quantityController.text) * double.parse(_unitPriceController.text),
      );
      provider.addItem(item);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un élément')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  // TODO: Appeler GeminiService.getAutocomplete
                  return _autocompleteSuggestions.where((option) =>
                      option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _nameController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _nameController.text = controller.text; // Synchroniser avec Autocomplete
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'aliment',
                      hintText: 'Ex. Plantains frits',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
                  hintText: 'Ex. 1.0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  final quantity = double.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Veuillez entrer une quantité positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire (FCFA)',
                  hintText: 'Ex. 500',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Veuillez entrer un prix positif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}