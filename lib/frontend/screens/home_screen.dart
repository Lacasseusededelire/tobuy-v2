import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/frontend/providers/app_providers.dart';
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
import 'package:tobuy/frontend/repositories/local_repository.dart';
import 'package:tobuy/ia/services/gemini_service.dart';
import 'package:tobuy/frontend/utils/export_service.dart';
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
      final repo = ref.read(localRepositoryProvider);
      final user = await repo.getUser();
      if (user != null) {
        ref.read(authProvider.notifier).state = user;
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
                  final repo = ref.read(localRepositoryProvider);
                  final user = ref.read(authProvider);
                  if (user != null) {
                    final list = await repo.createList(user.id, name);
                    ref.read(selectedListIdProvider.notifier).state = list.id;
                    ref.invalidate(shoppingListsProvider);
                  }
                  Navigator.pop(context);
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
                final repo = ref.read(localRepositoryProvider);
                await repo.deleteList(listId);
                ref.read(selectedListIdProvider.notifier).state = null;
                ref.invalidate(shoppingListsProvider);
                Navigator.pop(context);
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
                  final repo = ref.read(localRepositoryProvider);
                  final user = ref.read(authProvider);
                  if (user != null) {
                    await repo.createInvitation(listId, listName, user.id, user.email, email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invitation envoyée à $email')),
                    );
                  }
                  Navigator.pop(context);
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
    final budgetController = TextEditingController(text: '1000');

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
                final budget = double.tryParse(budgetController.text.trim()) ?? 1000.0;
                if (dish.isNotEmpty) {
                  final gemini = ref.read(geminiServiceProvider);
                  final ingredients = await gemini.getIngredientsForDish(dish, budget);
                  Navigator.pop(context);
                  if (ingredients.isNotEmpty) {
                    _showSuggestionsDialog(context, ref, ingredients, 'Ingrédients pour $dish');
                  }
                }
              },
              child: const Text('Suggérer'),
            ),
          ],
        );
      },
    );
  }

  void _showSuggestionsDialog(BuildContext context, WidgetRef ref, List<Suggestion> suggestions, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  title: Text(suggestion.name),
                  subtitle: MarkdownBody(data: suggestion.reason),
                  trailing: Text('${suggestion.estimatedPrice} FCFA'),
                  onTap: () async {
                    final listId = ref.read(selectedListIdProvider);
                    if (listId != null) {
                      final repo = ref.read(localRepositoryProvider);
                      await repo.addItem(
                        listId,
                        ShoppingItem(
                          id: UuidHelper.generate(),
                          listId: listId,
                          name: suggestion.name,
                          quantity: 1.0,
                          unitPrice: suggestion.estimatedPrice,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                      ref.invalidate(itemsProvider);
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final listsAsync = ref.watch(shoppingListsProvider(user.id));
    final selectedListAsync = ref.watch(selectedListProvider);
    final itemsAsync = ref.watch(itemsProvider(ref.watch(selectedListIdProvider) ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Liste d\'Achats'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_in_picture), onPressed: _enterPipMode),
        ],
      ),
      drawer: Drawer(
        child: listsAsync.when(
          data: (lists) => ListView(
            children: [
              DrawerHeader(child: Text('Listes de ${user.email}')),
              ...lists.map((list) => ListTile(
                    title: Text(list.name),
                    selected: ref.watch(selectedListIdProvider) == list.id,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteListDialog(context, ref, list.id, list.name);
                      },
                    ),
                    onTap: () {
                      ref.read(selectedListIdProvider.notifier).state = list.id;
                      Navigator.pop(context);
                    },
                  )),
              ListTile(
                title: const Text('Nouvelle liste'),
                leading: const Icon(Icons.add),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateListDialog(context, ref);
                },
              ),
              ListTile(
                title: const Text('Invitations'),
                leading: const Icon(Icons.mail),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationsScreen()));
                },
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
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
                decoration: const InputDecoration(
                  labelText: 'Rechercher un aliment',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
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
                                      final exportService = ref.read(exportServiceProvider);
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
                          data: (items) => FutureBuilder<List<Suggestion>>(
                            future: ref.read(geminiServiceProvider).getSuggestions(items.map((i) => i.name).toList()),
                            builder: (context, snapshot) {
                              final filteredItems = items
                                  .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                                  .toList();
                              final suggestions = snapshot.data ?? [];
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
                                          final repo = ref.read(localRepositoryProvider);
                                          await repo.deleteItem(item.id);
                                          ref.invalidate(itemsProvider);
                                        },
                                        onToggleCheck: () async {
                                          final repo = ref.read(localRepositoryProvider);
                                          await repo.updateItem(item.id, isChecked: !item.isChecked);
                                          ref.invalidate(itemsProvider);
                                        },
                                      );
                                    },
                                  ),
                                  if (suggestions.isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                          child: Text(
                                            'Suggestions IA',
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                        ),
                                        ...suggestions.map((suggestion) => ListTile(
                                              title: Text(suggestion.name),
                                              subtitle: MarkdownBody(data: suggestion.reason),
                                              trailing: Text('${suggestion.estimatedPrice} FCFA'),
                                              onTap: () async {
                                                final repo = ref.read(localRepositoryProvider);
                                                await repo.addItem(
                                                  list.id,
                                                  ShoppingItem(
                                                    id: UuidHelper.generate(),
                                                    listId: list.id,
                                                    name: suggestion.name,
                                                    quantity: 1.0,
                                                    unitPrice: suggestion.estimatedPrice,
                                                    createdAt: DateTime.now(),
                                                    updatedAt: DateTime.now(),
                                                  ),
                                                );
                                                ref.invalidate(itemsProvider);
                                              },
                                            )),
                                      ],
                                    ),
                                ],
                              );
                            },
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Erreur: $e')),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48.0)),
                            onPressed: () => _showIngredientsDialog(context, ref),
                            child: const Text('Suggérer des ingrédients pour un plat'),
                          ),
                        ),
                        TotalPriceDisplay(totalPrice: list.totalPrice),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (ref.read(selectedListIdProvider) == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sélectionnez une liste d\'abord')),
            );
            return;
          }
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AddItemScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeScaleTransition(animation: animation, child: child);
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}