import 'package:shared_preferences/shared_preferences.dart';

class LocalCartService {
  static const String _key = 'idPanier';

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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> _saveIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids);
  }

  static Future<void> clear() async {
    await _saveIds([]);
  }
} 