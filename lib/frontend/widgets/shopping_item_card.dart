import 'package:flutter/material.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/frontend/screens/edit_item_screen.dart';

class ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onDelete;
  final VoidCallback onToggleCheck;

  const ShoppingItemCard({
    Key? key,
    required this.item,
    required this.onDelete,
    required this.onToggleCheck,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (_) => onToggleCheck(),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Quantité: ${item.quantity} | Total: ${item.totalPrice} FCFA',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditItemScreen(item: item)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}