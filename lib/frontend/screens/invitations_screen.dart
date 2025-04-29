import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/frontend/providers/app_providers.dart' as app_providers;
import 'package:tobuy/models/invitation.dart';

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(app_providers.authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    print('Chargement invitations pour email: ${user.email}');
    final invitationsAsync = ref.watch(app_providers.invitationsProvider(user.email));

    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: invitationsAsync.when(
        data: (invitations) {
          print('Invitations affichées: ${invitations.length}');
          return invitations.isEmpty
              ? const Center(child: Text('Aucune invitation'))
              : ListView.builder(
                  itemCount: invitations.length,
                  itemBuilder: (context, index) {
                    final invitation = invitations[index];
                    return ListTile(
                      title: Text('Liste: ${invitation.listName}'),
                      subtitle: Text('Invité par: ${invitation.inviterEmail}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () async {
                              try {
                                final repo = ref.read(app_providers.localRepositoryProvider);
                                await repo.updateInvitation(invitation.id, InvitationStatus.accepted);
                                ref.invalidate(app_providers.invitationsProvider);
                                ref.invalidate(app_providers.shoppingListsProvider);
                                print('Invitation acceptée: ${invitation.listName}');
                              } catch (e) {
                                print('Erreur acceptation invitation: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: $e')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () async {
                              try {
                                final repo = ref.read(app_providers.localRepositoryProvider);
                                await repo.updateInvitation(invitation.id, InvitationStatus.rejected);
                                ref.invalidate(app_providers.invitationsProvider);
                                print('Invitation rejetée: ${invitation.listName}');
                              } catch (e) {
                                print('Erreur rejet invitation: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: $e')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur chargement invitations: $e')),
      ),
    );
  }
}