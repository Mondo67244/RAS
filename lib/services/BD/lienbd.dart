import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:RAS/basicdata/categorie.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/basicdata/facture.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/message.dart'; // Ajout de l'import du modèle Message

class FirestoreService {
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
  final CollectionReference messagesCollection = FirebaseFirestore.instance
      .collection('Messages'); // Ajout de la collection Messages

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

  Future<void> updateProductWishlist(
    String productId,
    bool isWishlisted,
  ) async {
    try {
      print(
        'Mise à jour de la wishlist pour le produit $productId: $isWishlisted',
      );
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

  // Méthodes pour gérer le panier de l'utilisateur dans Firestore
  Future<void> ajouterAuPanierFirestore(
    String userId,
    String productId,
    int quantity,
  ) async {
    try {
      await utilisateursCollection
          .doc(userId)
          .collection('Panier')
          .doc(productId)
          .set({
            'idProduit': productId,
            'quantite': quantity,
            'dateAjout': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Erreur dans ajouterAuPanierFirestore: $e');
      rethrow;
    }
  }

  Future<void> retirerDuPanierFirestore(String userId, String productId) async {
    try {
      await utilisateursCollection
          .doc(userId)
          .collection('Panier')
          .doc(productId)
          .delete();
    } catch (e) {
      print('Erreur dans retirerDuPanierFirestore: $e');
      rethrow;
    }
  }

  Future<void> updateQuantitePanierFirestore(
    String userId,
    String productId,
    int quantity,
  ) async {
    try {
      await utilisateursCollection
          .doc(userId)
          .collection('Panier')
          .doc(productId)
          .update({
            'quantite': quantity,
            'dateModification': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Erreur dans updateQuantitePanierFirestore: $e');
      rethrow;
    }
  }

  Future<void> viderPanierFirestore(String userId) async {
    try {
      final panierRef = utilisateursCollection.doc(userId).collection('Panier');
      final snap = await panierRef.get();
      if (snap.docs.isEmpty) return;
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Erreur dans viderPanierFirestore: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPanierUtilisateur(String userId) async {
    try {
      QuerySnapshot snapshot =
          await utilisateursCollection.doc(userId).collection('Panier').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'idProduit': data['idProduit'], 'quantite': data['quantite']};
      }).toList();
    } catch (e) {
      print('Erreur dans getPanierUtilisateur: $e');
      return [];
    }
  }

  // Méthodes pour gérer la liste de souhaits de l'utilisateur dans Firestore
  Future<void> ajouterAuxSouhaitsFirestore(
    String userId,
    String productId,
  ) async {
    try {
      await utilisateursCollection
          .doc(userId)
          .collection('Souhaits')
          .doc(productId)
          .set({
            'idProduit': productId,
            'dateAjout': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Erreur dans ajouterAuxSouhaitsFirestore: $e');
      rethrow;
    }
  }

  Future<void> retirerDesSouhaitsFirestore(
    String userId,
    String productId,
  ) async {
    try {
      await utilisateursCollection
          .doc(userId)
          .collection('Souhaits')
          .doc(productId)
          .delete();
    } catch (e) {
      print('Erreur dans retirerDesSouhaitsFirestore: $e');
      rethrow;
    }
  }

  Future<List<String>> getSouhaitsUtilisateur(String userId) async {
    try {
      QuerySnapshot snapshot =
          await utilisateursCollection.doc(userId).collection('Souhaits').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['idProduit'] as String;
      }).toList();
    } catch (e) {
      print('Erreur dans getSouhaitsUtilisateur: $e');
      return [];
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

  // Nouvelle méthode pour charger les produits avec pagination
  Future<List<Produit>> getProduitsPaginated(
    int limit,
    DocumentSnapshot? lastDocument,
  ) async {
    try {
      Query query = produitsCollection
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
      print('Erreur dans getProduitsPaginated: $e');
      return [];
    }
  }

  // Nouvelle méthode pour charger les produits par catégorie avec pagination
  Future<List<Produit>> getProduitsByCategoryPaginated(
    String category,
    int limit,
    DocumentSnapshot? lastDocument,
  ) async {
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

  Future<Facture?> getFactureById(String factureId) async {
    try {
      DocumentSnapshot snapshot = await facturesCollection.doc(factureId).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return Facture.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Erreur dans getFactureById: $e');
      return null;
    }
  }

  Future<Facture?> getFactureByOrderId(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Erreur dans getFactureByOrderId: Utilisateur non authentifié');
        return null;
      }
      
      // Query factures that contain the order ID in their ID and belong to the current user
      QuerySnapshot snapshot =
          await facturesCollection
              .where('utilisateur.idUtilisateur', isEqualTo: user.uid)
              .where(
                'idFacture',
                isGreaterThanOrEqualTo: 'FACT-${orderId.toUpperCase()}',
              )
              .where(
                'idFacture',
                isLessThan: 'FACT-${orderId.toUpperCase()}\uf8ff',
              )
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> data =
            snapshot.docs.first.data() as Map<String, dynamic>;
        return Facture.fromMap(data);
      }

      return null;
    } catch (e) {
      print('Erreur dans getFactureByOrderId: $e');
      return null;
    }
  }

  // Ajout de méthodes pour gérer les messages
  Future<void> sendMessage(Message message) async {
    try {
      await messagesCollection.add(message.toMap());
    } catch (e) {
      print('Erreur dans sendMessage: $e');
      rethrow;
    }
  }

  Stream<List<Message>> getMessagesStream(String conversationId) {
    try {
      return messagesCollection
          .where('idConversation', isEqualTo: conversationId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                return Message.fromMap(data, doc.id);
              } catch (e) {
                // En cas d'erreur de conversion, créer un message par défaut
                return Message(
                  idMessage: doc.id,
                  contenuMessage: 'Message non disponible',
                  idExpediteur: '',
                  idDestinataire: '',
                  idProduit: '',
                  idConversation: conversationId,
                  timestamp: Timestamp.now(),
                );
              }
            }).toList();
          });
    } catch (e) {
      print('Erreur dans getMessagesStream: $e');
      return Stream.value([]);
    }
  }
}
