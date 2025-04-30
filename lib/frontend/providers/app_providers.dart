import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/data/local_repository.dart';
import 'package:tobuy/data/remote_repository.dart';
import 'package:tobuy/data/sync_service.dart';
import 'package:tobuy/models/user.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/invitation.dart';
import 'package:tobuy/frontend/utils/export_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Fournir Dio
final dioProvider = Provider<Dio>((ref) => Dio());

// Fournir LocalRepository
final localRepositoryProvider = Provider<LocalRepository>((ref) {
  return LocalRepository();
});

// Fournir RemoteRepository
final remoteRepositoryProvider = Provider<RemoteRepository>((ref) {
  final localRepo = ref.read(localRepositoryProvider);
  final dio = ref.read(dioProvider);
  return RemoteRepository(dio: dio, localRepo: localRepo);
});

// Fournir SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final localRepo = ref.read(localRepositoryProvider);
  final remoteRepo = ref.read(remoteRepositoryProvider);
  return SyncService(localRepo: localRepo, remoteRepo: remoteRepo);
});

// Fournir un provider pour vérifier la connectivité
final connectivityProvider = FutureProvider<bool>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  return await syncService.isOnline();
});

final authProvider = StateProvider<User?>((ref) => null);

final shoppingListsProvider = FutureProvider.family<List<ShoppingList>, String>((ref, userId) async {
  final localRepo = ref.read(localRepositoryProvider);
  final syncService = ref.read(syncServiceProvider);
  final isOnline = await syncService.isOnline();
  if (isOnline) {
    try {
      await syncService.syncData(userId);
    } catch (e) {
      print('Erreur synchronisation listes: $e');
      // On continue avec les données locales en cas d'erreur
    }
  }
  return localRepo.getLists(userId);
});

final selectedListIdProvider = StateProvider<String?>((ref) => null);

final selectedListProvider = FutureProvider<ShoppingList?>((ref) async {
  final listId = ref.watch(selectedListIdProvider);
  if (listId == null) return null;
  final localRepo = ref.read(localRepositoryProvider);
  final lists = await localRepo.getLists(ref.watch(authProvider)!.id);
  return lists.firstWhere((list) => list.id == listId);
});

final itemsProvider = FutureProvider.family<List<ShoppingItem>, String>((ref, listId) async {
  final localRepo = ref.read(localRepositoryProvider);
  final remoteRepo = ref.read(remoteRepositoryProvider);
  final syncService = ref.read(syncServiceProvider);
  final isOnline = await syncService.isOnline();
  if (isOnline) {
    try {
      final remoteItems = await remoteRepo.getItems(listId, isOnline: isOnline);
      for (var item in remoteItems) {
        await localRepo.addItem(listId, item.copyWith(isSynced: true));
      }
    } catch (e) {
      print('Erreur récupération items serveur: $e');
      // On continue avec les données locales en cas d'erreur
    }
  }
  return localRepo.getItems(listId);
});

final invitationsProvider = FutureProvider<List<Invitation>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return [];
  final localRepo = ref.read(localRepositoryProvider);
  final remoteRepo = ref.read(remoteRepositoryProvider);
  final syncService = ref.read(syncServiceProvider);
  final isOnline = await syncService.isOnline();
  if (isOnline) {
    try {
      final remoteInvitations = await remoteRepo.getInvitations(user.email, isOnline: isOnline);
      for (var invitation in remoteInvitations) {
        await localRepo.createInvitation(
          invitation.listId,
          invitation.listName,
          invitation.senderId,
          invitation.senderEmail,
          invitation.receiverEmail,
        );
        if (invitation.status == 'accepted') {
          await localRepo.acceptInvitation(invitation.id, invitation.senderId);
        } else if (invitation.status == 'rejected') {
          await localRepo.rejectInvitation(invitation.id);
        }
      }
    } catch (e) {
      print('Erreur récupération invitations serveur: $e');
      // On continue avec les données locales en cas d'erreur
    }
  }
  return localRepo.getInvitations(user.email);
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});