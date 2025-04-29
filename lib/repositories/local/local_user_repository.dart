import 'package:sqflite/sqflite.dart';
import 'package:tobuy/models/user.dart';
import 'package:tobuy/services/local/database_helper.dart';

class LocalUserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String _tableName = 'users';

  // Insère ou met à jour l'utilisateur local (typiquement après login/register)
  Future<int> upsertUser(User user) async {
    final db = await _dbHelper.database;
    print("Upserting user locally: ${user.id} / ${user.email}");
    return await db.insert(
      _tableName,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Remplace si l'ID existe
    );
  }

  // Récupère l'utilisateur local (on suppose qu'il n'y en a qu'un)
  Future<User?> getLocalUser() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      limit: 1, // Il ne devrait y avoir qu'un seul utilisateur connecté localement
    );
    if (maps.isNotEmpty) {
      print("Found local user: ${maps.first['email']}");
      return User.fromMap(maps.first);
    }
    print("No local user found.");
    return null;
  }

  // Récupère un utilisateur par son ID (si nécessaire)
  Future<User?> getUserById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }


  // Supprime les données de l'utilisateur local (lors de la déconnexion)
  Future<int> deleteLocalUser() async {
    final db = await _dbHelper.database;
    print("Deleting local user data...");
    // Supprime toutes les lignes (il ne devrait y en avoir qu'une)
    return await db.delete(_tableName);
  }
}