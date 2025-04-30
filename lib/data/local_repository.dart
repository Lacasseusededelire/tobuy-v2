import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tobuy/models/user.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/invitation.dart';
import 'package:tobuy/models/uuid_helper.dart';

class LocalRepository {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'tobuy.db');
    return openDatabase(
      path,
      version: 4, // Incrémenter la version pour ajouter la nouvelle table
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE shopping_lists (
            id TEXT PRIMARY KEY,
            name TEXT,
            user_id TEXT,
            collaborator_ids TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE shopping_items (
            id TEXT PRIMARY KEY,
            list_id TEXT,
            name TEXT,
            quantity REAL,
            unit_price REAL,
            created_at INTEGER,
            updated_at INTEGER,
            is_checked INTEGER,
            is_synced INTEGER,
            is_deleted INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE invitations (
            id TEXT PRIMARY KEY,
            list_id TEXT,
            list_name TEXT,
            sender_id TEXT,
            sender_email TEXT,
            receiver_email TEXT,
            status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE item_history (
            name TEXT PRIMARY KEY
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE item_history (
              name TEXT PRIMARY KEY
            )
          ''');
        }
      },
    );
  }

  // Ajouter un nom à l'historique
  Future<void> addItemNameToHistory(String name) async {
    final db = await database;
    await db.insert(
      'item_history',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Récupérer les suggestions d'autocomplétion
  Future<List<String>> getItemNameSuggestions(String query) async {
    final db = await database;
    final maps = await db.query(
      'item_history',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      limit: 4,
    );
    return maps.map((map) => map['name'] as String).toList();
  }

  Future<User?> getUser() async {
    final db = await database;
    final maps = await db.query('users', limit: 1);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User> createUser(String email, String password) async {
    final db = await database;
    final user = User(
      id: UuidHelper.generate(),
      email: email,
      password: password,
    );
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return user;
  }

  Future<User?> login(String email, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<ShoppingList> createList(String userId, String name) async {
    final db = await database;
    final list = ShoppingList(
      id: UuidHelper.generate(),
      name: name,
      userId: userId,
      collaboratorIds: [],
      items: [],
    );
    await db.insert('shopping_lists', list.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return list;
  }

  Future<void> deleteList(String listId) async {
    final db = await database;
    await db.delete('shopping_lists', where: 'id = ?', whereArgs: [listId]);
    await db.delete('shopping_items', where: 'list_id = ?', whereArgs: [listId]);
  }

  Future<List<ShoppingList>> getLists(String userId) async {
    final db = await database;
    final maps = await db.query('shopping_lists', where: 'user_id = ? OR collaborator_ids LIKE ?', whereArgs: [userId, '%$userId%']);
    final lists = maps.map((map) => ShoppingList.fromMap(map)).toList();
    for (var list in lists) {
      final items = await getItems(list.id);
      list.items = items;
    }
    return lists;
  }

  Future<void> addItem(String listId, ShoppingItem item) async {
    final db = await database;
    await db.insert('shopping_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteItem(String itemId) async {
    final db = await database;
    await db.update(
      'shopping_items',
      {'is_deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> updateItem(
    String itemId, {
    String? name,
    double? quantity,
    double? unitPrice,
    bool? isChecked,
  }) async {
    final db = await database;
    final updates = {
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (isChecked != null) 'is_checked': isChecked ? 1 : 0,
    };
    await db.update(
      'shopping_items',
      updates,
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<ShoppingItem>> getItems(String listId) async {
    final db = await database;
    final maps = await db.query(
      'shopping_items',
      where: 'list_id = ? AND is_deleted = ?',
      whereArgs: [listId, 0],
    );
    return maps.map((map) => ShoppingItem.fromMap(map)).toList();
  }

  Future<void> createInvitation(
      String listId, String listName, String senderId, String senderEmail, String receiverEmail) async {
    final db = await database;
    final invitation = Invitation(
      id: UuidHelper.generate(),
      listId: listId,
      listName: listName,
      senderId: senderId,
      senderEmail: senderEmail,
      receiverEmail: receiverEmail,
      status: 'pending',
    );
    await db.insert('invitations', invitation.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> acceptInvitation(String invitationId, String userId) async {
    final db = await database;
    final invitationMaps = await db.query(
      'invitations',
      where: 'id = ?',
      whereArgs: [invitationId],
    );
    if (invitationMaps.isEmpty) throw Exception('Invitation non trouvée');
    final invitation = Invitation.fromMap(invitationMaps.first);

    await db.update(
      'invitations',
      {'status': 'accepted'},
      where: 'id = ?',
      whereArgs: [invitationId],
    );

    final listMaps = await db.query(
      'shopping_lists',
      where: 'id = ?',
      whereArgs: [invitation.listId],
    );
    if (listMaps.isEmpty) throw Exception('Liste non trouvée');
    final list = ShoppingList.fromMap(listMaps.first);
    final updatedCollaborators = [...list.collaboratorIds, userId];
    await db.update(
      'shopping_lists',
      {'collaborator_ids': updatedCollaborators.join(',')},
      where: 'id = ?',
      whereArgs: [invitation.listId],
    );
  }

  Future<void> rejectInvitation(String invitationId) async {
    final db = await database;
    await db.update(
      'invitations',
      {'status': 'rejected'},
      where: 'id = ?',
      whereArgs: [invitationId],
    );
  }

  Future<List<Invitation>> getInvitations(String userEmail) async {
    final db = await database;
    final maps = await db.query(
      'invitations',
      where: 'receiver_email = ?',
      whereArgs: [userEmail],
    );
    return maps.map((map) => Invitation.fromMap(map)).toList();
  }
  
}