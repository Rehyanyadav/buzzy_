import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyAlias = 'vault_key';

  static Future<String> _getOrGenerateKey() async {
    String? key = await _storage.read(key: _keyAlias);
    if (key == null) {
      key = Key.fromSecureRandom(32).base64;
      await _storage.write(key: _keyAlias, value: key);
    }
    return key;
  }

  static Future<String> encrypt(String text) async {
    final keyStr = await _getOrGenerateKey();
    final key = Key.fromBase64(keyStr);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));

    final encrypted = encrypter.encrypt(text, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static Future<String> decrypt(String encryptedText) async {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return encryptedText;

      final iv = IV.fromBase64(parts[0]);
      final encrypted = parts[1];

      final keyStr = await _getOrGenerateKey();
      final key = Key.fromBase64(keyStr);
      final encrypter = Encrypter(AES(key));

      return encrypter.decrypt64(encrypted, iv: iv);
    } catch (e) {
      return 'Decryption Error';
    }
  }
}
