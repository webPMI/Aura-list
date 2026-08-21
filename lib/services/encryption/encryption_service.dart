import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';
import '../logger_service.dart';

/// Servicio de Cifrado de Extremo a Extremo (E2EE / Zero-Knowledge)
///
/// Cifra y descifra los datos sensibles de tareas, notas y finanzas antes
/// de enviarlos o leerlos de la nube (Firebase Firestore).
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const String _prefUserKey = 'aura_e2ee_user_master_key_v1';
  final LoggerService _logger = LoggerService();

  enc.Key? _key;
  bool _isInitialized = false;

  /// Retorna si el servicio de cifrado está inicializado y listo.
  bool get isInitialized => _isInitialized && _key != null;

  /// Inicializa el servicio de cifrado cargando o generando la clave maestra del usuario.
  Future<void> initialize({String? customKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (customKey != null && customKey.isNotEmpty) {
        // Derivar clave de 32 bytes (256 bits) usando SHA-256 si es una frase personalizada
        final keyBytes = sha256.convert(utf8.encode(customKey)).bytes;
        _key = enc.Key.fromBase64(base64Encode(keyBytes));
        await prefs.setString(_prefUserKey, _key!.base64);
        _isInitialized = true;
        _logger.info('EncryptionService', 'Clave personalizada inicializada con éxito');
        return;
      }

      // Buscar clave existente en almacenamiento seguro local
      final existingKeyBase64 = prefs.getString(_prefUserKey);
      if (existingKeyBase64 != null && existingKeyBase64.isNotEmpty) {
        _key = enc.Key.fromBase64(existingKeyBase64);
        _isInitialized = true;
        _logger.info('EncryptionService', 'Clave existente cargada con éxito');
      } else {
        // Generar nueva clave aleatoria segura de 256 bits (32 bytes)
        _key = enc.Key.fromSecureRandom(32);
        await prefs.setString(_prefUserKey, _key!.base64);
        _isInitialized = true;
        _logger.info('EncryptionService', 'Nueva clave E2EE de 256-bit generada');
      }
    } catch (e) {
      _logger.error('EncryptionService', 'Error inicializando EncryptionService', error: e);
      // Fallback seguro en memoria en caso de error de prefs
      _key = enc.Key.fromSecureRandom(32);
      _isInitialized = true;
    }
  }

  /// Retorna la clave personal de cifrado en formato Base64 para respaldo del usuario.
  String get exportableKey {
    if (_key == null) return '';
    return _key!.base64;
  }

  /// Importa una clave existente en Base64 o frase maestra.
  Future<void> importKey(String userProvidedKey) async {
    await initialize(customKey: userProvidedKey.trim());
  }

  /// Cifra un Map de datos en un objeto seguro para Firestore.
  Map<String, dynamic> encryptMap(Map<String, dynamic> plainData) {
    _key ??= enc.Key.fromSecureRandom(32);

    try {
      final jsonString = jsonEncode(plainData);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(jsonString, iv: iv);

      return {
        'encrypted': true,
        'payload': encrypted.base64,
        'iv': iv.base64,
        'version': 1,
        // Conservamos metadatos de sincronización no sensibles para delta-sync
        'lastUpdatedAt': plainData['lastUpdatedAt'] ?? DateTime.now().toIso8601String(),
        'deleted': plainData['deleted'] ?? false,
        if (plainData['deletedAt'] != null) 'deletedAt': plainData['deletedAt'],
      };
    } catch (e) {
      _logger.error('EncryptionService', 'Error cifrando mapa', error: e);
      // En caso de fallo inesperado, retornar los datos para evitar pérdida
      return plainData;
    }
  }

  /// Descifra un Map recibido de Firestore (soporta documentos cifrados y legados).
  Map<String, dynamic> decryptMap(Map<String, dynamic> cloudData) {
    // Si no está marcado como cifrado, es un documento legado en texto plano
    if (cloudData['encrypted'] != true || cloudData['payload'] == null || cloudData['iv'] == null) {
      return cloudData;
    }

    if (_key == null) {
      _logger.warning('EncryptionService', 'Intentando descifrar sin clave cargada');
      return cloudData;
    }

    try {
      final payloadBase64 = cloudData['payload'] as String;
      final ivBase64 = cloudData['iv'] as String;

      final iv = enc.IV.fromBase64(ivBase64);
      final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
      final decryptedString = encrypter.decrypt64(payloadBase64, iv: iv);

      final decryptedMap = jsonDecode(decryptedString) as Map<String, dynamic>;
      return decryptedMap;
    } catch (e) {
      _logger.error('EncryptionService', 'Error descifrando mapa', error: e);
      return cloudData;
    }
  }
}
