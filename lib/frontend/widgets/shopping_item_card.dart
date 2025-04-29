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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.surface, // Support mode sombre
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (_) => onToggleCheck(),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Quantité: ${item.quantity} | Prix: ${item.totalPrice?.toStringAsFixed(2) ?? '-'} FCFA',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditItemScreen(item: item),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}