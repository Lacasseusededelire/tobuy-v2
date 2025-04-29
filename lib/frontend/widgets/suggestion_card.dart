import 'package:flutter/material.dart';
import '../../models/suggestion.dart';

class SuggestionCard extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback onAccept;

  const SuggestionCard({Key? key, required this.suggestion, required this.onAccept}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text('Suggestion: ${suggestion.name}', style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text('${suggestion.reason} (~${suggestion.totalPrice} FCFA)'),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green),
            onPressed: onAccept,
          ),
        ),
      ),
    );
  }
}