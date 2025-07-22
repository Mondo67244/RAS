import 'dart:convert';

import 'package:web/web.dart';

class LocalWishlistService {
  static const String _key = 'idSouhaits';

  static Future<void> addProductId(String id) async {
    final ids = await getProductIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await _saveIds(ids);
    }
  }

  static Future<void> removeProductId(String id) async {
    final ids = await getProductIds();
    ids.remove(id);
    await _saveIds(ids);
  }

  static Future<List<String>> getProductIds() async {
    final data = window.localStorage.getItem(_key);
    if (data != null) {
      return List<String>.from(jsonDecode(data));
    }
    return [];
  }

  static Future<void> _saveIds(List<String> ids) async {
    window.localStorage.setItem(_key, jsonEncode(ids));
  }

  static Future<void> clear() async {
    await _saveIds([]);
  }
}