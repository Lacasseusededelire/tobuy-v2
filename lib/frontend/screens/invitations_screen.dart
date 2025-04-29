import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tobuy/frontend/providers/app_providers.dart';
import 'package:tobuy/models/invitation.dart';
import 'package:tobuy/frontend/repositories/local_repository.dart';

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final invitationsAsync = ref.watch(invitationsProvider(user?.email ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: invitationsAsync.when(
        data: (invitations) => invitations.isEmpty
            ? const Center(child: Text('Aucune invitation'))
            : ListView.builder(
                itemCount: invitations.length,
                itemBuilder: (context, index) {
                  final invitation = invitations[index];
                  return ListTile(
                    title: Text('Liste: ${invitation.listName}'),
                    subtitle: Text('De: ${invitation.inviterEmail}'),
                    trailing: invitation.status == InvitationStatus.pending
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () async {
                                  final repo = ref.read(localRepositoryProvider);
                                  await repo.updateInvitation(invitation.id, InvitationStatus.accepted);
                                  ref.invalidate(invitationsProvider);
                                  ref.invalidate(shoppingListsProvider);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () async {
                                  final repo = ref.read(localRepositoryProvider);
                                  await repo.updateInvitation(invitation.id, InvitationStatus.rejected);
                                  ref.invalidate(invitationsProvider);
                                },
                              ),
                            ],
                          )
                        : Text(invitation.status.name),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

final invitationsProvider = FutureProvider.family<List<Invitation>, String>((ref, email) async {
  final repo = ref.watch(localRepositoryProvider);
  return repo.getInvitations(email);
});