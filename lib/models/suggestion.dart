class Suggestion {
  final String name;
  final String reason; // Condensé incluant utilité et bienfaits
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  Suggestion({
    required this.name,
    required this.reason,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      name: json['name'] as String? ?? 'Inconnu',
      reason: json['reason'] as String? ?? 'Aucune raison',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reason': reason,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory Suggestion.fromMap(Map<String, dynamic> map) {
    return Suggestion(
      name: map['name'] as String? ?? 'Inconnu',
      reason: map['reason'] as String? ?? 'Aucune raison',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'reason': reason,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  @override
  String toString() {
    return 'Suggestion(name: $name, reason: $reason, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice)';
  }
}
