import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobuy/frontend/providers/shopping_list_provider.dart';
import 'package:tobuy/models/shopping_item.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  List<String> _autocompleteSuggestions = [];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _fetchAutocomplete(String query) async {
    if (query.isNotEmpty) {
      final provider = Provider.of<ShoppingListProvider>(context, listen: false);
      final suggestions = await provider.getAutocomplete(query);
      setState(() {
        _autocompleteSuggestions = suggestions;
      });
    } else {
      setState(() {
        _autocompleteSuggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un aliment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'aliment',
              ),
              onChanged: _fetchAutocomplete,
            ),
            if (_autocompleteSuggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _autocompleteSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _autocompleteSuggestions[index];
                    return ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        _nameController.text = suggestion;
                        setState(() {
                          _autocompleteSuggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _unitPriceController,
              decoration: const InputDecoration(
                labelText: 'Prix unitaire (FCFA)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final quantity = double.tryParse(_quantityController.text) ?? 1.0;
                final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
                if (name.isNotEmpty) {
                  final item = ShoppingItem(
                    id: DateTime.now().toString(),
                    name: name,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    totalItemPrice: quantity * unitPrice,
                  );
                  Provider.of<ShoppingListProvider>(context, listen: false).addItem(item);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}