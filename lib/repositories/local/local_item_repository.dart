import 'package:sqflite/sqflite.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/uuid_helper.dart';
import 'package:tobuy/services/local/database_helper.dart';

class LocalItemRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String _tableName = 'shopping_items';

  // --- Opérations CRUD Basiques ---

  // Crée un NOUVEL item localement
  Future<ShoppingItem> createNewItem({
    required String listId,
    required String name,
    double quantity = 1.0,
    double? unitPrice,
    bool isChecked = false,
  }) async {
    final now = DateTime.now().toUtc();
    final newItem = ShoppingItem(
      id: UuidHelper.generate(),
      listId: listId,
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      isChecked: isChecked,
      createdAt: now,
      updatedAt: now,
      isSynced: false, // Nouveau, non synchronisé
      isDeleted: false,
    );
    await _insertOrReplace(newItem);
    print("Created new item locally: ${newItem.id} for list $listId");
    // Mettre à jour le timestamp de la liste parente pour indiquer un changement
    await _touchList(listId);
    return newItem;
  }

  // Met à jour un item existant localement
  Future<int> updateItem(ShoppingItem item) async {
    final db = await _dbHelper.database;
    item.isSynced = false; // Changement local -> non synchronisé
    item.updatedAt = DateTime.now().toUtc();
    print("Updating item locally: ${item.id}");
    int count = await db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    // Mettre à jour le timestamp de la liste parente
    await _touchList(item.listId);
    return count;
  }

  // Soft delete: Marque l'item comme supprimé et à synchroniser
  Future<int> markItemAsDeleted(String id, String listId) async {
    final db = await _dbHelper.database;
    print("Marking item as deleted locally: $id");
    int count = await db.update(
      _tableName,
      {
        'isDeleted': 1,
        'isSynced': 0,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
    );
    // Mettre à jour le timestamp de la liste parente
    await _touchList(listId);
    return count;
  }

  // Récupère un item par ID (non supprimé)
  Future<ShoppingItem?> getItemById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ShoppingItem.fromMap(maps.first);
    }
    return null;
  }

  // Récupère tous les items d'une liste spécifique (non supprimés)
  Future<List<ShoppingItem>> getItemsForList(String listId) async {
    final db = await _dbHelper.database;
    print("Fetching items for list: $listId");
    final maps = await db.query(
      _tableName,
      where: 'listId = ? AND isDeleted = 0',
      whereArgs: [listId],
      orderBy: 'createdAt ASC', // Ou 'name ASC'
    );
    return maps.map((map) => ShoppingItem.fromMap(map)).toList();
  }

  // --- Opérations Spécifiques à la Synchronisation ---

  Future<int> _insertOrReplace(ShoppingItem item) async {
    final db = await _dbHelper.database;
    return await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupère les items modifiés localement et non synchronisés
  Future<List<ShoppingItem>> getUnsyncedItems() async {
    final db = await _dbHelper.database;
    print("Fetching unsynced items...");
    final maps = await db.query(
      _tableName,
      where: 'isSynced = 0',
    );
    return maps.map((map) => ShoppingItem.fromMap(map)).toList();
  }

  // Marque un item comme synchronisé
  Future<int> markItemAsSynced(String id, DateTime serverUpdatedAt) async {
    final db = await _dbHelper.database;
    print("Marking item as synced: $id");
    return await db.update(
      _tableName,
      {
        'isSynced': 1,
        'updatedAt': serverUpdatedAt.toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Upsert un item venant du serveur
  Future<void> upsertItemFromServer(ShoppingItem item) async {
    print("Upserting item from server: ${item.id}");
    item.isSynced = true;
    item.isDeleted = item.isDeleted; // Conserve le statut du serveur
    await _insertOrReplace(item);
  }

  // Supprime physiquement un item (appelé par SyncService ou ON DELETE CASCADE)
  Future<int> deleteItemPermanently(String id) async {
    final db = await _dbHelper.database;
    print("Deleting item permanently from local DB: $id");
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprime physiquement les items marqués 'isDeleted=1' et 'isSynced=1' (nettoyage)
  Future<int> cleanupDeletedItems() async {
    final db = await _dbHelper.database;
    print("Cleaning up deleted and synced items...");
    int count = await db.delete(
      _tableName,
      where: 'isDeleted = 1 AND isSynced = 1',
    );
    print("$count deleted items cleaned up.");
    return count;
  }

  // Met à jour le timestamp 'updatedAt' de la liste parente pour indiquer un changement
  // et la marquer comme non synchronisée si elle ne l'était pas déjà pour les items
  Future<void> _touchList(String listId) async {
    final db = await _dbHelper.database;
    print("Touching list: $listId due to item change");
    await db.update(
      'shopping_lists', // Nom de la table des listes
      {
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'isSynced': 0 // La liste elle-même doit être resynchronisée car son contenu a changé
      },
      where: 'id = ?',
      whereArgs: [listId],
    );
  }
}