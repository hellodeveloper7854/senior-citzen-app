import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoUtil {
  static final AesGcm _algorithm = AesGcm.with256bits();
  static const String _keyStorageKey = 'encryption_key_v1';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<SecretKey> _getSecretKey() async {
    final existing = await _storage.read(key: _keyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      final bytes = base64Decode(existing);
      return SecretKey(bytes);
    }
    final newKey = await _algorithm.newSecretKey();
    final bytes = await newKey.extractBytes();
    await _storage.write(key: _keyStorageKey, value: base64Encode(bytes));
    return SecretKey(bytes);
  }

  static List<int> _randomBytes(int length) {
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }

  /// Encrypts a string using AES-GCM with a per-installation key stored in
  /// platform keystore/keychain. Returns a base64 string that includes nonce+ciphertext+mac.
  static Future<String?> encryptString(String? plaintext) async {
    if (plaintext == null) return null;
    if (plaintext.isEmpty) return plaintext;
    try {
      final key = await _getSecretKey();
      final nonce = _randomBytes(12);
      final secretBox = await _algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        nonce: nonce,
      );
      final macBytes = secretBox.mac.bytes;
      final cipherText = secretBox.cipherText;

      final packed = Uint8List(nonce.length + cipherText.length + macBytes.length);
      packed.setRange(0, nonce.length, nonce);
      packed.setRange(nonce.length, nonce.length + cipherText.length, cipherText);
      packed.setRange(nonce.length + cipherText.length, packed.length, macBytes);

      return base64Encode(packed);
    } catch (e) {
      // Fallback: return original to avoid crashing in edge cases
      return plaintext;
    }
  }

  /// Decrypts a base64(nonce+ciphertext+mac) string. If the input is not a valid
  /// encrypted payload (e.g., legacy plaintext in DB), returns the original string.
  static Future<String?> decryptString(String? encoded) async {
    if (encoded == null) return null;
    if (encoded.isEmpty) return encoded;
    try {
      final data = base64Decode(encoded);
      if (data.length < 12 + 16) {
        // Too short to contain nonce + mac; assume plaintext
        return encoded;
      }
      final nonce = data.sublist(0, 12);
      final macBytes = data.sublist(data.length - 16);
      final cipherText = data.sublist(12, data.length - 16);

      final key = await _getSecretKey();
      final clearText = await _algorithm.decrypt(
        SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(macBytes),
        ),
        secretKey: key,
      );
      return utf8.decode(clearText);
    } catch (e) {
      // Backward compatibility or corrupt payload; return original
      return encoded;
    }
  }
}