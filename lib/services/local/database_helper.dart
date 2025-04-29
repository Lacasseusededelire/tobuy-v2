import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io'; // Pour Directory

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'tobuy_app.db';
  static const int _dbVersion = 1; // Incrémentez si vous changez le schéma

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    print('Database path: $path'); // Utile pour le débogage

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure, // Activer les clés étrangères
      // onUpgrade: _onUpgrade, // Ajoutez pour gérer les migrations futures
    );
  }

  // Activer le support des clés étrangères pour SQLite
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    print("Foreign keys enabled");
  }

  // Création des tables lors de la première ouverture de la BDD
  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables...");
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,          -- UUID
        email TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL,      -- ISO8601 String UTC
        updatedAt TEXT NOT NULL       -- ISO8601 String UTC
      )
    ''');
    print("Table 'users' created.");

    await db.execute('''
      CREATE TABLE shopping_lists (
        id TEXT PRIMARY KEY,          -- UUID
        ownerId TEXT NOT NULL,        -- UUID du propriétaire
        name TEXT NOT NULL,
        collaboratorIds TEXT,         -- Stocké comme JSON String '["uuid1", "uuid2"]' ou NULL
        createdAt TEXT NOT NULL,      -- ISO8601 String UTC
        updatedAt TEXT NOT NULL,      -- ISO8601 String UTC
        isSynced INTEGER NOT NULL DEFAULT 0, -- 0 = false, 1 = true
        isDeleted INTEGER NOT NULL DEFAULT 0 -- 0 = false (active), 1 = true (soft deleted)
        -- FOREIGN KEY (ownerId) REFERENCES users(id) -- Peut être ajouté si la table users est toujours peuplée
      )
    ''');
    print("Table 'shopping_lists' created.");

    await db.execute('''
      CREATE TABLE shopping_items (
        id TEXT PRIMARY KEY,          -- UUID
        listId TEXT NOT NULL,         -- UUID de la liste parente
        name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1.0,
        unitPrice REAL,               -- Peut être NULL
        isChecked INTEGER NOT NULL DEFAULT 0, -- 0 = false, 1 = true
        createdAt TEXT NOT NULL,      -- ISO8601 String UTC
        updatedAt TEXT NOT NULL,      -- ISO8601 String UTC
        isSynced INTEGER NOT NULL DEFAULT 0,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (listId) REFERENCES shopping_lists(id) ON DELETE CASCADE -- Supprime les items si la liste est supprimée
      )
    ''');
    print("Table 'shopping_items' created.");

    await db.execute('''
      CREATE TABLE invitations (
          id TEXT PRIMARY KEY,          -- UUID
          listId TEXT NOT NULL,         -- UUID de la liste
          listName TEXT NOT NULL,       -- Nom dénormalisé pour affichage
          inviterId TEXT NOT NULL,      -- UUID de l'inviteur
          inviterEmail TEXT NOT NULL,   -- Email dénormalisé
          inviteeEmail TEXT NOT NULL,   -- Email de la personne invitée
          status TEXT NOT NULL,         -- 'pending', 'accepted', 'rejected'
          createdAt TEXT NOT NULL,      -- ISO8601 String UTC
          updatedAt TEXT NOT NULL       -- ISO8601 String UTC
      )
    ''');
    print("Table 'invitations' created.");
    print("Database tables created successfully.");
  }

  // Exemple de fonction pour une future migration (si vous passez à version: 2)
  // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   print("Upgrading database from version $oldVersion to $newVersion");
  //   if (oldVersion < 2) {
  //     // Exemple: Ajouter une colonne à une table existante
  //     // await db.execute("ALTER TABLE shopping_lists ADD COLUMN description TEXT;");
  //     print("Database upgraded to version 2.");
  //   }
  //   // Ajouter d'autres blocs if pour les versions suivantes
  // }

  // Méthode pour fermer la base de données (optionnel)
  Future<void> close() async {
    final db = await database;
    if (db.isOpen) {
      await db.close();
      _database = null; // Reset state
      print("Database closed.");
    }
  }
}