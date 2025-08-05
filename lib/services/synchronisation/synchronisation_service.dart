import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:RAS/services/panier/panier_local.dart';
import 'package:RAS/services/souhaits/souhaits_local.dart';

class SynchronisationService {
  final PanierLocal _panierLocal = PanierLocal();
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Synchroniser le panier local avec Firestore
  Future<void> synchroniserPanier() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Initialiser les services locaux
      await _panierLocal.init();
      
      // Obtenir les éléments du panier local
      final List<String> panierLocal = await _panierLocal.getPanier();
      final Map<String, int> quantitesLocal = await _panierLocal.getQuantities();
      
      // Référence à la collection Panier de l'utilisateur
      final CollectionReference panierRef = _firestore
          .collection('Utilisateurs')
          .doc(user.uid)
          .collection('Panier');
      
      // Obtenir les éléments du panier Firestore
      final QuerySnapshot panierSnapshot = await panierRef.get();
      final List<DocumentSnapshot> panierFirestore = panierSnapshot.docs;
      
      // Fusionner les deux paniers (priorité au local en cas de conflit)
      // Ajouter les éléments locaux à Firestore
      for (String productId in panierLocal) {
        final int quantity = quantitesLocal[productId] ?? 1;
        
        // Ajouter/mettre à jour dans Firestore
        await panierRef.doc(productId).set({
          'idProduit': productId,
          'quantite': quantity,
          'dateAjout': FieldValue.serverTimestamp(),
        });
      }
      
      // Mettre à jour le panier local avec les éléments de Firestore
      // (en cas d'ajouts sur un autre appareil)
      for (DocumentSnapshot doc in panierFirestore) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final String productId = data['idProduit'];
        final int quantity = data['quantite'] ?? 1;
        
        // Si le produit n'est pas dans le panier local, on l'ajoute
        if (!panierLocal.contains(productId)) {
          await _panierLocal.ajouterAuPanier(productId, quantite: quantity);
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation du panier: $e');
      // Ne pas lancer l'exception pour ne pas bloquer l'authentification
    }
  }

  // Synchroniser la liste de souhaits locale avec Firestore
  Future<void> synchroniserSouhaits() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Initialiser les services locaux
      await _souhaitsLocal.init();
      
      // Obtenir les éléments de la liste de souhaits locale
      final List<String> souhaitsLocal = await _souhaitsLocal.getSouhaits();
      
      // Référence à la collection Souhaits de l'utilisateur
      final CollectionReference souhaitsRef = _firestore
          .collection('Utilisateurs')
          .doc(user.uid)
          .collection('Souhaits');
      
      // Obtenir les éléments de la liste de souhaits Firestore
      final QuerySnapshot souhaitsSnapshot = await souhaitsRef.get();
      final List<DocumentSnapshot> souhaitsFirestore = souhaitsSnapshot.docs;
      
      // Fusionner les deux listes (priorité au local en cas de conflit)
      for (String productId in souhaitsLocal) {
        // Ajouter dans Firestore si non présent
        await souhaitsRef.doc(productId).set({
          'idProduit': productId,
          'dateAjout': FieldValue.serverTimestamp(),
        });
      }
      
      // Mettre à jour la liste de souhaits locale avec les éléments de Firestore
      // (en cas d'ajouts sur un autre appareil)
      for (DocumentSnapshot doc in souhaitsFirestore) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final String productId = data['idProduit'];
        
        // Si le produit n'est pas dans la liste de souhaits locale, on l'ajoute
        if (!souhaitsLocal.contains(productId)) {
          await _souhaitsLocal.ajouterAuxSouhaits(productId);
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des souhaits: $e');
      // Ne pas lancer l'exception pour ne pas bloquer l'authentification
    }
  }

  // Synchroniser à la fois le panier et la liste de souhaits
  Future<void> synchroniserTout() async {
    await synchroniserPanier();
    await synchroniserSouhaits();
  }
}