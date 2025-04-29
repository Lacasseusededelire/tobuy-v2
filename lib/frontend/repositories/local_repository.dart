import 'package:tobuy/models/user.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/invitation.dart';
import 'package:tobuy/models/uuid_helper.dart';

class LocalRepository {
  User? _user;
  final List<ShoppingList> _lists = [];
  final List<ShoppingItem> _items = [];
  final List<Invitation> _invitations = [];

  Future<User?> getUser() async {
    if (_user == null) {
      _user = User(
        id: UuidHelper.generate(),
        email: 'test@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return _user;
  }

  Future<List<ShoppingList>> getLists(String userId) async {
    return _lists.where((list) => (list.ownerId == userId || list.collaboratorIds.contains(userId)) && !list.isDeleted).toList();
  }

  Future<ShoppingList> createList(String userId, String name) async {
    final list = ShoppingList(
      id: UuidHelper.generate(),
      ownerId: userId,
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      isDeleted: false,
    );
    _lists.add(list);
    return list;
  }

  Future<void> updateList(String listId, {String? name, List<String>? collaboratorIds}) async {
    final index = _lists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      _lists[index] = _lists[index].copyWith(
        name: name,
        collaboratorIds: collaboratorIds,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
    }
  }

  Future<void> deleteList(String listId) async {
    final index = _lists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      _lists[index] = _lists[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
    }
  }

  Future<ShoppingList> getListWithItems(String listId) async {
    final list = _lists.firstWhere((list) => list.id == listId && !list.isDeleted, orElse: () => ShoppingList(
          id: listId,
          ownerId: '',
          name: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: false,
          isDeleted: false,
        ));
    final items = _items.where((item) => item.listId == listId && !item.isDeleted).toList();
    print('Liste $listId chargée avec ${items.length} items');
    return list.copyWith(items: items);
  }

  Future<void> addItem(String listId, ShoppingItem item) async {
    _items.add(item.copyWith(
      listId: listId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      isDeleted: false,
    ));
    print('Item ajouté: ${item.name} dans liste $listId, total items: ${_items.length}');
  }

  Future<void> updateItem(String itemId, {String? name, double? quantity, double? unitPrice, bool? isChecked}) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
        isChecked: isChecked,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      print('Item mis à jour: $itemId');
    }
  }

  Future<void> deleteItem(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      print('Item supprimé: $itemId');
    }
  }

  Future<List<Invitation>> getInvitations(String userEmail) async {
    final invitations = _invitations.where((inv) => inv.inviteeEmail == userEmail && inv.status != InvitationStatus.rejected).toList();
    print('Invitations récupérées pour $userEmail: ${invitations.length}');
    return invitations;
  }

  Future<void> createInvitation(String listId, String listName, String inviterId, String inviterEmail, String inviteeEmail) async {
    final invitation = Invitation(
      id: UuidHelper.generate(),
      listId: listId,
      listName: listName,
      inviterId: inviterId,
      inviterEmail: inviterEmail,
      inviteeEmail: inviteeEmail,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: InvitationStatus.pending,
    );
    _invitations.add(invitation);
    print('Invitation créée pour $inviteeEmail dans liste $listName, total invitations: ${_invitations.length}');
  }

  Future<void> updateInvitation(String invitationId, InvitationStatus status) async {
    final index = _invitations.indexWhere((inv) => inv.id == invitationId);
    if (index != -1) {
      _invitations[index] = _invitations[index].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      if (status == InvitationStatus.accepted) {
        final listId = _invitations[index].listId;
        final listIndex = _lists.indexWhere((list) => list.id == listId);
        if (listIndex != -1) {
          final user = await getUser();
          if (user != null) {
            _lists[listIndex] = _lists[listIndex].copyWith(
              collaboratorIds: [..._lists[listIndex].collaboratorIds, user.id],
              updatedAt: DateTime.now(),
              isSynced: false,
            );
            print('Collaborateur ajouté à la liste: $listId');
          }
        }
      }
      print('Invitation mise à jour: $invitationId, statut: $status');
    }
  }

  Future<void> sync() async {
    print('Synchronisation simulée');
  }
}