import 'dart:convert'; // Pour jsonEncode/Decode si besoin dans d'autres modèles

/// Modèle représentant un utilisateur de l'application.
class User {
  /// Identifiant unique universel (UUID) de l'utilisateur. Clé primaire.
  final String id;

  /// Adresse email de l'utilisateur (utilisée pour l'authentification et l'invitation).
  final String email;

  // final String? name; // Nom d'affichage optionnel, décommenter si nécessaire.

  /// Date et heure de création de l'utilisateur (UTC).
  final DateTime createdAt;

  /// Date et heure de la dernière mise à jour de l'utilisateur (UTC). Crucial pour la synchronisation.
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    // this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée une instance User à partir d'un map JSON (typiquement reçu de l'API).
  factory User.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['email'] == null || json['createdAt'] == null || json['updatedAt'] == null) {
      throw FormatException("Données JSON invalides pour User: $json");
    }
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      // name: json['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
    );
  }

  /// Convertit l'instance User en un map JSON (pour l'envoi à l'API).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      // 'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crée une instance User à partir d'un map provenant de la base de données SQLite.
  factory User.fromMap(Map<String, dynamic> map) {
    if (map['id'] == null || map['email'] == null || map['createdAt'] == null || map['updatedAt'] == null) {
      throw FormatException("Données Map invalides pour User: $map");
    }
    return User(
      id: map['id'] as String, // Utilise 'id'
      email: map['email'] as String,
      // name: map['name'] as String?,
      // Assure que les dates stockées comme String ISO8601 dans SQLite sont parsées en UTC
      createdAt: DateTime.parse(map['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updatedAt'] as String).toUtc(),
    );
  }

  /// Convertit l'instance User en un map pour la sauvegarde en base de données SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Utilise 'id'
      'email': email,
      // 'name': name,
      'createdAt': createdAt.toIso8601String(), // Stocke comme String ISO8601
      'updatedAt': updatedAt.toIso8601String(), // Stocke comme String ISO8601
    };
  }

  /// Crée une copie de l'instance User avec potentiellement des champs modifiés.
  User copyWith({
    String? id,
    String? email,
    // String? name, // Optionnel: Utiliser Object() comme valeur spéciale pour nullifier
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

  // Égalité et HashCode basés sur l'ID unique
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}