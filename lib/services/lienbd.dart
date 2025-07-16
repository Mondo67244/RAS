import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ras_app/basicdata/categorie.dart';
import 'package:ras_app/basicdata/utilisateur.dart';
import 'package:ras_app/basicdata/commande.dart';
import 'package:ras_app/basicdata/facture.dart';
import 'package:ras_app/basicdata/produit.dart';

class FirestoreService {
  // Collections references
  final CollectionReference categoriesCollection = FirebaseFirestore.instance.collection('Categories');
  final CollectionReference utilisateursCollection = FirebaseFirestore.instance.collection('Utilisateurs');
  final CollectionReference produitsCollection = FirebaseFirestore.instance.collection('Produits');
  final CollectionReference commandesCollection = FirebaseFirestore.instance.collection('Commandes');
  final CollectionReference facturesCollection = FirebaseFirestore.instance.collection('Factures');

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
  // Opérations pour les produits
  // =======================================================================

  Future<List<Produit>> getProduits() async {
    QuerySnapshot snapshot = await produitsCollection.orderBy('createdAt', descending: true).get();
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
  }

  Future<void> updateProductWishlist(String productId, bool newStatus) {
    return produitsCollection.doc(productId).update({
      'jeVeut': newStatus,
      if (newStatus) 'auPanier': false, // Un produit ne peut être aux souhaits et au panier en même temps
    });
  }

  Future<void> updateProductCart(String productId, bool newStatus) {
    return produitsCollection.doc(productId).update({
      'auPanier': newStatus,
      if (newStatus) 'jeVeut': false, // Retirer des souhaits si ajouté au panier
    });
  }

  // =======================================================================
  // Opérations sur les commandes
  // =======================================================================

  Future<void> addCommande(Commande commande) async {
    Map<String, dynamic> utilisateurMap = {
      'idUtilisateur': commande.utilisateur.idUtilisateur,
      'nomUtilisateur': commande.utilisateur.nomUtilisateur,
      'prenomUtilisateur': commande.utilisateur.prenomUtilisateur,
      'emailUtilisateur': commande.utilisateur.emailUtilisateur,
      'numeroUtilisateur': commande.utilisateur.numeroUtilisateur,
      'villeUtilisateur': commande.utilisateur.villeUtilisateur,
    };

    List<Map<String, dynamic>> produitsMap = commande.produit.map((produit) => {
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
        }).toList();

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

      Map<String, dynamic> utilisateurData = data['Utilisateur'] as Map<String, dynamic>;
      Utilisateur utilisateur = Utilisateur(
        idUtilisateur: utilisateurData['idUtilisateur'] ?? '',
        nomUtilisateur: utilisateurData['nomUtilisateur'] ?? '',
        prenomUtilisateur: utilisateurData['prenomUtilisateur'] ?? '',
        emailUtilisateur: utilisateurData['emailUtilisateur'] ?? '',
        numeroUtilisateur: utilisateurData['numeroUtilisateur'] ?? 0,
        villeUtilisateur: utilisateurData['villeUtilisateur'] ?? '',
      );

      List<dynamic> produitsData = data['produit'] as List<dynamic>;
      List<Produit> produits = produitsData.map((produitData) {
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
  }

  // =======================================================================
  // Opérations sur les factures
  // =======================================================================

  Future<void> addFacture(Facture facture) async {
    Map<String, dynamic> utilisateurMap = {
      'idUtilisateur': facture.utilisateur.idUtilisateur,
      'nomUtilisateur': facture.utilisateur.nomUtilisateur,
      'prenomUtilisateur': facture.utilisateur.prenomUtilisateur,
      'emailUtilisateur': facture.utilisateur.emailUtilisateur,
      'numeroUtilisateur': facture.utilisateur.numeroUtilisateur,
      'villeUtilisateur': facture.utilisateur.villeUtilisateur,
    };

    List<Map<String, dynamic>> produitsMap = facture.Produits.map((produit) => {
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
        }).toList();

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

      Map<String, dynamic> utilisateurData = data['Utilisateur'] as Map<String, dynamic>;
      Utilisateur utilisateur = Utilisateur(
        idUtilisateur: utilisateurData['idUtilisateur'] ?? '',
        nomUtilisateur: utilisateurData['nomUtilisateur'] ?? '',
        prenomUtilisateur: utilisateurData['prenomUtilisateur'] ?? '',
        emailUtilisateur: utilisateurData['emailUtilisateur'] ?? '',
        numeroUtilisateur: utilisateurData['numeroUtilisateur'] ?? 0,
        villeUtilisateur: utilisateurData['villeUtilisateur'] ?? '',
      );

      List<dynamic> produitsData = data['Produits'] as List<dynamic>;
      List<Produit> produits = produitsData.map((produitData) {
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
  }

  // =======================================================================
  // Opérations sur la liste de souhaits
  // =======================================================================

  Future<void> ajoutListeSouhait(String userId, Produit produit) async {
    await produitsCollection.doc(produit.idProduit).update({
      'jeVeut': true,
      'auPanier': false, // Un produit ne peut être aux souhaits et au panier en même temps
    });
  }

  Future<void> removeFromWishlist(String userId, String produitId) async {
    await produitsCollection.doc(produitId).update({
      'jeVeut': false,
    });
  }

  Future<List<Produit>> listeSouhait(String userId) async {
    QuerySnapshot snapshot = await produitsCollection.where('jeVeut', isEqualTo: true).get();
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
        jeVeut: data['jeVeut'] ?? true,
        auPanier: data['auPanier'] ?? false,
      );
    }).toList();
  }

  Future<void> syncLocalWishlistToFirestore(String userId, List<Produit> localWishlist) async {
    for (var produit in localWishlist) {
      if (produit.jeVeut) {
        await ajoutListeSouhait(userId, produit);
      }
    }
  }

  // =======================================================================
  // Opérations sur le panier
  // =======================================================================

  Future<void> addToCart(String userId, Produit produit) async {
    await produitsCollection.doc(produit.idProduit).update({
      'auPanier': true,
      'jeVeut': false, // Retirer des souhaits si ajouté au panier
    });
  }

  Future<void> removeFromCart(String userId, String produitId) async {
    await produitsCollection.doc(produitId).update({
      'auPanier': false,
    });
  }

  Future<List<Produit>> getCart(String userId) async {
    QuerySnapshot snapshot = await produitsCollection.where('auPanier', isEqualTo: true).get();
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
        jeVeut: data['jeVeut'] ?? false,
        auPanier: data['auPanier'] ?? true,
      );
    }).toList();
  }

  Future<void> syncLocalCartToFirestore(String userId, List<Produit> localCart) async {
    for (var produit in localCart) {
      if (produit.auPanier) {
        await addToCart(userId, produit);
      }
    }
  }
}