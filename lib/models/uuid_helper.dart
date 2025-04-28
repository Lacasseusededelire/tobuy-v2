import 'package:uuid/uuid.dart';

/// Classe utilitaire pour générer des identifiants uniques universels (UUIDs).
/// Utilise la version 4 (aléatoire) des UUIDs.
class UuidHelper {
  // Instance unique et constante du générateur UUID.
  static const Uuid _uuidGenerator = Uuid();

  /// Génère une nouvelle chaîne UUID v4.
  ///
  /// Exemple: "f47ac10b-58cc-4372-a567-0e02b2c3d479"
  static String generate() {
    return _uuidGenerator.v4();
  }

// Vous pouvez ajouter d'autres méthodes liées aux UUIDs ici si nécessaire.
// static bool isValidUuid(String uuid) {
//   try {
//     Uuid.parse(uuid);
//     return true;
//   } catch (e) {
//     return false;
//   }
// }
}