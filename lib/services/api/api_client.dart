import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tobuy/models/user.dart'; // Pour l'exemple d'auth
import 'package:tobuy/models/invitation.dart'; // Pour l'exemple d'invitation

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _baseUrl = 'http://VOTRE_IP_OU_DOMAINE:PORT'; // <-- METTRE A JOUR !

  // --- Singleton Pattern ---
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() : _dio = Dio() {
    // Configuration de base de Dio
    _dio.options = BaseOptions(
      baseUrl: _baseUrl, // Ex: 'http://10.0.2.2:3000' pour Android Emu local
      connectTimeout: const Duration(milliseconds: 8000), // 8 secondes
      receiveTimeout: const Duration(milliseconds: 8000), // 8 secondes
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Ajout des Intercepteurs
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
      logPrint: (o) => print(o.toString()), // Assure que tout est loggué comme string
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print("--> ${options.method} ${options.path}");
        // Récupérer le token JWT stocké (P3 le stocke au login)
        final token = await _secureStorage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print("Authorization Header Added");
        } else {
          print("No JWT token found for this request.");
        }
        return handler.next(options); // Continue la requête
      },
      onResponse: (response, handler) {
        print("<-- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}");
        // Traitement global des réponses si nécessaire
        return handler.next(response); // Continue
      },
      onError: (DioException e, handler) {
        print("<-- Error ${e.response?.statusCode} ${e.requestOptions.method} ${e.requestOptions.path}");
        print("Error details: ${e.message}");
        if (e.response?.statusCode == 401) {
          print("Authentication Error (401): Token might be invalid or expired.");
          // Ici, P3 pourrait intercepter cette erreur via un listener global
          // pour déconnecter l'utilisateur ou tenter un refresh token.
          // On ne gère pas la déconnexion directement ici.
        }
        // Propage l'erreur pour être gérée par l'appelant (ex: SyncService, AuthRepository)
        return handler.next(e);
      },
    ));
  }

  // Accesseur pour l'instance Dio configurée (utilisé par SyncService, AuthRepository, etc.)
  Dio get dio => _dio;

  // --- Méthodes spécifiques pour la Synchronisation (appelées par SyncService) ---
  // ATTENTION : La structure du payload et de la réponse DÉPEND de l'implémentation de P1

  // Envoie les changements locaux et récupère les changements serveur
  Future<Response> synchronizeData(Map<String, dynamic> syncPayload) async {
    // syncPayload = { 'lastSyncTimestamp': '...', 'changes': { 'lists': {...}, 'items': {...} } }
    print("Calling POST /sync");
    return await _dio.post('/sync', data: syncPayload);
  }

  // Récupère les changements serveur (si pas de changements locaux à envoyer)
  Future<Response> fetchServerChanges(String lastSyncTimestamp) async {
    print("Calling GET /sync?since=$lastSyncTimestamp");
    return await _dio.get('/sync', queryParameters: {'since': lastSyncTimestamp});
  }

// --- Exemples de méthodes pour P3 (Auth, Collaboration) ---
// Ces méthodes seraient typiquement dans des Repositories distincts (AuthRepository, CollaborationRepository)
// mais utilisent la même instance Dio configurée.

// Future<User> login(String email, String password) async {
//   final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
//   // Stocker le token reçu (response.data['access_token']) dans secureStorage
//   // Retourner l'objet User (response.data['user'])
//   return User.fromJson(response.data['user']);
// }

// Future<void> acceptInvitation(String invitationId) async {
//   await _dio.post('/invitations/$invitationId/accept');
// }

}