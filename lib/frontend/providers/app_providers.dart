import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/models/user.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/frontend/repositories/local_repository.dart';

final localRepositoryProvider = Provider<LocalRepository>((ref) => LocalRepository());

final authProvider = StateProvider<User?>((ref) => null);

final shoppingListsProvider = FutureProvider.family<List<ShoppingList>, String>((ref, userId) async {
  final repo = ref.watch(localRepositoryProvider);
  return repo.getLists(userId);
});

final selectedListIdProvider = StateProvider<String?>((ref) => null);

final selectedListProvider = FutureProvider<ShoppingList?>((ref) async {
  final listId = ref.watch(selectedListIdProvider);
  if (listId == null) return null;
  final repo = ref.watch(localRepositoryProvider);
  return repo.getListWithItems(listId);
});

final itemsProvider = FutureProvider.family<List<ShoppingItem>, String>((ref, listId) async {
  final repo = ref.watch(localRepositoryProvider);
  return (await repo.getListWithItems(listId)).items;
});

final syncStateProvider = StateProvider<bool>((ref) => false);