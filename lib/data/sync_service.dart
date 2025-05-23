import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tobuy/data/local_repository.dart';
import 'package:tobuy/data/remote_repository.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';

class SyncService {
  final LocalRepository localRepo;
  final RemoteRepository remoteRepo;

  SyncService({required this.localRepo, required this.remoteRepo});

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncData(String userId) async {
    if (!await isOnline()) {
      print('Hors ligne, synchronisation annulée');
      return;
    }

    try {
      print('Début de la synchronisation');

      // Synchroniser les listes
      final localLists = await localRepo.getLists(userId);
      final remoteLists = await remoteRepo.getLists(userId, isOnline: true);

      print('Listes locales: ${localLists.length}, Listes distantes: ${remoteLists.length}');

      // Créer des maps pour comparer les listes par nom et userId
      final remoteListMap = {
        for (var list in remoteLists) '${list.name}:${list.userId}': list,
      };
      final remoteListIds = remoteLists.map((list) => list.id).toSet();

      for (var localList in localLists) {
        final key = '${localList.name}:${localList.userId}';
        if (!remoteListMap.containsKey(key) && !remoteListIds.contains(localList.id)) {
          print('Synchronisation de la liste locale vers le serveur: ${localList.name}');
          final remoteList = await remoteRepo.createList(localList.userId, localList.name, isOnline: true);
          await localRepo.updateListId(localList.id, remoteList.id);
        } else {
          print('Liste déjà existante sur le serveur: ${localList.name}');
        }
      }

      // Synchroniser les items
      for (var list in localLists) {
        final localItems = await localRepo.getItems(list.id);
        final remoteItems = await remoteRepo.getItems(list.id, isOnline: true);

        print('Liste ${list.name} - Items locaux: ${localItems.length}, Items distants: ${remoteItems.length}');

        final remoteItemIds = remoteItems.map((item) => item.id).toSet();

        for (var localItem in localItems) {
          if (!localItem.isSynced || !remoteItemIds.contains(localItem.id)) {
            print('Synchronisation de l\'item local vers le serveur: ${localItem.name}');
            await remoteRepo.addItem(list.id, localItem, isOnline: true);
            await localRepo.updateItem(
              localItem.id,
              isChecked: localItem.isChecked,
              name: localItem.name,
              quantity: localItem.quantity,
              unitPrice: localItem.unitPrice,
            );
          }
        }

        final localItemIds = localItems.map((item) => item.id).toSet();
        for (var remoteItem in remoteItems) {
          if (!localItemIds.contains(remoteItem.id)) {
            print('Synchronisation de l\'item distant vers le local: ${remoteItem.name}');
            await localRepo.addItem(list.id, remoteItem.copyWith(isSynced: true));
          }
        }
      }

      // Synchroniser les invitations
      final userInfo = await localRepo.getUser();
      if (userInfo != null) {
        final localInvitations = await localRepo.getInvitations(userInfo.email);
        final remoteInvitations = await remoteRepo.getInvitations(userInfo.email, isOnline: true);

        print('Invitations locales: ${localInvitations.length}, Invitations distantes: ${remoteInvitations.length}');

        // Créer une map des invitations distantes pour une recherche plus efficace
        final remoteInvitationMap = {
          for (var inv in remoteInvitations) '${inv.listId}:${inv.senderId}:${inv.receiverEmail}': inv,
        };

        for (var localInvitation in localInvitations) {
          final key = '${localInvitation.listId}:${localInvitation.senderId}:${localInvitation.receiverEmail}';
          if (!remoteInvitationMap.containsKey(key) && localInvitation.status == 'pending') {
            print('Synchronisation de l\'invitation locale vers le serveur: ${localInvitation.receiverEmail}');
            await remoteRepo.createInvitation(
              localInvitation.listId,
              localInvitation.listName,
              localInvitation.senderId,
              localInvitation.senderEmail,
              localInvitation.receiverEmail,
              isOnline: true,
            );
            // Mettre à jour le statut local pour éviter une re-synchronisation
            await localRepo.updateInvitationStatus(localInvitation.id, 'synced');
          }
        }
      }

      print('Synchronisation terminée avec succès');
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }
  }
}

extension on LocalRepository {
  Future<void> updateInvitationStatus(String invitationId, String status) async {
    final db = await database;
    await db.update(
      'invitations',
      {'status': status},
      where: 'id = ?',
      whereArgs: [invitationId],
    );
  }
}