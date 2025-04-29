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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(app_providers.localRepositoryProvider);
      final user = await repo.getUser();
      if (user != null) {
        ref.read(app_providers.authProvider.notifier).state = user;
      }
    });
  }

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

  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
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
                    final repo = ref.read(app_providers.localRepositoryProvider);
                    final user = ref.read(app_providers.authProvider);
                    if (user != null) {
                      final list = await repo.createList(user.id, name);
                      ref.read(app_providers.selectedListIdProvider.notifier).state = list.id;
                      ref.invalidate(app_providers.shoppingListsProvider);
                      ref.invalidate(app_providers.selectedListProvider);
                      print('Liste créée: ${list.name}');
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

  void _showDeleteListDialog(BuildContext context, WidgetRef ref, String listId, String listName) {
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
                  final repo = ref.read(app_providers.localRepositoryProvider);
                  await repo.deleteList(listId);
                  ref.read(app_providers.selectedListIdProvider.notifier).state = null;
                  ref.invalidate(app_providers.shoppingListsProvider);
                  ref.invalidate(app_providers.selectedListProvider);
                  print('Liste supprimée: $listName');
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

  void _showInviteDialog(BuildContext context, WidgetRef ref, String listId, String listName) {
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
                    final repo = ref.read(app_providers.localRepositoryProvider);
                    final user = ref.read(app_providers.authProvider);
                    if (user != null) {
                      await repo.createInvitation(listId, listName, user.id, user.email, email);
                      ref.invalidate(app_providers.invitationsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invitation envoyée à $email')),
                      );
                      print('Invitation envoyée à $email');
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

  void _showIngredientsDialog(BuildContext context, WidgetRef ref) {
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
                  if (listId != null && ingredients.isNotEmpty) {
                    final repo = ref.read(app_providers.localRepositoryProvider);
                    for (var ingredient in ingredients) {
                      await repo.addItem(
                        listId,
                        ShoppingItem(
                          id: UuidHelper.generate(),
                          listId: listId,
                          name: ingredient.name.replaceAll(RegExp(r'[*_]+'), ''), // Nettoyer les étoiles
                          quantity: ingredient.quantity,
                          unitPrice: ingredient.unitPrice,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                          isSynced: false,
                          isDeleted: false,
                        ),
                      );
                    }
                    ref.invalidate(app_providers.itemsProvider);
                    ref.invalidate(app_providers.selectedListProvider);
                    ref.invalidate(app_providers.shoppingListsProvider);
                    print('Ingrédients ajoutés automatiquement pour $dish: ${ingredients.length} items');
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
                  title: MarkdownBody(data: ingredient.name), // Rendre le nom en Markdown
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
                                    style: Theme.of(context).textTheme.titleLarge,
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
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                                              final repo = ref.read(app_providers.localRepositoryProvider);
                                              await repo.deleteItem(item.id);
                                              ref.invalidate(app_providers.itemsProvider);
                                              ref.invalidate(app_providers.selectedListProvider);
                                              ref.invalidate(app_providers.shoppingListsProvider);
                                              print('Item supprimé: ${item.name}');
                                            } catch (e) {
                                              print('Erreur suppression item: $e');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erreur: $e')),
                                              );
                                            }
                                          },
                                          onToggleCheck: () async {
                                            try {
                                              final repo = ref.read(app_providers.localRepositoryProvider);
                                              await repo.updateItem(item.id, isChecked: !item.isChecked);
                                              ref.invalidate(app_providers.itemsProvider);
                                              ref.invalidate(app_providers.selectedListProvider);
                                              ref.invalidate(app_providers.shoppingListsProvider);
                                              print('Item coché: ${item.name}, isChecked: ${!item.isChecked}');
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
                                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48.0)),
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
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}