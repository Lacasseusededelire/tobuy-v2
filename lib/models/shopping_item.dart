import 'package:tobuy/models/uuid_helper.dart'; // Pour UuidHelper.generate() si utilisé, sinon commenter/supprimer

/// Modèle représentant un article dans une liste de courses.
class ShoppingItem {
  /// Identifiant unique universel (UUID) de l'article. Clé primaire.
  final String id;

  /// Identifiant unique (UUID) de la liste de courses parente. Clé étrangère.
  final String listId;

  /// Nom de l'article (modifiable).
  String name;

  /// Quantité souhaitée de l'article (modifiable).
  double quantity;

  /// Prix unitaire estimé ou réel de l'article (modifiable, peut être nul).
  double? unitPrice;

  /// Indicateur si l'article a été acheté/coché dans la liste (modifiable).
  bool isChecked;

  /// Date et heure de création de l'article (UTC).
  final DateTime createdAt;

  /// Date et heure de la dernière mise à jour de l'article (UTC). Crucial pour la synchronisation.
  DateTime updatedAt;

  /// Indicateur local: true si l'article est synchronisé avec le serveur, false sinon.
  bool isSynced;

  /// Indicateur local de suppression logique (soft delete).
  bool isDeleted;

  // --- Constructeur ---
  ShoppingItem({
    required this.id,
    required this.listId, // Requis pour lier à une liste
    required this.name,
    this.quantity = 1.0, // Quantité par défaut
    this.unitPrice, // Nullable par défaut
    this.isChecked = false, // Non coché par défaut
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });

  /// Calcule le prix total pour cet article (quantité * prix unitaire).
  /// Retourne 0.0 si le prix unitaire est nul.
  double get totalItemPrice => (unitPrice ?? 0.0) * quantity;

  // --- Sérialisation / Désérialisation ---

  /// Crée une instance ShoppingItem à partir d'un map JSON (API).
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['listId'] == null || json['name'] == null || json['createdAt'] == null || json['updatedAt'] == null) {
      throw FormatException("Données JSON invalides pour ShoppingItem: $json");
    }
    return ShoppingItem(
      id: json['id'] as String,
      listId: json['listId'] as String, // Doit être fourni par l'API
      name: json['name'] as String,
      // Gère les types numériques (int ou double) venant du JSON
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(), // Gère null
      isChecked: json['isChecked'] as bool? ?? false, // Gère null et valeur par défaut
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      // isSynced et isDeleted sont gérés localement.
    );
  }

  /// Convertit l'instance ShoppingItem en un map JSON (API).
  /// N'inclut PAS 'isSynced', 'isDeleted'.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listId': listId, // Envoyé à l'API
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice, // Peut être null
      'isChecked': isChecked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crée une instance ShoppingItem à partir d'un map (SQLite).
  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    if (map['id'] == null || map['listId'] == null || map['name'] == null || map['createdAt'] == null || map['updatedAt'] == null) {
      throw FormatException("Données Map invalides pour ShoppingItem: $map");
    }
    return ShoppingItem(
      id: map['id'] as String,
      listId: map['listId'] as String,
      name: map['name'] as String? ?? '', // Gère null pour la BDD si nécessaire
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0, // SQLite stocke REAL
      unitPrice: (map['unitPrice'] as num?)?.toDouble(), // SQLite stocke REAL, peut être null
      isChecked: (map['isChecked'] as int? ?? 0) == 1, // SQLite: 0 ou 1
      createdAt: DateTime.parse(map['createdAt'] as String).toUtc(), // Stocké comme TEXT
      updatedAt: DateTime.parse(map['updatedAt'] as String).toUtc(), // Stocké comme TEXT
      isSynced: (map['isSynced'] as int? ?? 0) == 1, // SQLite: 0 ou 1
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1, // SQLite: 0 ou 1
    );
  }

  /// Convertit l'instance ShoppingItem en un map (SQLite).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'name': name,
      'quantity': quantity, // Stocké comme REAL
      'unitPrice': unitPrice, // Stocké comme REAL (peut être NULL)
      'isChecked': isChecked ? 1 : 0, // Stocké comme INTEGER (0 ou 1)
      'createdAt': createdAt.toIso8601String(), // Stocké comme TEXT
      'updatedAt': updatedAt.toIso8601String(), // Stocké comme TEXT
      'isSynced': isSynced ? 1 : 0, // Stocké comme INTEGER (0 ou 1)
      'isDeleted': isDeleted ? 1 : 0, // Stocké comme INTEGER (0 ou 1)
      // totalItemPrice n'est pas stocké, il est calculé.
    };
  }

  /// Crée une copie avec des champs potentiellement modifiés.
  /// Pour unitPrice, fournir `null` explicitement si on veut le supprimer,
  /// sinon il garde l'ancienne valeur.
  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    double? quantity,
    // Utiliser Object() comme valeur spéciale pour indiquer "mettre à null" est une option,
    // mais plus complexe. Ici, `null` signifie "ne pas changer", et pour supprimer,
    // il faudrait une méthode spécifique ou passer `null` directement lors de l'appel.
    // Ou plus simple : créer une nouvelle instance avec `unitPrice: null` si besoin.
    double? unitPrice, // Permet de mettre à jour avec une nouvelle valeur
    bool? updateUnitPriceToNull, // Booléen explicite pour supprimer le prix
    bool? isChecked,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: (updateUnitPriceToNull ?? false) ? null : (unitPrice ?? this.unitPrice),
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'ShoppingItem(id: $id, listId: $listId, name: $name, qty: $quantity, price: $unitPrice, checked: $isChecked, synced: $isSynced, deleted: $isDeleted, updatedAt: $updatedAt)';
  }

  // Égalité et HashCode basés sur l'ID unique
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}