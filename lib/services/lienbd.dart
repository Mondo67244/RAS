// Fichier : services/lienbd.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ras_app/basicdata/categorie.dart';
import 'package:ras_app/basicdata/utilisateur.dart';
import 'package:ras_app/basicdata/commande.dart';
import 'package:ras_app/basicdata/facture.dart';
import 'package:ras_app/basicdata/produit.dart';

class FirestoreService {
  // Collections references
  final CollectionReference categoriesCollection =
      FirebaseFirestore.instance.collection('Categories');

  final CollectionReference utilisateursCollection =
      FirebaseFirestore.instance.collection('Utilisateurs');

  final CollectionReference produitsCollection =
      FirebaseFirestore.instance.collection('Produits');

  final CollectionReference commandesCollection =
      FirebaseFirestore.instance.collection('Commandes');

  final CollectionReference facturesCollection =
      FirebaseFirestore.instance.collection('Factures');

  final CollectionReference listesSouhaitCollection =
      FirebaseFirestore.instance.collection('listesSouhait');

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

  // =======================================================================
  // Opérations sur les produits
  // =======================================================================

  Future<void> addProduit(Produit produit, bool bool) {
    return produitsCollection.add({
      'enStock': produit.enStock,
      'idProduit': '',
      'nomProduit': produit.nomProduit,
      'description': produit.description,
      'prix': produit.prix,
      'vues': produit.vues,
      'modele': produit.modele,
      'marque': produit.marque,
      'categorie': produit.categorie,
      'type': produit.type,
      'jeVeut': produit.jeVeut,
    });
  }

  Future<void> updateProduit(String id, bool enStock) {
    return produitsCollection.doc(id).update({
      'enStock': enStock,
    });
  }
  
  /// Récupère la liste de tous les produits.
  Future<List<Produit>> getProduits() async {
    QuerySnapshot snapshot = await produitsCollection.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Produit(
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
  }


  
  Future<void> updateProductWishlist(String productId, bool newStatus) {
    return produitsCollection.doc(productId).update({
      'jeVeut': newStatus,
      if (newStatus) 'auPanier': false, // Règle métier : un produit ne peut être aux souhaits et au panier en même temps
    });
  }

  Future<void> updateProductCart(String productId, bool newStatus) {
    return produitsCollection.doc(productId).update({
      'auPanier': newStatus,
      if (newStatus) 'jeVeut': false, 
    });
  }

  // =======================================================================
  // Opérations sur les commandes
  // =======================================================================
  
  // Opérations sur les commandes
  Future<void> addCommande(Commande commande) async {
    // Convert Utilisateur to Map
    Map<String, dynamic> utilisateurMap = {
      'idUtilisateur': commande.utilisateur.idUtilisateur,
      'nomUtilisateur': commande.utilisateur.nomUtilisateur,
      'prenomUtilisateur': commande.utilisateur.prenomUtilisateur,
      'emailUtilisateur': commande.utilisateur.emailUtilisateur,
      'numeroUtilisateur': commande.utilisateur.numeroUtilisateur,
      'villeUtilisateur': commande.utilisateur.villeUtilisateur,
    };

    // Convert List<Produit> to List<Map>
    List<Map<String, dynamic>> produitsMap =
        commande.produit
            .map(
              (produit) => {
                'idProduit': produit.idProduit,
                'nomProduit': produit.nomProduit,
                'description': produit.description,
                'prix': produit.prix,
                'vues': produit.vues,
                'modele': produit.modele,
                'marque': produit.marque,
                'categorie': produit.categorie,
                'type': produit.type,
                'jeVeut': produit.jeVeut,
              },
            )
            .toList();

    return commandesCollection.doc(commande.idCommande).set({
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
  }


   Future<List<Commande>> getCommandes() async {
    QuerySnapshot snapshot = await commandesCollection.get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Convert Map to Utilisateur
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

      // Convert List<Map> to List<Produit>
      List<dynamic> produitsData = data['produit'] as List<dynamic>;
      List<Produit> produits =
          produitsData.map((produitData) {
            return Produit(
              createdAt: data['createdAt'] ?? Timestamp.now(),
              enStock: produitData['enStock'] ?? true,
              img1: produitData['img1'] ?? '',
              img2: produitData['img1'] ?? '',
              img3: produitData['img1'] ?? '',
              auPanier: produitData['auPanier'] ?? false,
              idProduit: produitData['idProduit'] ?? '',
              nomProduit: produitData['nomProduit'] ?? '',
              description: produitData['description'] ?? '',
              prix: produitData['prix'] ?? '',
              vues: produitData['vues'] ?? '',
              modele: produitData['modele'] ?? '',
              marque: produitData['marque'] ?? '',
              categorie: produitData['categorie'] ?? '',
              type: produitData['type'] ?? '',
              jeVeut: produitData['jeVeut'] ?? false,
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
  }


  // =======================================================================
  // Opérations sur les factures
  // =======================================================================

  // Opérations sur les factures
  Future<void> addFacture(Facture facture) async {
    // Convert Utilisateur to Map
    Map<String, dynamic> utilisateurMap = {
      'idUtilisateur': facture.utilisateur.idUtilisateur,
      'nomUtilisateur': facture.utilisateur.nomUtilisateur,
      'prenomUtilisateur': facture.utilisateur.prenomUtilisateur,
      'emailUtilisateur': facture.utilisateur.emailUtilisateur,
      'numeroUtilisateur': facture.utilisateur.numeroUtilisateur,
      'villeUtilisateur': facture.utilisateur.villeUtilisateur,
    };

    // Convert List<Produit> to List<Map>
    List<Map<String, dynamic>> produitsMap =
        facture.Produits.map(
          (produit) => {
            'idProduit': produit.idProduit,
            'nomProduit': produit.nomProduit,
            'description': produit.description,
            'prix': produit.prix,
            'vues': produit.vues,
            'modele': produit.modele,
            'marque': produit.marque,
            'categorie': produit.categorie,
            'type': produit.type,
            'jeVeut': produit.jeVeut,
          },
        ).toList();

    return facturesCollection.doc(facture.idFacture).set({
      'idFacture': facture.idFacture,
      'dateFacture': facture.dateFacture,
      'Utilisateur': utilisateurMap,
      'Produits': produitsMap,
      'prixFacture': facture.prixFacture,
      'quantite': facture.quantite,
    });
  }


  Future<List<Facture>> getFactures() async {
    QuerySnapshot snapshot = await facturesCollection.get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Convert Map to Utilisateur
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

      // Convert List<Map> to List<Produit>
      List<dynamic> produitsData = data['Produits'] as List<dynamic>;
      List<Produit> produits =
          produitsData.map((produitData) {
            return Produit(
              createdAt: data['createdAt'] ?? Timestamp.now(),
              img1: produitData['img1'] ?? '',
              img2: produitData['img1'] ?? '',
              img3: produitData['img1'] ?? '',
              enStock: produitData['enStock'] ?? true,
              auPanier: produitData['auPanier'] ?? false,
              idProduit: produitData['idProduit'] ?? '',
              nomProduit: produitData['nomProduit'] ?? '',
              description: produitData['description'] ?? '',
              prix: produitData['prix'] ?? '',
              vues: produitData['vues'] ?? '',
              modele: produitData['modele'] ?? '',
              marque: produitData['marque'] ?? '',
              categorie: produitData['categorie'] ?? '',
              type: produitData['type'] ?? '',
              jeVeut: produitData['jeVeut'] ?? false,
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
  }



  // Opérations sur la liste de souhaits
  Future<void> ajoutListeSouhait(String userId, Produit produit) {
    return listesSouhaitCollection
        .doc(userId)
        .collection('Produits')
        .doc(produit.idProduit)
        .set({
          'idProduit': produit.idProduit,
          'nomProduit': produit.nomProduit,
          'description': produit.description,
          'prix': produit.prix,
          'vues': produit.vues,
          'modele': produit.modele,
          'marque': produit.marque,
          'categorie': produit.categorie,
          'type': produit.type,
          'jeVeut': true,
          'dateAjout': FieldValue.serverTimestamp(),
        });
  }

  Future<void> removeFromWishlist(String userId, String produitId) {
    return listesSouhaitCollection
        .doc(userId)
        .collection('Produits')
        .doc(produitId)
        .delete();
  }

  Future<List<Produit>> listeSouhait(String userId) async {
    QuerySnapshot snapshot =
        await listesSouhaitCollection.doc(userId).collection('Produits').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Produit(
        createdAt: data['createdAt'] ?? Timestamp.now(),
        enStock: data['enStock'] ?? true,
        img1: data['img1'] ?? '',
        img2: data['img1'] ?? '',
        img3: data['img1'] ?? '',
        auPanier: data['auPanier'] ?? false,
        idProduit: data['idProduit'] ?? '',
        nomProduit: data['nomProduit'] ?? '',
        description: data['description'] ?? '',
        prix: data['prix'] ?? '',
        vues: data['vues'] ?? '',
        modele: data['modele'] ?? '',
        marque: data['marque'] ?? '',
        categorie: data['categorie'] ?? '',
        type: data['type'] ?? '',
        jeVeut: data['jeVeut'] ?? true,
      );
    }).toList();
  }
}