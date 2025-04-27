import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shopping_item.dart';
import '../providers/shopping_list_provider.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double _quantity = 1.0;
  double _unitPrice = 0.0;
  List<String> _autocompleteSuggestions = ['Plantains frits', 'Plantains bouillis']; // Simulé

  @override
  Widget build(BuildContext context) {
    final shoppingListProvider = Provider.of<ShoppingListProvider>(context);
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
                  _name = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Nom de l\'aliment'),
                    validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                    onChanged: (value) => _name = value,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                onChanged: (value) => _quantity = double.tryParse(value) ?? 1.0,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Prix unitaire (FCFA)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                onChanged: (value) => _unitPrice = double.tryParse(value) ?? 0.0,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final item = ShoppingItem(
                      id: DateTime.now().toString(),
                      name: _name,
                      quantity: _quantity,
                      unitPrice: _unitPrice,
                      totalItemPrice: _quantity * _unitPrice,
                    );
                    shoppingListProvider.addItem(item);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}