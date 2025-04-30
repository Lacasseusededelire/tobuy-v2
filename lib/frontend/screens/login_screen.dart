import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:tobuy/frontend/providers/app_providers.dart' as app_providers;
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Note : La suppression de la base de données est commentée pour éviter de vider les données à chaque démarrage.
    // Si tu veux réinitialiser à nouveau, décommente ce bloc temporairement.
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final localRepo = ref.read(app_providers.localRepositoryProvider);
      await localRepo.deleteAndRecreateDatabase();
      print('Base de données locale supprimée et recréée au démarrage.');
    });
    */
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final localRepo = ref.read(app_providers.localRepositoryProvider);
        final remoteRepo = ref.read(app_providers.remoteRepositoryProvider);
        final syncService = ref.read(app_providers.syncServiceProvider);
        final isOnline = await ref.read(app_providers.connectivityProvider.future);
        print('État de la connectivité : isOnline = $isOnline');

        // Vérifier si un utilisateur existe localement
        var user = await localRepo.login(_emailController.text, _passwordController.text);

        if (user == null && isOnline) {
          // Si l'utilisateur n'existe pas localement et qu'on est en ligne, tenter une connexion au serveur
          print('Utilisateur non trouvé localement, tentative de connexion au serveur...');
          try {
            user = await remoteRepo.login(_emailController.text, _passwordController.text, isOnline: true);
            if (user != null) {
              // Créer l'utilisateur dans la base de données locale pour les futures connexions hors ligne
              await localRepo.createUser(_emailController.text, _passwordController.text);
              print('Utilisateur créé localement après connexion serveur: ${_emailController.text}');
            }
          } catch (e) {
            // Gérer l'erreur 401 spécifiquement
            if (e is DioException && e.response?.statusCode == 401) {
              print('Erreur 401: Utilisateur non trouvé sur le serveur');
              throw Exception('Utilisateur non trouvé sur le serveur');
            } else {
              // Autres erreurs réseau
              print('Erreur détaillée lors de la connexion au serveur: $e');
              throw Exception('Erreur serveur: $e');
            }
          }
        }

        if (user != null) {
          // Si l'utilisateur est connecté (localement ou via le serveur), on met à jour l'état
          ref.read(app_providers.authProvider.notifier).state = user;
          print('Connexion réussie: ${_emailController.text}');

          // Si on est en ligne, synchroniser les données
          if (isOnline) {
            try {
              print('Tentative de synchronisation des données...');
              await syncService.syncData(user.id);
              print('Synchronisation des données réussie');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connexion et synchronisation réussies !')),
              );
            } catch (e) {
              print('Erreur lors de la synchronisation: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connexion réussie, mais erreur synchronisation: $e. Synchronisation en attente.'),
                ),
              );
            }
          } else {
            // Si hors ligne, informer l'utilisateur
            print('Mode hors ligne détecté');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mode hors ligne : connexion réussie, synchronisation en attente.')),
            );
          }

          // Naviguer vers l'écran d'accueil
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Si l'utilisateur est null et qu'on est hors ligne, indiquer qu'une connexion en ligne est nécessaire
          if (!isOnline) {
            throw Exception('Aucune donnée locale trouvée. Une connexion en ligne est requise pour la première connexion.');
          } else {
            throw Exception('Identifiants incorrects');
          }
        }
      } catch (e) {
        print('Erreur générale connexion: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToBuy'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'exemple@domaine.com',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  hintText: 'Minimum 6 caractères',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: _submitForm,
                      child: const Text('Connexion'),
                    ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SharedAxisTransition(
                          animation: animation,
                          secondaryAnimation: secondaryAnimation,
                          transitionType: SharedAxisTransitionType.horizontal,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: const Text('Pas de compte ? Inscrivez-vous'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}