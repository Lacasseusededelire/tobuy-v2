import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/invitation.dart'; // Si les invitations sont synchronisées
import 'package:tobuy/repositories/local/local_list_repository.dart';
import 'package:tobuy/repositories/local/local_item_repository.dart';
import 'package:tobuy/repositories/local/local_invitation_repository.dart'; // Si nécessaire
import 'package:tobuy/services/api/api_client.dart';

// Enum pour l'état de la synchronisation (utilisé par P3 via Riverpod)
enum SyncStatus { idle, syncing, success, error }

// Callback pour notifier P3 (ou un Provider Riverpod)
typedef SyncStatusCallback = void Function(SyncStatus status, [String? message]);

class SyncService {
  final LocalListRepository _listRepo = LocalListRepository();
  final LocalItemRepository _itemRepo = LocalItemRepository();
  final LocalInvitationRepository _invitationRepo = LocalInvitationRepository(); // Ajouté
  final ApiClient _apiClient = ApiClient();
  final String _lastSyncTimestampKey = 'lastSyncTimestamp_v2'; // Clé pour SharedPreferences

  bool _isSyncing = false; // Verrou pour éviter les synchronisations concurrentes

  // Callback pour informer l'extérieur (ex: un Provider Riverpod)
  SyncStatusCallback? onSyncStatusChanged;

  // Méthode principale pour démarrer la synchronisation
  Future<void> synchronize({bool force = false}) async {
    if (_isSyncing && !force) {
      print('SyncService: Sync already in progress.');
      onSyncStatusChanged?.call(SyncStatus.syncing, "Synchronisation déjà en cours.");
      return;
    }

    _isSyncing = true;
    print('SyncService: Starting synchronization...');
    onSyncStatusChanged?.call(SyncStatus.syncing, "Démarrage de la synchronisation...");

    String? finalErrorMessage; // Pour stocker un message d'erreur final

    try {
      final lastSyncTimestamp = await _getLastSyncTimestamp();
      print('SyncService: Last sync timestamp: $lastSyncTimestamp');

      // --- 1. Rassembler les changements locaux ---
      print('SyncService: Gathering local changes...');
      final unsyncedLists = await _listRepo.getUnsyncedLists();
      final unsyncedItems = await _itemRepo.getUnsyncedItems();
      // final unsyncedInvitations = await _invitationRepo.getUnsyncedInvitations(); // Moins probable

      // Structure attendue par P1 (EXEMPLE - À VALIDER ABSOLUMENT AVEC P1)
      final Map<String, dynamic> localChangesPayload = {
        'lists': {
          'upsert': unsyncedLists.where((l) => !l.isDeleted).map((l) => l.toJson()).toList(),
          'delete': unsyncedLists.where((l) => l.isDeleted).map((l) => l.id).toList(),
        },
        'items': {
          'upsert': unsyncedItems.where((i) => !i.isDeleted).map((i) => i.toJson()).toList(),
          'delete': unsyncedItems.where((i) => i.isDeleted).map((i) => i.id).toList(),
        },
        // 'invitations': { ... } // Si applicable
      };
      final bool hasLocalChanges = unsyncedLists.isNotEmpty || unsyncedItems.isNotEmpty;
      print('SyncService: Found ${unsyncedLists.length} unsynced lists, ${unsyncedItems.length} unsynced items.');


      // --- 2. Communiquer avec le serveur ---
      Response? response;
      String serverResponseTimestamp = DateTime.now().toUtc().toIso8601String(); // Timestamp par défaut

      final syncPayload = {
        'lastSyncTimestamp': lastSyncTimestamp,
        'changes': localChangesPayload,
      };

      if (hasLocalChanges) {
        print('SyncService: Sending local changes and fetching server changes (POST /sync)...');
        response = await _apiClient.synchronizeData(syncPayload);
      } else {
        print('SyncService: No local changes. Fetching server changes (GET /sync)...');
        response = await _apiClient.fetchServerChanges(lastSyncTimestamp);
      }

      // --- 3. Traiter la réponse du serveur ---
      if (response != null && (response.statusCode == 200 || response.statusCode == 201) ) {
        print('SyncService: Server response received successfully.');
        final responseData = response.data;

        // Récupérer le timestamp fiable du serveur (CRUCIAL - P1 doit le fournir)
        serverResponseTimestamp = responseData['serverTimestamp'] ?? serverResponseTimestamp;
        print('SyncService: Server timestamp for next sync: $serverResponseTimestamp');

        // --- 4. Appliquer les changements serveur localement ---
        final serverChanges = responseData['changes'];
        if (serverChanges != null && serverChanges is Map<String, dynamic>) {
          print('SyncService: Applying server changes locally...');
          // --- Traiter les Listes ---
          await _applyServerListChanges(serverChanges['lists']);
          // --- Traiter les Items ---
          await _applyServerItemChanges(serverChanges['items']);
          // --- Traiter les Invitations ---
          await _applyServerInvitationChanges(serverChanges['invitations']);
          print('SyncService: Finished applying server changes.');
        } else {
          print('SyncService: No changes received from server or invalid format.');
        }


        // --- 5. Marquer les changements locaux comme synchronisés (SI envoyés avec succès) ---
        if (hasLocalChanges) {
          print('SyncService: Marking local changes as synced...');
          final serverTime = DateTime.parse(serverResponseTimestamp).toUtc();
          await _markLocalListsAsSynced(unsyncedLists, serverTime);
          await _markLocalItemsAsSynced(unsyncedItems, serverTime);
          // await _markLocalInvitationsAsSynced(unsyncedInvitations, serverTime); // Si applicable
          print('SyncService: Finished marking local changes as synced.');
        }


        // --- 6. Optionnel : Nettoyage ---
        // print('SyncService: Performing cleanup...');
        // await _listRepo.cleanupDeletedLists();
        // await _itemRepo.cleanupDeletedItems();
        // await _invitationRepo.cleanupProcessedInvitations();
        // print('SyncService: Cleanup finished.');


        // --- 7. Mettre à jour le timestamp de la dernière synchro réussie ---
        await _setLastSyncTimestamp(serverResponseTimestamp);
        print('SyncService: Synchronization finished successfully.');
        onSyncStatusChanged?.call(SyncStatus.success, "Synchronisation réussie.");

      } else {
        // Gérer les erreurs de réponse HTTP
        final errorMsg = "Erreur serveur: ${response?.statusCode} ${response?.statusMessage}";
        print('SyncService: Synchronization failed. $errorMsg');
        finalErrorMessage = errorMsg;
        onSyncStatusChanged?.call(SyncStatus.error, errorMsg);
      }

    } on DioException catch (e) {
      String errorMsg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMsg = "Erreur réseau. Vérifiez votre connexion.";
        print('SyncService: Network error during sync: $e');
      } else if (e.response != null) {
        errorMsg = "Erreur serveur (${e.response?.statusCode}): ${e.response?.data?['message'] ?? e.message}";
        print('SyncService: Server error response during sync: ${e.response?.data}');
      } else {
        errorMsg = "Erreur inconnue lors de la communication.";
        print('SyncService: Unknown Dio error during sync: $e');
      }
      finalErrorMessage = errorMsg;
      onSyncStatusChanged?.call(SyncStatus.error, errorMsg);

    } catch (e, s) {
      final errorMsg = "Erreur inattendue: ${e.toString()}";
      print('SyncService: Unexpected error during synchronization: $e\n$s');
      finalErrorMessage = errorMsg;
      onSyncStatusChanged?.call(SyncStatus.error, errorMsg);
    } finally {
      _isSyncing = false; // Libérer le verrou
      // Si une erreur s'est produite, assurez-vous que le statut final est 'error'
      if (finalErrorMessage != null) {
        onSyncStatusChanged?.call(SyncStatus.error, finalErrorMessage);
        print('SyncService: Synchronization finished with error.');
      } else if (onSyncStatusChanged != null){
        // Si pas d'erreur mais pas encore de succès (devrait pas arriver ici mais par sécurité)
        // onSyncStatusChanged!(SyncStatus.idle); // Ou laisser le dernier statut succès
      }
    }
  }

  // --- Méthodes d'aide privées ---

  Future<String> _getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncTimestampKey) ?? DateTime.fromMillisecondsSinceEpoch(0).toUtc().toIso8601String();
  }

  Future<void> _setLastSyncTimestamp(String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncTimestampKey, timestamp);
    print("Saved last sync timestamp: $timestamp");
  }

  Future<void> _applyServerListChanges(dynamic listChanges) async {
    if (listChanges == null || listChanges is! Map<String, dynamic>) return;

    // Upserts (Create/Update)
    final listsToUpsert = (listChanges['upsert'] as List<dynamic>? ?? [])
        .map((data) => ShoppingList.fromJson(data as Map<String, dynamic>))
        .toList();
    print("Applying ${listsToUpsert.length} list upserts from server.");
    for (var list in listsToUpsert) {
      await _listRepo.upsertListFromServer(list);
    }

    // Deletes
    final listIdsToDelete = List<String>.from(listChanges['delete'] ?? []);
    print("Applying ${listIdsToDelete.length} list deletes from server.");
    for (var listId in listIdsToDelete) {
      await _listRepo.deleteListPermanently(listId);
    }
  }

  Future<void> _applyServerItemChanges(dynamic itemChanges) async {
    if (itemChanges == null || itemChanges is! Map<String, dynamic>) return;

    // Upserts (Create/Update)
    final itemsToUpsert = (itemChanges['upsert'] as List<dynamic>? ?? [])
        .map((data) => ShoppingItem.fromJson(data as Map<String, dynamic>))
        .toList();
    print("Applying ${itemsToUpsert.length} item upserts from server.");
    for (var item in itemsToUpsert) {
      await _itemRepo.upsertItemFromServer(item);
    }

    // Deletes
    final itemIdsToDelete = List<String>.from(itemChanges['delete'] ?? []);
    print("Applying ${itemIdsToDelete.length} item deletes from server.");
    for (var itemId in itemIdsToDelete) {
      await _itemRepo.deleteItemPermanently(itemId);
    }
  }

  Future<void> _applyServerInvitationChanges(dynamic invitationChanges) async {
    if (invitationChanges == null || invitationChanges is! Map<String, dynamic>) return;

    // Upserts (Create/Update)
    final invitationsToUpsert = (invitationChanges['upsert'] as List<dynamic>? ?? [])
        .map((data) => Invitation.fromJson(data as Map<String, dynamic>))
        .toList();
    print("Applying ${invitationsToUpsert.length} invitation upserts from server.");
    for (var inv in invitationsToUpsert) {
      await _invitationRepo.upsertInvitationFromServer(inv);
    }

    // Deletes (Moins courant pour les invitations, mais possible)
    final invitationIdsToDelete = List<String>.from(invitationChanges['delete'] ?? []);
    print("Applying ${invitationIdsToDelete.length} invitation deletes from server.");
    for (var invId in invitationIdsToDelete) {
      await _invitationRepo.deleteInvitationPermanently(invId);
    }
  }


  Future<void> _markLocalListsAsSynced(List<ShoppingList> lists, DateTime syncTime) async {
    for (var list in lists) {
      if (list.isDeleted) {
        // Si la suppression a été synchronisée, on peut la nettoyer OU juste la marquer
        // await _listRepo.deleteListPermanently(list.id); // Option nettoyage immédiat
        // Marquer synchro même si supprimé, pour le nettoyage ultérieur
        await _listRepo.markListAsSynced(list.id, syncTime);
      } else {
        await _listRepo.markListAsSynced(list.id, syncTime);
      }
    }
  }

  Future<void> _markLocalItemsAsSynced(List<ShoppingItem> items, DateTime syncTime) async {
    for (var item in items) {
      if (item.isDeleted) {
        // await _itemRepo.deleteItemPermanently(item.id); // Option nettoyage immédiat
        await _itemRepo.markItemAsSynced(item.id, syncTime);
      } else {
        await _itemRepo.markItemAsSynced(item.id, syncTime);
      }
    }
  }

// Ajouter _markLocalInvitationsAsSynced si nécessaire
}