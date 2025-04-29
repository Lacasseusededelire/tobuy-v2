import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/frontend/providers/app_providers.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/uuid_helper.dart';
import 'package:tobuy/frontend/repositories/local_repository.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() async {
    final query = _nameController.text.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final items = await ref.read(itemsProvider(ref.read(selectedListIdProvider) ?? '').future);
    setState(() {
      _suggestions = items
          .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .map((item) => item.name)
          .toList();
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unitPrice = double.tryParse(_priceController.text);
    final listId = ref.read(selectedListIdProvider);

    if (name.isEmpty || listId == null) return;

    final repo = ref.read(localRepositoryProvider);
    final items = await ref.read(itemsProvider(listId).future);
    final existingItem = items.firstWhere(
      (item) => item.name.toLowerCase() == name.toLowerCase(),
      orElse: () => ShoppingItem(
        id: '',
        listId: listId,
        name: '',
        quantity: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existingItem.name.isNotEmpty) {
      await repo.updateItem(
        existingItem.id,
        quantity: existingItem.quantity + quantity,
        unitPrice: unitPrice ?? existingItem.unitPrice,
      );
    } else {
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
        ),
      );
    }
    ref.invalidate(itemsProvider);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un article')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) => _suggestions,
              onSelected: (String selection) => _nameController.text = selection,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _nameController.text = controller.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'article',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addItem(),
                );
              },
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
            ElevatedButton(onPressed: _addItem, child: const Text('Ajouter')),
          ],
        ),
      ),
    );
  }
}