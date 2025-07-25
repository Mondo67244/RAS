import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ras_app/basicdata/categorie.dart';
import 'package:ras_app/basicdata/utilisateur.dart';
import 'package:ras_app/basicdata/commande.dart';
import 'package:ras_app/basicdata/facture.dart';
import 'package:ras_app/basicdata/produit.dart';

class FirestoreService {
  // Collections references
  final CollectionReference categoriesCollection = FirebaseFirestore.instance
      .collection('Categories');
  final CollectionReference utilisateursCollection = FirebaseFirestore.instance
      .collection('Utilisateurs');
  final CollectionReference produitsCollection = FirebaseFirestore.instance
      .collection('Produits');
  final CollectionReference commandesCollection = FirebaseFirestore.instance
      .collection('Commandes');
  final CollectionReference facturesCollection = FirebaseFirestore.instance
      .collection('Factures');

  // =======================================================================
  // Opérations pour la collection catégorie
  // =======================================================================

  

  Future<List<Categorie>> getCategories() async {
    QuerySnapshot snapshot = await categoriesCollection.get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Categorie(
        nomCategorie: data['nomCategorie'] ?? '',
        description: data['description'] ?? '',
      );
    }).toList();
  }

  // =======================================================================
  // Opération pour les utilisateurs
  // =======================================================================

  Future<void> addUtilisateur(Utilisateur utilisateur) {
    return utilisateursCollection.doc(utilisateur.idUtilisateur).set({
      'idUtilisateur': utilisateur.idUtilisateur,
      'nomUtilisateur': utilisateur.nomUtilisateur,
      'prenomUtilisateur': utilisateur.prenomUtilisateur,
      'emailUtilisateur': utilisateur.emailUtilisateur,
      'numeroUtilisateur': utilisateur.numeroUtilisateur,
      'villeUtilisateur': utilisateur.villeUtilisateur,
    });
  }

  Future<List<Utilisateur>> getUtilisateurs() async {
    QuerySnapshot snapshot = await utilisateursCollection.get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Utilisateur(
        idUtilisateur: data['idUtilisateur'] ?? '',
        nomUtilisateur: data['nomUtilisateur'] ?? '',
        prenomUtilisateur: data['prenomUtilisateur'] ?? '',
        emailUtilisateur: data['emailUtilisateur'] ?? '',
        numeroUtilisateur: data['numeroUtilisateur'] ?? 0,
        villeUtilisateur: data['villeUtilisateur'] ?? '',
      );
    }).toList();
  }

  // =======================================================================
  
  Future<void> updateProductWishlist(String productId, bool isWishlisted) async {
    await produitsCollection.doc(productId).update({'jeVeut': isWishlisted});
  }

  Future<void> updateProductCart(String productId, bool isCarted) async {
    await produitsCollection.doc(productId).update({'auPanier': isCarted});
  }

  // =======================================================================

  Future<void> addProduit(Produit produit) {
    return produitsCollection.add(produit.toMap());
  }

  Future<List<Produit>> getProduits() async {
    try {
      QuerySnapshot snapshot =
          await produitsCollection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Produit.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Erreur dans getProduits: $e');
      return [];
    }
  }

  Stream<Produit> getProduitStream(String produitId) {
    try {
      return produitsCollection.doc(produitId).snapshots().map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Produit.fromMap(data, doc.id);
      });
    } catch (e) {
      print('Erreur dans getProduitStream: $e');
      return Stream.error(e);
    }
  }

  Stream<List<Produit>> getProduitsStream() {
    try {
      return produitsCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return Produit.fromMap(data, doc.id);
        }).toList();
      });
    } catch (e) {
      print('Erreur dans getProduitsStream: $e');
      return Stream.value([]);
    }
  }

  // =======================================================================
  // Opérations pour les commandes
  // =======================================================================

  Future<void> addCommande(Commande commande) async {
    try {
      await commandesCollection.doc(commande.idCommande).set(commande.toMap());
      print('Commande ajoutée: ${commande.idCommande}');
    } catch (e) {
      print('Erreur dans addCommande: $e');
    }
  }

  Future<List<Commande>> getCommandes() async {
    try {
      QuerySnapshot snapshot = await commandesCollection.get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Commande.fromMap(data);
      }).toList();
    } catch (e) {
      print('Erreur dans getCommandes: $e');
      return [];
    }
  }

  // =======================================================================
  // Opérations pour les factures
  // =======================================================================

  Future<void> addFacture(Facture facture) async {
    try {
      await facturesCollection.doc(facture.idFacture).set(facture.toMap());
      print('Facture ajoutée: ${facture.idFacture}');
    } catch (e) {
      print('Erreur dans addFacture: $e');
    }
  }

  Future<List<Facture>> getFactures() async {
    try {
      QuerySnapshot snapshot = await facturesCollection.get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Facture.fromMap(data);
      }).toList();
    } catch (e) {
      print('Erreur dans getFactures: $e');
      return [];
    }
  }
}