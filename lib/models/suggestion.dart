class Suggestion {
  final String name; // Ex. "Sucre"
  final String reason; // Ex. "Nécessaire pour l'okok"
  final double estimatedPrice; // Ex. 200.0

  Suggestion({
    required this.name,
    required this.reason,
    required this.estimatedPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'reason': reason,
      'estimated_price': estimatedPrice,
    };
  }

  factory Suggestion.fromMap(Map<String, dynamic> map) {
    return Suggestion(
      name: map['name'] as String,
      reason: map['reason'] as String,
      estimatedPrice: (map['estimated_price'] as num).toDouble(),
    );
  }
}