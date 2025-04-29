import 'dart:convert'; // Pour jsonEncode/Decode si besoin

// Énumération pour le statut de l'invitation
enum InvitationStatus { pending, accepted, rejected }

class Invitation {
  final String id; // UUID de l'invitation
  final String listId; // UUID de la liste concernée
  final String listName; // Nom de la liste (dénormalisé pour affichage facile)
  final String inviterId; // UUID de l'utilisateur qui invite
  final String inviterEmail; // Email de l'inviteur (dénormalisé)
  final String inviteeEmail; // Email de l'utilisateur invité (cible)
  InvitationStatus status; // Statut actuel
  final DateTime createdAt;
  DateTime updatedAt;

  Invitation({
    required this.id,
    required this.listId,
    required this.listName,
    required this.inviterId,
    required this.inviterEmail,
    required this.inviteeEmail,
    this.status = InvitationStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  // Pour l'API JSON (Dio)
  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      listId: json['listId'] as String,
      listName: json['listName'] as String,
      inviterId: json['inviterId'] as String,
      inviterEmail: json['inviterEmail'] as String,
      inviteeEmail: json['inviteeEmail'] as String,
      status: InvitationStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'], // Compare juste le nom
            orElse: () => InvitationStatus.pending),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listId': listId,
      'listName': listName,
      'inviterId': inviterId,
      'inviterEmail': inviterEmail,
      'inviteeEmail': inviteeEmail,
      'status': status.toString().split('.').last, // Envoie "pending", "accepted", etc.
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Pour la base de données locale SQLite
  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] as String,
      listId: map['listId'] as String,
      listName: map['listName'] as String,
      inviterId: map['inviterId'] as String,
      inviterEmail: map['inviterEmail'] as String,
      inviteeEmail: map['inviteeEmail'] as String,
      status: InvitationStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'], // Compare juste le nom
            orElse: () => InvitationStatus.pending),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'listName': listName,
      'inviterId': inviterId,
      'inviterEmail': inviterEmail,
      'inviteeEmail': inviteeEmail,
      'status': status.toString().split('.').last, // Stocke comme String
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

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
    return 'Invitation(id: $id, list: $listName ($listId), from: $inviterEmail, to: $inviteeEmail, status: $status)';
  }
}