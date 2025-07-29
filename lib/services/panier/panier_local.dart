import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// import '../local/pont_stockage.dart';

class PanierLocal {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<String>> getPanier() async {
    return _prefs?.getStringList('panier') ?? [];
  }

  Future<Map<String, int>> getQuantities() async {
    final String? quantitiesJson = _prefs?.getString('quantities');
    if (quantitiesJson != null) {
      return Map<String, int>.from(jsonDecode(quantitiesJson));
    }
    return {};
  }

  Future<void> ajouterAuPanier(String idProduit, {int quantite = 1}) async {
    final panier = await getPanier();
    if (!panier.contains(idProduit)) {
      panier.add(idProduit);
      await _prefs?.setStringList('panier', panier);
    }
    final quantities = await getQuantities();
    quantities[idProduit] = quantite;
    await _prefs?.setString('quantities', jsonEncode(quantities));
  }

  Future<void> retirerDuPanier(String idProduit) async {
    final panier = await getPanier();
    panier.remove(idProduit);
    await _prefs?.setStringList('panier', panier);
    final quantities = await getQuantities();
    quantities.remove(idProduit);
    await _prefs?.setString('quantities', jsonEncode(quantities));
  }

  Future<void> updateQuantity(String idProduit, int quantite) async {
    final quantities = await getQuantities();
    quantities[idProduit] = quantite;
    await _prefs?.setString('quantities', jsonEncode(quantities));
  }

  Future<void> saveDeliveryMethod(String method) async {
    await _prefs?.setString('delivery_method', method);
  }

  Future<String?> getDeliveryMethod() async {
    return _prefs?.getString('delivery_method');
  }

  Future<void> savePaymentMethod(String method) async {
    await _prefs?.setString('payment_method', method);
  }

  Future<String?> getPaymentMethod() async {
    return _prefs?.getString('payment_method');
  }
}
