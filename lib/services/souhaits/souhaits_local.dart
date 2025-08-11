import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'dart:async';

// import '../local/pont_stockage.dart';

class SouhaitsLocal {
  // final _stockage = PontStockage.instance;
  // final _key = 'souhaits';
  SharedPreferences? _prefs;
  final FirestoreService _firestoreService = FirestoreService();
  
  final StreamController<int> _wishlistCountController = StreamController<int>.broadcast();
  Stream<int> get wishlistCountStream => _wishlistCountController.stream;

  Future<void> init() async {
    // await _stockage.init();
    _prefs = await SharedPreferences.getInstance();
    // Emit initial count
    final count = (await getSouhaits()).length;
    _wishlistCountController.add(count);
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
      
      // Notify listeners of wishlist count change
      _wishlistCountController.add(souhait.length);
    }

    // Si l'utilisateur est connecté, synchroniser avec Firestore
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestoreService.ajouterAuxSouhaitsFirestore(user.uid, idProduit);
    }
  }

  Future<void> retirerDesSouhaits(String idProduit) async {
    // await _stockage.removeFromList(_key, idProduit);
    final souhait = await getSouhaits();
    souhait.remove(idProduit);
    await _prefs?.setStringList('souhaits', souhait);
    
    // Notify listeners of wishlist count change
    _wishlistCountController.add(souhait.length);

    // Si l'utilisateur est connecté, synchroniser avec Firestore
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestoreService.retirerDesSouhaitsFirestore(user.uid, idProduit);
    }
  }
  
  void dispose() {
    _wishlistCountController.close();
  }
}