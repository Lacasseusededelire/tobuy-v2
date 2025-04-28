import 'dart:convert'; // Pour jsonEncode/Decode des collaboratorIds
import 'package:tobuy/models/shopping_item.dart'; // Assurez-vous que le chemin est correct

/// Modèle représentant une liste de courses.
class ShoppingList {
  /// Identifiant unique universel (UUID) de la liste. Clé primaire.
  final String id;

  /// Identifiant unique (UUID) de l'utilisateur propriétaire de la liste.
  final String ownerId;

  /// Nom de la liste de courses (modifiable).
  String name;

  /// Liste des identifiants (UUIDs) des utilisateurs collaborateurs.
  /// Stockée comme String JSON dans SQLite.
  final List<String> collaboratorIds;

  /// Date et heure de création de la liste (UTC).
  final DateTime createdAt;

  /// Date et heure de la dernière mise à jour de la liste (UTC). Crucial pour la synchronisation.
  DateTime updatedAt;

  /// Indicateur local: true si la liste est synchronisée avec le serveur, false sinon.
  /// Ne pas inclure dans toJson/fromJson pour l'API principale (géré par SyncService).
  bool isSynced;

  /// Indicateur local de suppression logique (soft delete).
  /// true si la liste est marquée comme supprimée localement.
  /// Ne pas inclure dans toJson/fromJson pour l'API principale (géré par SyncService).
  bool isDeleted;

  /// Liste des articles de cette liste.
  /// **Important:** Cette liste n'est PAS persistée directement dans la table 'shopping_lists'.
  /// Elle est chargée à la demande depuis la table 'shopping_items' via le `listId`.
  /// Utilisée principalement pour l'affichage et les calculs en mémoire.
  List<ShoppingItem> items;

  // --- Constructeur ---
  ShoppingList({
    required this.id,
    required this.ownerId,
    required this.name,
    List<String>? collaboratorIds,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false, // Par défaut, non synchronisé lors de la création locale
    this.isDeleted = false, // Par défaut, non supprimé
    this.items = const [], // Initialiser avec une liste d'items vide par défaut
  }) : collaboratorIds = collaboratorIds ?? []; // Assure que la liste n'est jamais nulle

  /// Calcule le prix total de la liste en additionnant le prix total de chaque item.
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalItemPrice);

  // --- Sérialisation / Désérialisation ---

  /// Crée une instance ShoppingList à partir d'un map JSON (API).
  /// Ne peuple PAS les 'items'. 'isSynced' et 'isDeleted' sont gérés localement.
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['ownerId'] == null || json['name'] == null || json['createdAt'] == null || json['updatedAt'] == null) {
      throw FormatException("Données JSON invalides pour ShoppingList: $json");
    }
    return ShoppingList(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      // Gère le cas où 'collaboratorIds' est null ou absent dans le JSON
      collaboratorIds: (json['collaboratorIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          ?.toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      // isSynced et isDeleted ne sont pas définis par l'API principale ici.
      // Les items sont chargés séparément.
    );
  }

  /// Convertit l'instance ShoppingList en un map JSON (API).
  /// N'inclut PAS 'items', 'isSynced', 'isDeleted'.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'collaboratorIds': collaboratorIds, // Envoyé comme array JSON
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crée une instance ShoppingList à partir d'un map (SQLite).
  /// Ne peuple PAS les 'items'. Récupère 'isSynced' et 'isDeleted'.
  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    if (map['id'] == null || map['ownerId'] == null || map['name'] == null || map['createdAt'] == null || map['updatedAt'] == null) {
      throw FormatException("Données Map invalides pour ShoppingList: $map");
    }
    List<String> collaborators = [];
    if (map['collaboratorIds'] != null && (map['collaboratorIds'] as String).isNotEmpty) {
      try {
        collaborators = List<String>.from(jsonDecode(map['collaboratorIds'] as String));
      } catch (e) {
        print("Erreur décodage collaboratorIds pour list ${map['id']}: ${map['collaboratorIds']} - Erreur: $e");
        // Gérer l'erreur comme vous le souhaitez, ici on laisse la liste vide
      }
    }

    return ShoppingList(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      collaboratorIds: collaborators, // Décode la chaîne JSON stockée
      createdAt: DateTime.parse(map['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updatedAt'] as String).toUtc(),
      isSynced: (map['isSynced'] as int? ?? 0) == 1, // SQLite stocke booléen comme 0 ou 1
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      // Les items sont chargés séparément.
    );
  }

  /// Convertit l'instance ShoppingList en un map (SQLite).
  /// N'inclut PAS 'items'. Inclut 'isSynced' et 'isDeleted'.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'collaboratorIds': jsonEncode(collaboratorIds), // Encode la liste en chaîne JSON
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0, // Stocke comme entier 0 ou 1
      'isDeleted': isDeleted ? 1 : 0, // Stocke comme entier 0 ou 1
    };
  }

  /// Crée une copie avec des champs potentiellement modifiés.
  ShoppingList copyWith({
    String? id,
    String? ownerId,
    String? name,
    List<String>? collaboratorIds,
    List<ShoppingItem>? items, // Permet de mettre à jour les items chargés en mémoire
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      collaboratorIds: collaboratorIds ?? List.from(this.collaboratorIds), // Copie profonde
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      items: items ?? List.from(this.items), // Copie profonde
    );
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, ownerId: $ownerId, items: ${items.length}, collaborators: ${collaboratorIds.length}, synced: $isSynced, deleted: $isDeleted, updatedAt: $updatedAt)';
  }

  // Égalité et HashCode basés sur l'ID unique
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingList && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}