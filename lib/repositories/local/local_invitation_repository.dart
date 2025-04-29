import 'package:sqflite/sqflite.dart';
import 'package:tobuy/models/invitation.dart';
import 'package:tobuy/services/local/database_helper.dart';

class LocalInvitationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String _tableName = 'invitations';

  // --- Opérations CRUD et de Synchronisation ---

  // Insère ou remplace une invitation (utilisé par SyncService)
  Future<int> upsertInvitationFromServer(Invitation invitation) async {
    final db = await _dbHelper.database;
    print("Upserting invitation from server: ${invitation.id}");
    return await db.insert(
      _tableName,
      invitation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupère une invitation par ID
  Future<Invitation?> getInvitationById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Invitation.fromMap(maps.first);
    }
    return null;
  }

  // Récupère toutes les invitations PENDING pour l'email de l'utilisateur actuel
  Future<List<Invitation>> getPendingInvitationsForEmail(String userEmail) async {
    final db = await _dbHelper.database;
    print("Fetching pending invitations for email: $userEmail");
    final maps = await db.query(
      _tableName,
      where: 'inviteeEmail = ? AND status = ?',
      whereArgs: [userEmail, 'pending'], // Utilise la valeur string de l'enum status
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Invitation.fromMap(map)).toList();
  }

  // Supprime physiquement une invitation (après traitement ou nettoyage)
  Future<int> deleteInvitationPermanently(String id) async {
    final db = await _dbHelper.database;
    print("Deleting invitation permanently from local DB: $id");
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Met à jour le statut local d'une invitation (pas synchronisé directement)
  // L'acceptation/refus déclenche un appel API (géré par P3),
  // la mise à jour viendra via la synchro. Cette méthode est donc moins utile.
  // Future<int> updateInvitationStatusLocally(String id, InvitationStatus status) async {
  //   final db = await _dbHelper.database;
  //   return await db.update(
  //     _tableName,
  //     {'status': status.toString().split('.').last},
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
  // }

  // Supprime toutes les invitations locales (ex: à la déconnexion)
  Future<int> deleteAllInvitations() async {
    final db = await _dbHelper.database;
    print("Deleting all local invitations...");
    return await db.delete(_tableName);
  }

  // Nettoyage : Supprime les invitations qui ne sont plus 'pending'
  // Peut être appelé par SyncService ou P3
  Future<int> cleanupProcessedInvitations() async {
    final db = await _dbHelper.database;
    print("Cleaning up processed (non-pending) invitations...");
    int count = await db.delete(
      _tableName,
      where: 'status != ?',
      whereArgs: ['pending'],
    );
    print("$count processed invitations cleaned up.");
    return count;
  }
}