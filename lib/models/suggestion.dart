class Suggestion {
  final String name;
  final String reason;
  final double estimatedPrice;

  Suggestion({
    required this.name,
    required this.reason,
    required this.estimatedPrice,
  });

  // Gardé tel quel, semble correct
  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      name: json['name'] as String? ?? 'Inconnu',
      reason: json['reason'] as String? ?? 'Aucune raison',
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Gardé tel quel, semble correct
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reason': reason,
      'estimated_price': estimatedPrice,
    };
  }

  // Gardé tel quel, semble correct
  factory Suggestion.fromMap(Map<String, dynamic> map) {
    // Assumant que le prix est stocké comme num dans la map (si jamais stocké)
    return Suggestion(
      name: map['name'] as String? ?? 'Inconnu',
      reason: map['reason'] as String? ?? 'Aucune raison',
      estimatedPrice: (map['estimated_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Gardé tel quel, semble correct
  Map<String, dynamic> toMap() {
     return {
      'name': name,
      'reason': reason,
      'estimated_price': estimatedPrice,
    };
  }

  @override
  String toString() {
    return 'Suggestion(name: $name, reason: $reason, estimatedPrice: $estimatedPrice)';
  }
}