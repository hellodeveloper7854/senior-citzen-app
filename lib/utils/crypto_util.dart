import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class CryptoUtil {
  static final AesCbc _algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
  static final SecretKey _key = SecretKey(utf8.encode('ThaneMitrSecretKey1234567890abcd')); // 32 bytes
  static final List<int> _iv = utf8.encode('VectorInit123456'); // 16 bytes

  /// Encrypts a string using AES-CBC with fixed key and IV. Returns base64-encoded ciphertext.
  static Future<String?> encryptString(String? plaintext) async {
    if (plaintext == null) return null;
    if (plaintext.isEmpty) return plaintext;
    try {
      final secretBox = await _algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: _key,
        nonce: _iv,
      );
      return base64Encode(secretBox.cipherText);
    } catch (e) {
      // Fallback: return original
      return plaintext;
    }
  }

  /// Decrypts a base64-encoded ciphertext string. If decryption fails, returns the original string.
  static Future<String?> decryptString(String? encoded) async {
    if (encoded == null) return null;
    if (encoded.isEmpty) return encoded;
    try {
      final cipherText = base64Decode(encoded);
      final clearText = await _algorithm.decrypt(
        SecretBox(cipherText, nonce: _iv, mac: Mac.empty),
        secretKey: _key,
      );
      return utf8.decode(clearText);
    } catch (e) {
      // Return original on failure
      return encoded;
    }
  }
}