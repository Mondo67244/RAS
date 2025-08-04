import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:RAS/basicdata/categorie.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/basicdata/facture.dart';
import 'package:RAS/basicdata/produit.dart';

class FirestoreService {
  final CollectionReference categoriesCollection = FirebaseFirestore.instance.collection('Categories');
  final CollectionReference utilisateursCollection = FirebaseFirestore.instance.collection('Utilisateurs');
  final CollectionReference produitsCollection = FirebaseFirestore.instance.collection('Produits');
  final CollectionReference commandesCollection = FirebaseFirestore.instance.collection('Commandes');
  final CollectionReference facturesCollection = FirebaseFirestore.instance.collection('Factures');

  Future<List<Categorie>> getCategories() async {
    try {
      QuerySnapshot snapshot = await categoriesCollection.get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Categorie(
          nomCategorie: data['nomCategorie'] ?? '',
          description: data['description'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Erreur dans getCategories: $e');
      rethrow;
    }
  }

  Future<void> addUtilisateur(Utilisateur utilisateur) async {
    try {
      print('Ajout de l\'utilisateur: ${utilisateur.toMap()}');
      await utilisateursCollection.doc(utilisateur.idUtilisateur).set({
        'idUtilisateur': utilisateur.idUtilisateur,
        'nomUtilisateur': utilisateur.nomUtilisateur,
        'prenomUtilisateur': utilisateur.prenomUtilisateur,
        'emailUtilisateur': utilisateur.emailUtilisateur,
        'numeroUtilisateur': utilisateur.numeroUtilisateur,
        'villeUtilisateur': utilisateur.villeUtilisateur,
      });
    } catch (e) {
      print('Erreur dans addUtilisateur: $e');
      rethrow;
    }
  }

  Future<List<Utilisateur>> getUtilisateurs() async {
    try {
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
    } catch (e) {
      print('Erreur dans getUtilisateurs: $e');
      rethrow;
    }
  }

  Future<void> updateProductWishlist(String productId, bool isWishlisted) async {
    try {
      print('Mise à jour de la wishlist pour le produit $productId: $isWishlisted');
      await produitsCollection.doc(productId).update({'jeVeut': isWishlisted});
    } catch (e) {
      print('Erreur dans updateProductWishlist: $e');
      rethrow;
    }
  }

  Future<void> updateProductCart(String productId, bool isCarted) async {
    try {
      print('Mise à jour du panier pour le produit $productId: $isCarted');
      await produitsCollection.doc(productId).update({'auPanier': isCarted});
    } catch (e) {
      print('Erreur dans updateProductCart: $e');
      rethrow;
    }
  }

  Future<void> addProduit(Produit produit) async {
    try {
      print('Ajout du produit: ${produit.toMap()}');
      final docRef = await produitsCollection.add(produit.toMap());
      await docRef.update({'idProduit': docRef.id});
    } catch (e) {
      print('Erreur dans addProduit: $e');
      rethrow;
    }
  }

  Future<List<Produit>> getProduits() async {
    try {
      QuerySnapshot snapshot = await produitsCollection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Produit.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Erreur dans getProduits: $e');
      return [];
    }
  }

  Future<void> updateProduit(Produit produit) async {
    try {
      print('Mise à jour du produit: ${produit.toMap()}');
      await produitsCollection.doc(produit.idProduit).update(produit.toMap());
    } catch (e) {
      print('Erreur dans updateProduit: $e');
      rethrow;
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
      return produitsCollection.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
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

  // Nouvelle méthode pour charger les produits avec pagination
  Future<List<Produit>> getProduitsPaginated(int limit, DocumentSnapshot? lastDocument) async {
    try {
      Query query = produitsCollection.orderBy('createdAt', descending: true).limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Produit.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Erreur dans getProduitsPaginated: $e');
      return [];
    }
  }

  // Nouvelle méthode pour charger les produits par catégorie avec pagination
  Future<List<Produit>> getProduitsByCategoryPaginated(String category, int limit, DocumentSnapshot? lastDocument) async {
    try {
      Query query = produitsCollection
          .where('categorie', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Produit.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Erreur dans getProduitsByCategoryPaginated: $e');
      return [];
    }
  }

  Future<void> addCommande(Commande commande) async {
    try {
      // Générer un ID unique pour la commande
      final commandeId = commandesCollection.doc().id;
      
      // Créer la commande avec l'ID correct dès le début
      final commandeMap = commande.toMap();
      commandeMap['idCommande'] = commandeId;
      
      print('Ajout de la commande: $commandeMap');
      
      // Créer directement le document avec l'ID
      await commandesCollection.doc(commandeId).set(commandeMap);
      print('Commande ajoutée avec succès: $commandeId');
    } catch (e, stackTrace) {
      print('Erreur dans addCommande: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<Commande>> recupCommandes() async {
    try {
      QuerySnapshot snapshot = await commandesCollection.get();
      print('Récupération de ${snapshot.docs.length} commandes');
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Commande.fromMap(data);
      }).toList();
    } catch (e) {
      print('Erreur dans recupCommandes: $e');
      return [];
    }
  }

  Future<void> ajouterFacture(Facture facture) async {
    try {
      print('Ajout de la facture: ${facture.toMap()}');
      await facturesCollection.doc(facture.idFacture).set(facture.toMap());
      print('Facture ajoutée: ${facture.idFacture}');
    } catch (e) {
      print('Erreur dans ajouterFacture: $e');
      rethrow;
    }
  }

  Future<List<Facture>> recupFactures() async {
    try {
      QuerySnapshot snapshot = await facturesCollection.get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Facture.fromMap(data);
      }).toList();
    } catch (e) {
      print('Erreur dans recupFactures: $e');
      return [];
    }
  }
}