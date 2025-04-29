import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/models/user.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/invitation.dart';
import 'package:tobuy/models/suggestion.dart';
import 'package:tobuy/frontend/repositories/local_repository.dart';
import 'package:tobuy/frontend/utils/export_service.dart';
import 'package:tobuy/ia/services/gemini_service.dart';

final localRepositoryProvider = Provider<LocalRepository>((ref) => LocalRepository());

final authProvider = StateProvider<User?>((ref) => null);

final shoppingListsProvider = FutureProvider.family<List<ShoppingList>, String>((ref, userId) async {
  final repo = ref.read(localRepositoryProvider);
  return await repo.getLists(userId);
});

final selectedListIdProvider = StateProvider<String?>((ref) => null);

final selectedListProvider = FutureProvider<ShoppingList?>((ref) async {
  final listId = ref.watch(selectedListIdProvider);
  if (listId == null) return null;
  final repo = ref.read(localRepositoryProvider);
  final items = await ref.watch(itemsProvider(listId).future);
  final list = await repo.getListWithItems(listId);
  print('selectedListProvider rechargé pour liste $listId, items: ${items.length}');
  return list.copyWith(items: items);
});

final itemsProvider = FutureProvider.family<List<ShoppingItem>, String>((ref, listId) async {
  final repo = ref.read(localRepositoryProvider);
  final list = await repo.getListWithItems(listId);
  print('itemsProvider rechargé pour liste $listId: ${list.items.length} items');
  return list.items;
});


final invitationsProvider = FutureProvider.family<List<Invitation>, String>((ref, userEmail) async {
  final repo = ref.read(localRepositoryProvider);
  return await repo.getInvitations(userEmail);
});

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());