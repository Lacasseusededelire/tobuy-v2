import 'package:flutter/material.dart';
import 'package:tobuy/models/shopping_item.dart';

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
    return ListTile(
      leading: Checkbox(
        value: item.isChecked,
        onChanged: (_) => onToggleCheck(),
      ),
      title: Text(
        item.name,
        style: TextStyle(decoration: item.isChecked ? TextDecoration.lineThrough : null),
      ),
      subtitle: Text('Quantité: ${item.quantity} - Total: ${item.totalItemPrice} FCFA'),
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
      onTap: () => Navigator.pushNamed(context, '/edit-item', arguments: item),
    );
  }
}