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

  Future<void> addCategorie(Categorie categorie) {
    return categoriesCollection.doc(categorie.nomCategorie).set({
      'nomCategorie': categorie.nomCategorie,
      'description': categorie.description,
    });
  }

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

  Future<List<Produit>> getProduits() async {
    try {
      QuerySnapshot snapshot =
          await produitsCollection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Produit(
          descriptionCourte: data['descriptionCourte'] ?? '',
          sousCategorie: data['sousCategorie'] ?? '',
          enPromo: data['enPromo'] ?? false,
          cash: data['cash'] ?? false,
          electronique: data['electronique'] ?? false,
          quantite: data['quantite'] ?? '',
          livrable: data['livrable'] ?? true,
          createdAt: data['createdAt'] ?? Timestamp.now(),
          enStock: data['enStock'] ?? true,
          img1: data['img1'] ?? '',
          img2: data['img2'] ?? '',
          img3: data['img3'] ?? '',
          auPanier: data['auPanier'] ?? false,
          idProduit: doc.id,
          nomProduit: data['nomProduit'] ?? '',
          description: data['description'] ?? '',
          prix: data['prix'] ?? '',
          vues: data['vues']?.toString() ?? '0',
          modele: data['modele'] ?? '',
          marque: data['marque'] ?? '',
          categorie: data['categorie'] ?? '',
          type: data['type'] ?? '',
          jeVeut: data['jeVeut'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('Erreur dans getProduits: $e');
      return [];
    }
  }

  Future<void> updateProductWishlist(String productId, bool newStatus) async {
    try {
      await produitsCollection.doc(productId).update({
        'jeVeut': newStatus,
        if (newStatus) 'auPanier': false,
      });
      print('Produit $productId mis à jour: jeVeut=$newStatus');
    } catch (e) {
      print('Erreur dans updateProductWishlist: $e');
    }
  }

  Future<void> updateProductCart(String productId, bool newStatus) async {
    try {
      await produitsCollection.doc(productId).update({
        'auPanier': newStatus,
        if (newStatus) 'jeVeut': false,
      });
      print('Produit $productId mis à jour: auPanier=$newStatus');
    } catch (e) {
      print('Erreur dans updateProductCart: $e');
    }
  }

  Future<void> addCommande(Commande commande) async {
    try {
      Map<String, dynamic> utilisateurMap = {
        'idUtilisateur': commande.utilisateur.idUtilisateur,
        'nomUtilisateur': commande.utilisateur.nomUtilisateur,
        'prenomUtilisateur': commande.utilisateur.prenomUtilisateur,
        'emailUtilisateur': commande.utilisateur.emailUtilisateur,
        'numeroUtilisateur': commande.utilisateur.numeroUtilisateur,
        'villeUtilisateur': commande.utilisateur.villeUtilisateur,
      };

      List<Map<String, dynamic>> produitsMap =
          commande.produit
              .map(
                (produit) => {
                  'idProduit': produit.idProduit,
                  'nomProduit': produit.nomProduit,
                  'description': produit.description,
                  'descriptionCourte': produit.descriptionCourte,
                  'prix': produit.prix,
                  'vues': produit.vues,
                  'modele': produit.modele,
                  'marque': produit.marque,
                  'categorie': produit.categorie,
                  'type': produit.type,
                  'jeVeut': produit.jeVeut,
                  'auPanier': produit.auPanier,
                  'sousCategorie': produit.sousCategorie,
                  'cash': produit.cash,
                  'electronique': produit.electronique,
                  'quantite': produit.quantite,
                  'livrable': produit.livrable,
                  'createdAt': produit.createdAt,
                  'enStock': produit.enStock,
                  'img1': produit.img1,
                  'img2': produit.img2,
                  'img3': produit.img3,
                },
              )
              .toList();

      await commandesCollection.doc(commande.idCommande).set({
        'idCommande': commande.idCommande,
        'dateCommande': commande.dateCommande,
        'noteCommande': commande.noteCommande,
        'pays': commande.pays,
        'rue': commande.rue,
        'prixCommande': commande.prixCommande,
        'ville': commande.ville,
        'codePostal': commande.codePostal,
        'Utilisateur': utilisateurMap,
        'produit': produitsMap,
        'methodePaiment': commande.methodePaiment,
        'choixLivraison': commande.choixLivraison,
      });
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

        Map<String, dynamic> utilisateurData =
            data['Utilisateur'] as Map<String, dynamic>;
        Utilisateur utilisateur = Utilisateur(
          idUtilisateur: utilisateurData['idUtilisateur'] ?? '',
          nomUtilisateur: utilisateurData['nomUtilisateur'] ?? '',
          prenomUtilisateur: utilisateurData['prenomUtilisateur'] ?? '',
          emailUtilisateur: utilisateurData['emailUtilisateur'] ?? '',
          numeroUtilisateur: utilisateurData['numeroUtilisateur'] ?? 0,
          villeUtilisateur: utilisateurData['villeUtilisateur'] ?? '',
        );

        List<dynamic> produitsData = data['produit'] as List<dynamic>;
        List<Produit> produits =
            produitsData.map((produitData) {
              return Produit(
                descriptionCourte: produitData['descriptionCourte'] ?? '',
                sousCategorie: produitData['sousCategorie'] ?? '',
                enPromo: produitData['enPromo'] ?? false,
                cash: produitData['cash'] ?? false,
                electronique: produitData['electronique'] ?? false,
                quantite: produitData['quantite'] ?? '',
                livrable: produitData['livrable'] ?? true,
                createdAt: produitData['createdAt'] ?? Timestamp.now(),
                enStock: produitData['enStock'] ?? true,
                img1: produitData['img1'] ?? '',
                img2: produitData['img2'] ?? '',
                img3: produitData['img3'] ?? '',
                idProduit: produitData['idProduit'] ?? '',
                nomProduit: produitData['nomProduit'] ?? '',
                description: produitData['description'] ?? '',
                prix: produitData['prix'] ?? '',
                vues: produitData['vues']?.toString() ?? '0',
                modele: produitData['modele'] ?? '',
                marque: produitData['marque'] ?? '',
                categorie: produitData['categorie'] ?? '',
                type: produitData['type'] ?? '',
                jeVeut: produitData['jeVeut'] ?? false,
                auPanier: produitData['auPanier'] ?? false,
              );
            }).toList();

        return Commande(
          auPanier: false,
          enSouhait: false,
          idCommande: data['idCommande'] ?? '',
          dateCommande: data['dateCommande'] ?? '',
          noteCommande: data['noteCommande'] ?? '',
          pays: data['pays'] ?? '',
          rue: data['rue'] ?? '',
          prixCommande: data['prixCommande'] ?? '',
          ville: data['ville'] ?? '',
          codePostal: data['codePostal'] ?? '',
          utilisateur: utilisateur,
          produit: produits,
          enPromo: false,
          methodePaiment: data['methodePaiment'] ?? false,
          choixLivraison: data['choixLivraison'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('Erreur dans getCommandes: $e');
      return [];
    }
  }

  Future<void> addFacture(Facture facture) async {
    try {
      Map<String, dynamic> utilisateurMap = {
        'idUtilisateur': facture.utilisateur.idUtilisateur,
        'nomUtilisateur': facture.utilisateur.nomUtilisateur,
        'prenomUtilisateur': facture.utilisateur.prenomUtilisateur,
        'emailUtilisateur': facture.utilisateur.emailUtilisateur,
        'numeroUtilisateur': facture.utilisateur.numeroUtilisateur,
        'villeUtilisateur': facture.utilisateur.villeUtilisateur,
      };

      List<Map<String, dynamic>> produitsMap =
          facture.Produits.map(
            (produit) => {
              'idProduit': produit.idProduit,
              'nomProduit': produit.nomProduit,
              'description': produit.description,
              'descriptionCourte': produit.descriptionCourte,
              'prix': produit.prix,
              'vues': produit.vues,
              'modele': produit.modele,
              'marque': produit.marque,
              'categorie': produit.categorie,
              'type': produit.type,
              'jeVeut': produit.jeVeut,
              'auPanier': produit.auPanier,
              'sousCategorie': produit.sousCategorie,
              'cash': produit.cash,
              'electronique': produit.electronique,
              'quantite': produit.quantite,
              'livrable': produit.livrable,
              'createdAt': produit.createdAt,
              'enStock': produit.enStock,
              'img1': produit.img1,
              'img2': produit.img2,
              'img3': produit.img3,
            },
          ).toList();

      await facturesCollection.doc(facture.idFacture).set({
        'idFacture': facture.idFacture,
        'dateFacture': facture.dateFacture,
        'Utilisateur': utilisateurMap,
        'Produits': produitsMap,
        'prixFacture': facture.prixFacture,
        'quantite': facture.quantite,
      });
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

        Map<String, dynamic> utilisateurData =
            data['Utilisateur'] as Map<String, dynamic>;
        Utilisateur utilisateur = Utilisateur(
          idUtilisateur: utilisateurData['idUtilisateur'] ?? '',
          nomUtilisateur: utilisateurData['nomUtilisateur'] ?? '',
          prenomUtilisateur: utilisateurData['prenomUtilisateur'] ?? '',
          emailUtilisateur: utilisateurData['emailUtilisateur'] ?? '',
          numeroUtilisateur: utilisateurData['numeroUtilisateur'] ?? 0,
          villeUtilisateur: utilisateurData['villeUtilisateur'] ?? '',
        );

        List<dynamic> produitsData = data['Produits'] as List<dynamic>;
        List<Produit> produits =
            produitsData.map((produitData) {
              return Produit(
                descriptionCourte: produitData['descriptionCourte'] ?? '',
                sousCategorie: produitData['sousCategorie'] ?? '',
                enPromo: produitData['enPromo'] ?? false,
                cash: produitData['cash'] ?? false,
                electronique: produitData['electronique'] ?? false,
                quantite: produitData['quantite'] ?? '',
                livrable: produitData['livrable'] ?? true,
                createdAt: produitData['createdAt'] ?? Timestamp.now(),
                enStock: produitData['enStock'] ?? true,
                img1: produitData['img1'] ?? '',
                img2: produitData['img2'] ?? '',
                img3: produitData['img3'] ?? '',
                idProduit: produitData['idProduit'] ?? '',
                nomProduit: produitData['nomProduit'] ?? '',
                description: produitData['description'] ?? '',
                prix: produitData['prix'] ?? '',
                vues: produitData['vues']?.toString() ?? '0',
                modele: produitData['modele'] ?? '',
                marque: produitData['marque'] ?? '',
                categorie: produitData['categorie'] ?? '',
                type: produitData['type'] ?? '',
                jeVeut: produitData['jeVeut'] ?? false,
                auPanier: produitData['auPanier'] ?? false,
              );
            }).toList();

        return Facture(
          idFacture: data['idFacture'] ?? '',
          dateFacture: data['dateFacture'] ?? '',
          utilisateur: utilisateur,
          Produits: produits,
          prixFacture: data['prixFacture'] ?? 0,
          quantite: data['quantite'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Erreur dans getFactures: $e');
      return [];
    }
  }

  Future<void> ajoutListeSouhait(String userId, Produit produit) async {
    try {
      await utilisateursCollection
          .doc(userId)
          .collection('wishlist')
          .doc(produit.idProduit)
          .set({
            'idProduit': produit.idProduit,
            'nomProduit': produit.nomProduit,
            'descriptionCourte': produit.descriptionCourte,
            'img1': produit.img1,
            'img2': produit.img2,
            'img3': produit.img3,
            'prix': produit.prix,
            'categorie': produit.categorie,
            'sousCategorie': produit.sousCategorie,
            'marque': produit.marque,
            'modele': produit.modele,
            'type': produit.type,
            'enStock': produit.enStock,
            'livrable': produit.livrable,
            'quantite': produit.quantite,
            'cash': produit.cash,
            'electronique': produit.electronique,
            'enPromo': produit.enPromo,
            'createdAt': Timestamp.now(),
          });
      print('Produit ajouté à la wishlist de $userId: ${produit.idProduit}');
    } catch (e) {
      print('Erreur lors de l\'ajout à la wishlist: $e');
    }
  }

  Future<void> removeFromWishlist(String userId, String produitId) async {
    try {
      await utilisateursCollection
          .doc(userId)
          .collection('wishlist')
          .doc(produitId)
          .delete();
      print('Produit retiré de la wishlist de $userId: $produitId');
    } catch (e) {
      print('Erreur lors du retrait de la wishlist: $e');
    }
  }

  Future<List<Produit>> listeSouhait(String userId) async {
    try {
      QuerySnapshot snapshot =
          await utilisateursCollection.doc(userId).collection('wishlist').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Produit(
          descriptionCourte: data['descriptionCourte'] ?? '',
          sousCategorie: data['sousCategorie'] ?? '',
          enPromo: data['enPromo'] ?? false,
          cash: data['cash'] ?? false,
          electronique: data['electronique'] ?? false,
          quantite: data['quantite'] ?? '',
          livrable: data['livrable'] ?? true,
          createdAt: data['createdAt'] ?? Timestamp.now(),
          enStock: data['enStock'] ?? true,
          img1: data['img1'] ?? '',
          img2: data['img2'] ?? '',
          img3: data['img3'] ?? '',
          idProduit: doc.id,
          nomProduit: data['nomProduit'] ?? '',
          description: data['description'] ?? '',
          prix: data['prix'] ?? '',
          vues: data['vues']?.toString() ?? '0',
          modele: data['modele'] ?? '',
          marque: data['marque'] ?? '',
          categorie: data['categorie'] ?? '',
          type: data['type'] ?? '',
          jeVeut: true,
          auPanier: false,
        );
      }).toList();
    } catch (e) {
      print('Erreur dans listeSouhait: $e');
      return [];
    }
  }

  Future<void> syncLocalWishlistToFirestore(
    String userId,
    List<Produit> localWishlist,
  ) async {
    try {
      for (var produit in localWishlist) {
        if (produit.jeVeut) {
          await ajoutListeSouhait(userId, produit);
        }
      }
      print('Synchronisation des souhaits locaux vers Firestore terminée');
    } catch (e) {
      print('Erreur lors de la synchronisation des souhaits: $e');
    }
  }

  Future<void> addToCart(String userId, Produit produit) async {
    try {
      await utilisateursCollection
          .doc(userId)
          .collection('cart')
          .doc(produit.idProduit)
          .set({
            'idProduit': produit.idProduit,
            'nomProduit': produit.nomProduit,
            'descriptionCourte': produit.descriptionCourte,
            'img1': produit.img1,
            'img2': produit.img2,
            'img3': produit.img3,
            'prix': produit.prix,
            'categorie': produit.categorie,
            'sousCategorie': produit.sousCategorie,
            'marque': produit.marque,
            'modele': produit.modele,
            'type': produit.type,
            'enStock': produit.enStock,
            'livrable': produit.livrable,
            'quantite': produit.quantite,
            'cash': produit.cash,
            'electronique': produit.electronique,
            'enPromo': produit.enPromo,
            'createdAt': Timestamp.now(),
          });
      // Retirer de la wishlist si présent
      await removeFromWishlist(userId, produit.idProduit);
      print('Produit ajouté au panier de $userId: ${produit.idProduit}');
    } catch (e) {
      print('Erreur lors de l\'ajout au panier: $e');
    }
  }

  Future<void> removeFromCart(String userId, String produitId) async {
    try {
      await utilisateursCollection
          .doc(userId)
          .collection('cart')
          .doc(produitId)
          .delete();
      print('Produit retiré du panier de $userId: $produitId');
    } catch (e) {
      print('Erreur lors du retrait du panier: $e');
    }
  }

  Future<List<Produit>> getCart(String userId) async {
    try {
      QuerySnapshot snapshot =
          await utilisateursCollection.doc(userId).collection('cart').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Produit(
          descriptionCourte: data['descriptionCourte'] ?? '',
          sousCategorie: data['sousCategorie'] ?? '',
          enPromo: data['enPromo'] ?? false,
          cash: data['cash'] ?? false,
          electronique: data['electronique'] ?? false,
          quantite: data['quantite'] ?? '',
          livrable: data['livrable'] ?? true,
          createdAt: data['createdAt'] ?? Timestamp.now(),
          enStock: data['enStock'] ?? true,
          img1: data['img1'] ?? '',
          img2: data['img2'] ?? '',
          img3: data['img3'] ?? '',
          idProduit: doc.id,
          nomProduit: data['nomProduit'] ?? '',
          description: data['description'] ?? '',
          prix: data['prix'] ?? '',
          vues: data['vues']?.toString() ?? '0',
          modele: data['modele'] ?? '',
          marque: data['marque'] ?? '',
          categorie: data['categorie'] ?? '',
          type: data['type'] ?? '',
          jeVeut: false,
          auPanier: true,
        );
      }).toList();
    } catch (e) {
      print('Erreur dans getCart: $e');
      return [];
    }
  }

  Future<void> syncLocalCartToFirestore(
    String userId,
    List<Produit> localCart,
  ) async {
    try {
      for (var produit in localCart) {
        if (produit.auPanier) {
          await addToCart(userId, produit);
        }
      }
      print('Synchronisation du panier local vers Firestore terminée');
    } catch (e) {
      print('Erreur lors de la synchronisation du panier: $e');
    }
  }
}
