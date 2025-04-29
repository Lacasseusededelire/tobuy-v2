import 'package:flutter/material.dart';
import '../../models/shopping_item.dart';
import '../screens/edit_item_screen.dart';
import 'package:animations/animations.dart';

class ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onDelete;

  const ShoppingItemCard({
    Key? key,
    required this.item,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          item.name.isNotEmpty ? item.name : 'Article sans nom',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${item.quantity} x ${item.unitPrice} = ${item.totalItemPrice}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        EditItemScreen(item: item),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeScaleTransition(animation: animation, child: child);
                    },
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}