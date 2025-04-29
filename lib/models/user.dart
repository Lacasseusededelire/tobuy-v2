import 'dart:convert'; // Pour jsonEncode/Decode si besoin dans d'autres modèles

// Modèle principal pour l'utilisateur
class User {
  final String id; // UUID de l'utilisateur (remplace uid)
  final String email;
  // final String? name; // Optionnel, si vous voulez un nom d'affichage
  final DateTime createdAt;
  final DateTime updatedAt; // Ajouté pour la synchro

  User({
    required this.id,
    required this.email,
    // this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  // Pour l'API JSON (Dio)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      // name: json['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      // 'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Pour la base de données locale SQLite
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String, // Utilise 'id' au lieu de 'uid'
      email: map['email'] as String,
      // name: map['name'] as String?,
      // Assurez-vous que les dates sont stockées comme String ISO8601 dans SQLite
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Utilise 'id'
      'email': email,
      // 'name': name,
      'createdAt': createdAt.toIso8601String(), // Stocke comme String
      'updatedAt': updatedAt.toIso8601String(), // Stocke comme String
    };
  }

  User copyWith({
    String? id,
    String? email,
    // String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      // name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  @override
  String toString() {
    return 'User(id: $id, email: $email, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}