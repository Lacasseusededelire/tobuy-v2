import 'dart:convert'; // Pour jsonEncode/Decode si besoin

/// Énumération pour le statut d'une invitation à collaborer sur une liste.
enum InvitationStatus { pending, accepted, rejected }

/// Extension pour faciliter la conversion de/vers String pour l'enum.
extension InvitationStatusExtension on InvitationStatus {
  String toJson() => name; // Retourne 'pending', 'accepted', 'rejected'
  static InvitationStatus fromJson(String json) {
    return InvitationStatus.values.firstWhere(
          (e) => e.name == json,
      orElse: () => InvitationStatus.pending, // Défaut si inconnu
    );
  }
}

/// Modèle représentant une invitation envoyée à un utilisateur pour rejoindre une liste.
class Invitation {
  /// Identifiant unique universel (UUID) de l'invitation. Clé primaire.
  final String id;

  /// Identifiant unique (UUID) de la liste de courses concernée.
  final String listId;

  /// Nom de la liste (dénormalisé pour affichage facile dans l'UI).
  final String listName;

  /// Identifiant unique (UUID) de l'utilisateur qui a envoyé l'invitation.
  final String inviterId;

  /// Email de l'utilisateur qui a envoyé l'invitation (dénormalisé).
  final String inviterEmail;

  /// Email de l'utilisateur invité (cible de l'invitation).
  final String inviteeEmail;

  /// Statut actuel de l'invitation (pending, accepted, rejected).
  InvitationStatus status;

  /// Date et heure de création de l'invitation (UTC).
  final DateTime createdAt;

  /// Date et heure de la dernière mise à jour de l'invitation (UTC).
  DateTime updatedAt;

  // --- Constructeur ---
  Invitation({
    required this.id,
    required this.listId,
    required this.listName,
    required this.inviterId,
    required this.inviterEmail,
    required this.inviteeEmail,
    this.status = InvitationStatus.pending, // Statut par défaut
    required this.createdAt,
    required this.updatedAt,
  });

  // --- Sérialisation / Désérialisation ---

  /// Crée une instance Invitation à partir d'un map JSON (API).
  factory Invitation.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['listId'] == null || json['listName'] == null ||
        json['inviterId'] == null || json['inviterEmail'] == null || json['inviteeEmail'] == null ||
        json['status'] == null || json['createdAt'] == null || json['updatedAt'] == null) {
      throw FormatException("Données JSON invalides pour Invitation: $json");
    }
    return Invitation(
      id: json['id'] as String,
      listId: json['listId'] as String,
      listName: json['listName'] as String,
      inviterId: json['inviterId'] as String,
      inviterEmail: json['inviterEmail'] as String,
      inviteeEmail: json['inviteeEmail'] as String,
      status: InvitationStatusExtension.fromJson(json['status'] as String), // Utilise l'extension
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
    );
  }

  /// Convertit l'instance Invitation en un map JSON (API).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listId': listId,
      'listName': listName,
      'inviterId': inviterId,
      'inviterEmail': inviterEmail,
      'inviteeEmail': inviteeEmail,
      'status': status.toJson(), // Utilise l'extension ('pending', 'accepted', 'rejected')
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crée une instance Invitation à partir d'un map (SQLite).
  factory Invitation.fromMap(Map<String, dynamic> map) {
    if (map['id'] == null || map['listId'] == null || map['listName'] == null ||
        map['inviterId'] == null || map['inviterEmail'] == null || map['inviteeEmail'] == null ||
        map['status'] == null || map['createdAt'] == null || map['updatedAt'] == null) {
      throw FormatException("Données Map invalides pour Invitation: $map");
    }
    return Invitation(
      id: map['id'] as String,
      listId: map['listId'] as String,
      listName: map['listName'] as String,
      inviterId: map['inviterId'] as String,
      inviterEmail: map['inviterEmail'] as String,
      inviteeEmail: map['inviteeEmail'] as String,
      status: InvitationStatusExtension.fromJson(map['status'] as String), // SQLite stocke comme TEXT
      createdAt: DateTime.parse(map['createdAt'] as String).toUtc(), // SQLite stocke comme TEXT
      updatedAt: DateTime.parse(map['updatedAt'] as String).toUtc(), // SQLite stocke comme TEXT
    );
  }

  /// Convertit l'instance Invitation en un map (SQLite).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'listName': listName,
      'inviterId': inviterId,
      'inviterEmail': inviterEmail,
      'inviteeEmail': inviteeEmail,
      'status': status.toJson(), // Stocke comme TEXT ('pending', 'accepted', 'rejected')
      'createdAt': createdAt.toIso8601String(), // Stocke comme TEXT
      'updatedAt': updatedAt.toIso8601String(), // Stocke comme TEXT
    };
  }

  /// Crée une copie avec des champs potentiellement modifiés.
  Invitation copyWith({
    String? id,
    String? listId,
    String? listName,
    String? inviterId,
    String? inviterEmail,
    String? inviteeEmail,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invitation(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      listName: listName ?? this.listName,
      inviterId: inviterId ?? this.inviterId,
      inviterEmail: inviterEmail ?? this.inviterEmail,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Invitation(id: $id, list: $listName ($listId), from: $inviterEmail, to: $inviteeEmail, status: ${status.toJson()})';
  }

  // Égalité et HashCode basés sur l'ID unique
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}