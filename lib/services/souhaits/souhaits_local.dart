import 'package:shared_preferences/shared_preferences.dart';

// import '../local/pont_stockage.dart';

class SouhaitsLocal {
  // final _stockage = PontStockage.instance;
  // final _key = 'souhaits';
  SharedPreferences? _prefs;

  Future<void> init() async {
    // await _stockage.init();
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<String>> getSouhaits() async {
    // return _stockage.getList(_key);
    return _prefs?.getStringList('souhaits') ?? [];
  }

  Future<void> ajouterAuxSouhaits(String idProduit) async {
    // await _stockage.addToList(_key, idProduit);
    final souhait = await getSouhaits();
    if (!souhait.contains(idProduit)) {
      souhait.add(idProduit);
      await _prefs?.setStringList('souhaits', souhait);
    }
  }

  Future<void> retirerDesSouhaits(String idProduit) async {
    // await _stockage.removeFromList(_key, idProduit);
    final souhait = await getSouhaits();
    souhait.remove(idProduit);
    await _prefs?.setStringList('souhaits', souhait);
  }
}
