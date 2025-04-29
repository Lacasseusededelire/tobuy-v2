import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/frontend/providers/app_providers.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/frontend/repositories/local_repository.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final ShoppingItem item;

  const EditItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.item.name;
    _quantityController.text = widget.item.quantity.toString();
    _priceController.text = widget.item.unitPrice?.toString() ?? '';
    _isChecked = widget.item.isChecked;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _updateItem() async {
    final name = _nameController.text.trim();
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unitPrice = double.tryParse(_priceController.text);
    if (name.isEmpty) return;

    final repo = ref.read(localRepositoryProvider);
    await repo.updateItem(
      widget.item.id,
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      isChecked: _isChecked,
    );
    ref.invalidate(itemsProvider);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier l\'article')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom de l\'article', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantité', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Prix unitaire (FCFA)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            CheckboxListTile(
              title: const Text('Acheté'),
              value: _isChecked,
              onChanged: (value) => setState(() => _isChecked = value ?? false),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(onPressed: _updateItem, child: const Text('Mettre à jour')),
          ],
        ),
      ),
    );
  }
}