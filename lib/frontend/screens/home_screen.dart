import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/frontend/providers/app_providers.dart' as app_providers;
import 'package:tobuy/frontend/widgets/shopping_item_card.dart';
import 'package:tobuy/frontend/widgets/total_price_display.dart';
import 'package:tobuy/frontend/screens/add_item_screen.dart';
import 'package:tobuy/frontend/screens/invitations_screen.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/suggestion.dart';
import 'package:tobuy/models/uuid_helper.dart';
import 'package:tobuy/ia/services/gemini_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _pipChannel = MethodChannel('com.example.tobuy/pip');
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _enterPipMode() async {
    try {
      await _pipChannel.invokeMethod('enterPipMode');
      print('Mode PiP déclenché');
    } catch (e) {
      print('Erreur PiP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur PiP: $e')),
      );
    }
  }

  Future<void> _showCreateListDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle liste'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nom de la liste'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    final localRepo = ref.read(app_providers.localRepositoryProvider);
                    final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
                    final user = ref.read(app_providers.authProvider);
                    final isOnline = await ref.read(app_providers.connectivityProvider.future);
                    if (user != null) {
                      final list = await localRepo.createList(user.id, name);
                      if (isOnline) {
                        try {
                          await remoteRepo.createList(user.id, name, isOnline: isOnline);
                          print('Liste créée sur le serveur: ${list.name}');
                        } catch (e) {
                          print('Erreur création liste serveur: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Liste créée localement, synchronisation en attente.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mode hors ligne : liste créée localement, synchronisation en attente.')),
                        );
                      }
                      ref.read(app_providers.selectedListIdProvider.notifier).state = list.id;
                      ref.invalidate(app_providers.shoppingListsProvider);
                      ref.invalidate(app_providers.selectedListProvider);
                      print('Liste créée localement: ${list.name}');
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    print('Erreur création liste: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteListDialog(BuildContext context, WidgetRef ref, String listId, String listName) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la liste'),
          content: Text('Voulez-vous supprimer "$listName" ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            TextButton(
              onPressed: () async {
                try {
                  final localRepo = ref.read(app_providers.localRepositoryProvider);
                  final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
                  final isOnline = await ref.read(app_providers.connectivityProvider.future);
                  await localRepo.deleteList(listId);
                  if (isOnline) {
                    try {
                      await remoteRepo.deleteList(listId, isOnline: isOnline);
                      print('Liste supprimée sur le serveur: $listName');
                    } catch (e) {
                      print('Erreur suppression liste serveur: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Liste supprimée localement, synchronisation en attente.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mode hors ligne : liste supprimée localement, synchronisation en attente.')),
                    );
                  }
                  ref.read(app_providers.selectedListIdProvider.notifier).state = null;
                  ref.invalidate(app_providers.shoppingListsProvider);
                  ref.invalidate(app_providers.selectedListProvider);
                  print('Liste supprimée localement: $listName');
                  Navigator.pop(context);
                } catch (e) {
                  print('Erreur suppression liste: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref, String listId, String listName) async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Inviter un collaborateur'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email du collaborateur'),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  try {
                    final localRepo = ref.read(app_providers.localRepositoryProvider);
                    final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
                    final user = ref.read(app_providers.authProvider);
                    final isOnline = await ref.read(app_providers.connectivityProvider.future);
                    if (user != null) {
                      await localRepo.createInvitation(listId, listName, user.id, user.email, email);
                      if (isOnline) {
                        try {
                          await remoteRepo.createInvitation(
                            listId,
                            listName,
                            user.id,
                            user.email,
                            email,
                            isOnline: isOnline,
                          );
                          print('Invitation envoyée sur le serveur à $email');
                        } catch (e) {
                          print('Erreur envoi invitation serveur: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invitation créée localement, synchronisation en attente.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mode hors ligne : invitation créée localement, synchronisation en attente.')),
                        );
                      }
                      ref.invalidate(app_providers.invitationsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invitation envoyée à $email')),
                      );
                      print('Invitation créée localement pour $email');
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    print('Erreur invitation: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              },
              child: const Text('Inviter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showIngredientsDialog(BuildContext context, WidgetRef ref) async {
    final dishController = TextEditingController();
    final budgetController = TextEditingController(text: '5000');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Suggérer des ingrédients'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dishController,
                decoration: const InputDecoration(labelText: 'Plat (ex. Ndolé)'),
              ),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(labelText: 'Budget (FCFA)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            TextButton(
              onPressed: () async {
                final dish = dishController.text.trim();
                final budget = double.tryParse(budgetController.text.trim()) ?? 5000.0;
                if (dish.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer un plat')),
                  );
                  return;
                }
                try {
                  final gemini = ref.read(geminiServiceProvider);
                  final ingredients = await gemini.getIngredientsForDish(dish, budget);
                  final listId = ref.read(app_providers.selectedListIdProvider);
                  final isOnline = await ref.read(app_providers.connectivityProvider.future);
                  if (listId != null && ingredients.isNotEmpty) {
                    final localRepo = ref.read(app_providers.localRepositoryProvider);
                    final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
                    for (var ingredient in ingredients) {
                      final item = ShoppingItem(
                        id: UuidHelper.generate(),
                        listId: listId,
                        name: ingredient.name.replaceAll(RegExp(r'[*_]+'), ''),
                        quantity: ingredient.quantity,
                        unitPrice: ingredient.unitPrice,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        isSynced: false,
                        isDeleted: false,
                      );
                      await localRepo.addItem(listId, item);
                      if (isOnline) {
                        try {
                          await remoteRepo.addItem(listId, item, isOnline: isOnline);
                          print('Ingrédient ajouté sur le serveur: ${item.name}');
                        } catch (e) {
                          print('Erreur ajout ingrédient serveur: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ingrédients ajoutés localement, synchronisation en attente.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mode hors ligne : ingrédients ajoutés localement, synchronisation en attente.')),
                        );
                      }
                    }
                    ref.invalidate(app_providers.itemsProvider);
                    ref.invalidate(app_providers.selectedListProvider);
                    ref.invalidate(app_providers.shoppingListsProvider);
                    print('Ingrédients ajoutés localement pour $dish: ${ingredients.length} items');
                    Navigator.pop(context);
                    _showConfirmationDialog(context, ref, ingredients, dish);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucun ingrédient suggéré ou liste non sélectionnée')),
                    );
                  }
                } catch (e) {
                  print('Erreur suggestion ingrédients: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur suggestions: $e')),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, WidgetRef ref, List<Suggestion> ingredients, String dish) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ingrédients ajoutés pour $dish'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = ingredients[index];
                return ListTile(
                  title: MarkdownBody(data: ingredient.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(data: '**Raison**: ${ingredient.reason}'),
                      Text('Quantité: ${ingredient.quantity}'),
                      Text('Prix unitaire: ${ingredient.unitPrice} FCFA'),
                      Text('Prix total: ${ingredient.totalPrice} FCFA'),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(app_providers.authProvider);
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final listsAsync = ref.watch(app_providers.shoppingListsProvider(user.id));
        final selectedListAsync = ref.watch(app_providers.selectedListProvider);
        final listId = ref.watch(app_providers.selectedListIdProvider) ?? '';
        final itemsAsync = ref.watch(app_providers.itemsProvider(listId));

        print('HomeScreen reconstruit, listId: $listId');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ma Liste d\'Achats'),
            actions: [
              IconButton(icon: const Icon(Icons.picture_in_picture), onPressed: _enterPipMode),
            ],
          ),
          drawer: Drawer(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: listsAsync.when(
                data: (lists) => ListView(
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'Listes de ${user.email}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    ...lists.map((list) => ListTile(
                          title: Text(
                            list.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          selected: ref.watch(app_providers.selectedListIdProvider) == list.id,
                          selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteListDialog(context, ref, list.id, list.name);
                            },
                          ),
                          onTap: () {
                            ref.read(app_providers.selectedListIdProvider.notifier).state = list.id;
                            Navigator.pop(context);
                          },
                        )),
                    ListTile(
                      title: Text(
                        'Nouvelle liste',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      leading: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showCreateListDialog(context, ref);
                      },
                    ),
                    ListTile(
                      title: Text(
                        'Invitations',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      leading: Icon(
                        Icons.mail,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationsScreen()));
                      },
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur chargement listes: $e')),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Rechercher un aliment',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                selectedListAsync.when(
                  data: (list) => list == null
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Sélectionnez une liste'),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${list.name} (${list.items.length})',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.person_add),
                                        onPressed: () => _showInviteDialog(context, ref, list.id, list.name),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () async {
                                          final exportService = ref.read(app_providers.exportServiceProvider);
                                          await exportService.exportToPdf(list);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (list.collaboratorIds.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Text(
                                  'Collaborateurs: ${list.collaboratorIds.length}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                ),
                              ),
                            itemsAsync.when(
                              data: (items) {
                                final filteredItems = items
                                    .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                                    .toList();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: filteredItems.length,
                                      itemBuilder: (context, index) {
                                        final item = filteredItems[index];
                                        return ShoppingItemCard(
                                          item: item,
                                          onDelete: () async {
                                            try {
                                              final localRepo = ref.read(app_providers.localRepositoryProvider);
                                              final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
                                              final isOnline = await ref.read(app_providers.connectivityProvider.future);
                                              await localRepo.deleteItem(item.id);
                                              if (isOnline) {
                                                try {
                                                  await remoteRepo.deleteItem(item.id, isOnline: isOnline);
                                                  print('Item supprimé sur le serveur: ${item.name}');
                                                } catch (e) {
                                                  print('Erreur suppression item serveur: $e');
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Item supprimé localement, synchronisation en attente.')),
                                                  );
                                                }
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Mode hors ligne : item supprimé localement, synchronisation en attente.')),
                                                );
                                              }
                                              ref.invalidate(app_providers.itemsProvider);
                                              ref.invalidate(app_providers.selectedListProvider);
                                              ref.invalidate(app_providers.shoppingListsProvider);
                                              print('Item supprimé localement: ${item.name}');
                                            } catch (e) {
                                              print('Erreur suppression item: $e');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erreur: $e')),
                                              );
                                            }
                                          },
                                          onToggleCheck: () async {
                                            try {
                                              final localRepo = ref.read(app_providers.localRepositoryProvider);
                                              final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
                                              final isOnline = await ref.read(app_providers.connectivityProvider.future);
                                              await localRepo.updateItem(item.id, isChecked: !item.isChecked);
                                              if (isOnline) {
                                                try {
                                                  await remoteRepo.updateItem(
                                                    item.id,
                                                    isChecked: !item.isChecked,
                                                    isOnline: isOnline,
                                                  );
                                                  print('Item coché sur le serveur: ${item.name}, isChecked: ${!item.isChecked}');
                                                } catch (e) {
                                                  print('Erreur coche item serveur: $e');
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Item coché localement, synchronisation en attente.')),
                                                  );
                                                }
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Mode hors ligne : item coché localement, synchronisation en attente.')),
                                                );
                                              }
                                              ref.invalidate(app_providers.itemsProvider);
                                              ref.invalidate(app_providers.selectedListProvider);
                                              ref.invalidate(app_providers.shoppingListsProvider);
                                              print('Item coché localement: ${item.name}, isChecked: ${!item.isChecked}');
                                            } catch (e) {
                                              print('Erreur coche item: $e');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erreur: $e')),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => Center(child: Text('Erreur chargement items: $e')),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48.0),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                ),
                                onPressed: () => _showIngredientsDialog(context, ref),
                                child: const Text('Ajouter des ingrédients pour un plat'),
                              ),
                            ),
                            TotalPriceDisplay(totalPrice: list.totalPrice),
                          ],
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur chargement liste: $e')),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (ref.read(app_providers.selectedListIdProvider) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sélectionnez une liste d\'abord')),
                );
                return;
              }
              Navigator.pushNamed(context, '/add-item');
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}