class Suggestion {
  final String name;
  final String reason;
  final double estimatedPrice;

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