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

    final invitationsAsync = ref.watch(app_providers.invitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitations'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: invitationsAsync.when(
        data: (invitations) => invitations.isEmpty
            ? const Center(child: Text('Aucune invitation'))
            : ListView.builder(
                itemCount: invitations.length,
                itemBuilder: (context, index) {
                  final invitation = invitations[index];
                  return ListTile(
                    title: Text(
                      invitation.listName,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      'De: ${invitation.senderEmail}',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                    ),
                    trailing: invitation.status == 'pending'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check),
                                color: Theme.of(context).colorScheme.primary,
                                onPressed: () async {
                                  try {
                                    final localRepo = ref.read(app_providers.localRepositoryProvider);
                                    final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
                                    final isOnline = await ref.read(app_providers.connectivityProvider.future);
                                    await localRepo.acceptInvitation(invitation.id, user.id);
                                    if (isOnline) {
                                      try {
                                        await remoteRepo.acceptInvitation(invitation.id, user.id, isOnline: isOnline);
                                        print('Invitation acceptée sur le serveur: ${invitation.id}');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Invitation pour ${invitation.listName} acceptée et synchronisée.')),
                                        );
                                      } catch (e) {
                                        print('Erreur acceptation invitation serveur: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Invitation pour ${invitation.listName} acceptée localement, synchronisation en attente.')),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Mode hors ligne : invitation pour ${invitation.listName} acceptée localement, synchronisation en attente.')),
                                      );
                                    }
                                    ref.invalidate(app_providers.invitationsProvider);
                                    ref.invalidate(app_providers.shoppingListsProvider);
                                    print('Invitation acceptée localement: ${invitation.id}');
                                  } catch (e) {
                                    print('Erreur acceptation invitation: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erreur: $e')),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                color: Theme.of(context).colorScheme.error,
                                onPressed: () async {
                                  try {
                                    final localRepo = ref.read(app_providers.localRepositoryProvider);
                                    final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
                                    final isOnline = await ref.read(app_providers.connectivityProvider.future);
                                    await localRepo.rejectInvitation(invitation.id);
                                    if (isOnline) {
                                      try {
                                        await remoteRepo.rejectInvitation(invitation.id, isOnline: isOnline);
                                        print('Invitation refusée sur le serveur: ${invitation.id}');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Invitation pour ${invitation.listName} refusée et synchronisée.')),
                                        );
                                      } catch (e) {
                                        print('Erreur refus invitation serveur: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Invitation pour ${invitation.listName} refusée localement, synchronisation en attente.')),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Mode hors ligne : invitation pour ${invitation.listName} refusée localement, synchronisation en attente.')),
                                      );
                                    }
                                    ref.invalidate(app_providers.invitationsProvider);
                                    print('Invitation refusée localement: ${invitation.id}');
                                  } catch (e) {
                                    print('Erreur refus invitation: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erreur: $e')),
                                    );
                                  }
                                },
                              ),
                            ],
                          )
                        : Text(
                            invitation.status == 'accepted' ? 'Acceptée' : 'Refusée',
                            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                          ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur chargement invitations: $e')),
      ),
    );
  }
}