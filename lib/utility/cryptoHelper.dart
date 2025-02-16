import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class CryptoHelper {
  // Encryption key (32 bytes for AES-256)
  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');

  // Method to encrypt data
  static String encryptData(String plainText) {
    final iv = encrypt.IV.fromLength(16); // Generate a random 16-byte IV
    final encrypter =
        encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Combine IV and ciphertext (IV needs to be stored to decrypt later)
    final combined = iv.base64 + ":" + encrypted.base64;

    return combined;
  }

  // Method to decrypt data
  static String decryptData(String encryptedData) {
    // Split the combined string into IV and ciphertext
    final parts = encryptedData.split(":");
    if (parts.length != 2) {
      throw ArgumentError("Invalid encrypted data format");
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));

    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }
}
