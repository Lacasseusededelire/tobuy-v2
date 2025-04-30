import 'package:dio/dio.dart';
import 'package:tobuy/models/user.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/invitation.dart';
import 'package:tobuy/data/local_repository.dart';

class RemoteRepository {
  final Dio dio;
  final LocalRepository localRepo;
  final String baseUrl = 'http://192.168.1.115:3000';

  RemoteRepository({
    required this.dio,
    required this.localRepo,
  });

  Future<User> login(String email, String password, {required bool isOnline}) async {
    try {
      final response = await dio.post('$baseUrl/auth/login', data: {
        'email': email,
        'password': password,
      });
      final user = User.fromJson(response.data);
      await localRepo.createUser(user.email, user.password);
      return user;
    } catch (e) {
      if (!isOnline) {
        final user = await localRepo.login(email, password);
        if (user == null) throw Exception('Échec de la connexion: utilisateur non trouvé en local');
        return user;
      }
      throw Exception('Échec de la connexion: $e');
    }
  }

  Future<User> createUser(String email, String password, {required bool isOnline}) async {
    try {
      final response = await dio.post('$baseUrl/users', data: {
        'email': email,
        'password': password,
      });
      final user = User.fromJson(response.data);
      await localRepo.createUser(user.email, user.password);
      return user;
    } catch (e) {
      if (!isOnline) {
        return await localRepo.createUser(email, password);
      }
      throw Exception('Échec de la création: $e');
    }
  }

  Future<ShoppingList> createList(String userId, String name, {required bool isOnline}) async {
    try {
      final response = await dio.post('$baseUrl/lists', data: {
        'userId': userId,
        'name': name,
      });
      final list = ShoppingList.fromJson(response.data);
      await localRepo.createList(userId, name);
      return list;
    } catch (e) {
      if (!isOnline) {
        return await localRepo.createList(userId, name);
      }
      throw Exception('Échec création liste: $e');
    }
  }

  Future<void> deleteList(String listId, {required bool isOnline}) async {
    try {
      await dio.delete('$baseUrl/lists/$listId');
      await localRepo.deleteList(listId);
    } catch (e) {
      if (!isOnline) {
        await localRepo.deleteList(listId);
        return;
      }
      throw Exception('Échec suppression liste: $e');
    }
  }

  Future<List<ShoppingList>> getLists(String userId, {required bool isOnline}) async {
    try {
      final response = await dio.get('$baseUrl/lists', queryParameters: {'userId': userId});
      final lists = (response.data as List).map((json) => ShoppingList.fromJson(json)).toList();
      for (var list in lists) {
        await localRepo.createList(list.userId, list.name);
        for (var item in list.items) {
          await localRepo.addItem(list.id, item);
        }
      }
      return lists;
    } catch (e) {
      if (!isOnline) {
        return await localRepo.getLists(userId);
      }
      throw Exception('Échec chargement listes: $e');
    }
  }

  Future<void> addItem(String listId, ShoppingItem item, {required bool isOnline}) async {
    try {
      await dio.post('$baseUrl/items', data: item.toJson()..['listId'] = listId);
      await localRepo.addItem(listId, item.copyWith(isSynced: true));
    } catch (e) {
      if (!isOnline) {
        await localRepo.addItem(listId, item.copyWith(isSynced: false));
        return;
      }
      throw Exception('Échec ajout item: $e');
    }
  }

  Future<void> deleteItem(String itemId, {required bool isOnline}) async {
    try {
      await dio.delete('$baseUrl/items/$itemId');
      await localRepo.deleteItem(itemId);
    } catch (e) {
      if (!isOnline) {
        await localRepo.deleteItem(itemId);
        return;
      }
      throw Exception('Échec suppression item: $e');
    }
  }

  Future<void> updateItem(
    String itemId, {
    String? name,
    double? quantity,
    double? unitPrice,
    bool? isChecked,
    required bool isOnline,
  }) async {
    try {
      await dio.patch('$baseUrl/items/$itemId', data: {
        if (name != null) 'name': name,
        if (quantity != null) 'quantity': quantity,
        if (unitPrice != null) 'unitPrice': unitPrice,
        if (isChecked != null) 'isChecked': isChecked,
      });
      await localRepo.updateItem(
        itemId,
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
        isChecked: isChecked,
      );
    } catch (e) {
      if (!isOnline) {
        await localRepo.updateItem(
          itemId,
          name: name,
          quantity: quantity,
          unitPrice: unitPrice,
          isChecked: isChecked,
        );
        return;
      }
      throw Exception('Échec mise à jour item: $e');
    }
  }

  Future<List<ShoppingItem>> getItems(String listId, {required bool isOnline}) async {
    try {
      final response = await dio.get('$baseUrl/items', queryParameters: {'listId': listId});
      final items = (response.data as List).map((json) => ShoppingItem.fromJson(json)).toList();
      for (var item in items) {
        await localRepo.addItem(listId, item.copyWith(isSynced: true));
      }
      return items;
    } catch (e) {
      if (!isOnline) {
        return await localRepo.getItems(listId);
      }
      throw Exception('Échec chargement items: $e');
    }
  }

  Future<void> createInvitation(
      String listId, String listName, String senderId, String senderEmail, String receiverEmail,
      {required bool isOnline}) async {
    try {
      await dio.post('$baseUrl/invitations', data: {
        'listId': listId,
        'listName': listName,
        'senderId': senderId,
        'senderEmail': senderEmail,
        'receiverEmail': receiverEmail,
        'status': 'pending',
      });
      await localRepo.createInvitation(listId, listName, senderId, senderEmail, receiverEmail);
    } catch (e) {
      if (!isOnline) {
        await localRepo.createInvitation(listId, listName, senderId, senderEmail, receiverEmail);
        return;
      }
      throw Exception('Échec création invitation: $e');
    }
  }

  Future<void> acceptInvitation(String invitationId, String userId, {required bool isOnline}) async {
    try {
      await dio.patch('$baseUrl/invitations/$invitationId/accept', data: {
        'userId': userId,
      });
      await localRepo.acceptInvitation(invitationId, userId);
    } catch (e) {
      if (!isOnline) {
        await localRepo.acceptInvitation(invitationId, userId);
        return;
      }
      throw Exception('Échec acceptation invitation: $e');
    }
  }

  Future<void> rejectInvitation(String invitationId, {required bool isOnline}) async {
    try {
      await dio.patch('$baseUrl/invitations/$invitationId/reject');
      await localRepo.rejectInvitation(invitationId);
    } catch (e) {
      if (!isOnline) {
        await localRepo.rejectInvitation(invitationId);
        return;
      }
      throw Exception('Échec refus invitation: $e');
    }
  }

  Future<List<Invitation>> getInvitations(String userEmail, {required bool isOnline}) async {
    try {
      final response = await dio.get('$baseUrl/invitations', queryParameters: {'receiverEmail': userEmail});
      final invitations = (response.data as List).map((json) => Invitation.fromJson(json)).toList();
      for (var invitation in invitations) {
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
      return invitations;
    } catch (e) {
      if (!isOnline) {
        return await localRepo.getInvitations(userEmail);
      }
      throw Exception('Échec chargement invitations: $e');
    }
  }
}