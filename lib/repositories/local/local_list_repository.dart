import 'dart:convert'; // Pour encoder/décoder collaboratorIds
import 'package:sqflite/sqflite.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/uuid_helper.dart'; // Ou import 'package:uuid/uuid.dart';
import 'package:tobuy/services/local/database_helper.dart';

class LocalListRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String _tableName = 'shopping_lists';

  // --- Opérations CRUD Basiques (Utilisées par P3 via Providers) ---

  // Crée une NOUVELLE liste localement (non synchronisée initialement)
  Future<ShoppingList> createNewList(String name, String ownerId) async {
    final now = DateTime.now().toUtc();
    final newList = ShoppingList(
      id: UuidHelper.generate(), // Génère un nouvel UUID v4
      ownerId: ownerId,
      name: name,
      collaboratorIds: [], // Commence sans collaborateurs
      createdAt: now,
      updatedAt: now,
      isSynced: false, // Nouvelle liste, pas encore synchronisée
      isDeleted: false,
    );
    await _insertOrReplace(newList); // Sauvegarde en BDD locale
    print("Created new list locally: ${newList.id}");
    return newList;
  }

  // Met à jour une liste existante localement
  Future<int> updateList(ShoppingList list) async {
    final db = await _dbHelper.database;
    // Marque comme non synchronisé lors de la mise à jour manuelle
    list.isSynced = false;
    list.updatedAt = DateTime.now().toUtc(); // Mettre à jour le timestamp
    print("Updating list locally: ${list.id}");
    return await db.update(
      _tableName,
      list.toMap(), // Assurez-vous que toMap inclut isSynced et updatedAt
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  // Soft delete: Marque la liste comme supprimée et à synchroniser
  Future<int> markListAsDeleted(String id) async {
    final db = await _dbHelper.database;
    print("Marking list as deleted locally: $id");
    return await db.update(
      _tableName,
      {
        'isDeleted': 1,
        'isSynced': 0, // Doit être synchronisé pour informer le serveur
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND isDeleted = 0', // Évite les updates si déjà marquée
      whereArgs: [id],
    );
  }

  // Récupère une liste par son ID (non supprimée)
  Future<ShoppingList?> getListById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ShoppingList.fromMap(maps.first);
    }
    print("List not found locally or marked deleted: $id");
    return null;
  }

  // Récupère TOUTES les listes disponibles localement (non supprimées)
  // Utilisé par P3 pour afficher les listes après synchronisation.
  Future<List<ShoppingList>> getAllAvailableLists() async {
    final db = await _dbHelper.database;
    print("Fetching all available lists locally...");
    final maps = await db.query(
      _tableName,
      where: 'isDeleted = 0',
      orderBy: 'updatedAt DESC', // Ou 'name ASC'
    );
    return maps.map((map) => ShoppingList.fromMap(map)).toList();
  }


  // --- Opérations Spécifiques à la Synchronisation (Utilisées par SyncService) ---

  // Insère ou Remplace une liste (utilisé en interne et pour upsert serveur)
  Future<int> _insertOrReplace(ShoppingList list) async {
    final db = await _dbHelper.database;
    return await db.insert(
      _tableName,
      list.toMap(), // Convertit l'objet en Map pour SQLite
      conflictAlgorithm: ConflictAlgorithm.replace, // Remplace si l'ID existe
    );
  }

  // Récupère les listes modifiées localement et non encore synchronisées
  Future<List<ShoppingList>> getUnsyncedLists() async {
    final db = await _dbHelper.database;
    print("Fetching unsynced lists...");
    final maps = await db.query(
      _tableName,
      where: 'isSynced = 0', // Récupère créations, updates ET suppressions marquées
    );
    return maps.map((map) => ShoppingList.fromMap(map)).toList();
  }

  // Marque une liste comme synchronisée (après confirmation du serveur)
  Future<int> markListAsSynced(String id, DateTime serverUpdatedAt) async {
    final db = await _dbHelper.database;
    print("Marking list as synced: $id");
    return await db.update(
      _tableName,
      {
        'isSynced': 1,
        'updatedAt': serverUpdatedAt.toUtc().toIso8601String(), // Utilise le timestamp du serveur
        // isDeleted reste tel quel (peut être 1 si la suppression a été synchro)
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Insère ou Met à jour une liste venant du serveur (Upsert)
  Future<void> upsertListFromServer(ShoppingList list) async {
    print("Upserting list from server: ${list.id}");
    // Marque la liste comme synchronisée car elle vient du serveur
    list.isSynced = true;
    // Le serveur doit indiquer si elle est supprimée via un autre champ/endpoint
    // Ici, on assume que si elle est dans la liste 'upsert', elle n'est pas supprimée.
    // Si le serveur renvoie aussi des listes supprimées, il faudra ajuster.
    list.isDeleted = list.isDeleted; // Conserve le statut deleted du serveur si fourni

    await _insertOrReplace(list);
  }

  // Supprime physiquement une liste (appelé par SyncService pour les suppressions confirmées par le serveur)
  Future<int> deleteListPermanently(String id) async {
    final db = await _dbHelper.database;
    print("Deleting list permanently from local DB: $id");
    // Grâce à ON DELETE CASCADE, les items associés seront aussi supprimés.
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprime physiquement les listes marquées 'isDeleted=1' et 'isSynced=1' (nettoyage)
  // Peut être appelé périodiquement par SyncService
  Future<int> cleanupDeletedLists() async {
    final db = await _dbHelper.database;
    print("Cleaning up deleted and synced lists...");
    int count = await db.delete(
      _tableName,
      where: 'isDeleted = 1 AND isSynced = 1',
    );
    print("$count deleted lists cleaned up.");
    return count;
  }
}