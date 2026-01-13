import 'dart:convert';

import 'package:flutter/material.dart';

/// Convert a backend profile image field into an [ImageProvider].
///
/// Supported formats:
/// - Public URL (http/https)
/// - Raw base64 string
/// - data URI (data:image/...;base64,....)
///
/// Returns null when the input is null/empty/invalid.
class ImageUtil {
  static ImageProvider? imageProviderFromString(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty) return null;

    if (v.startsWith('http://') || v.startsWith('https://')) {
      return NetworkImage(v);
    }

    final base64Payload = (v.startsWith('data:') && v.contains(','))
        ? v.substring(v.indexOf(',') + 1)
        : v;

    try {
      return MemoryImage(base64Decode(base64Payload));
    } catch (_) {
      return null;
    }
  }
}

