
import '../local/pont_stockage.dart';

class SouhaitsLocal {
  final _stockage = PontStockage.instance;
  final _key = 'souhaits';

  Future<void> init() async {
    await _stockage.init();
  }

  Future<List<String>> getSouhaits() async {
    return _stockage.getList(_key);
  }

  Future<void> ajouterAuxSouhaits(String idProduit) async {
    await _stockage.addToList(_key, idProduit);
  }

  Future<void> retirerDesSouhaits(String idProduit) async {
    await _stockage.removeFromList(_key, idProduit);
  }
}
