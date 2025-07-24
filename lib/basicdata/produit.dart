import 'package:cloud_firestore/cloud_firestore.dart';

class Produit {
  String idProduit;
  String nomProduit;
  String description;
  String descriptionCourte;
  String prix;
  String vues;
  String modele;
  String marque;
  String categorie;
  String type;
  String sousCategorie;
  bool jeVeut;
  bool auPanier;
  String img1;
  String img2;
  String img3;
  bool cash;
  bool electronique;
  bool enStock;
  Timestamp createdAt;
  String quantite;
  bool livrable;
  bool enPromo;

  Produit({
    required this.descriptionCourte,
    required this.sousCategorie,
    required this.enPromo,
    required this.cash,
    required this.electronique,
    required this.quantite,
    required this.livrable,
    required this.createdAt,
    required this.enStock,
    required this.img1,
    required this.img2,
    required this.img3,
    required this.auPanier,
    required this.jeVeut,
    required this.idProduit,
    required this.nomProduit,
    required this.description,
    required this.prix,
    required this.vues,
    required this.modele,
    required this.marque,
    required this.categorie,
    required this.type,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    final idProduit = json['idProduit']?.toString() ?? '';
    if (idProduit.isEmpty) {
      print('Avertissement: idProduit vide dans Produit.fromJson');
    }
    return Produit(
      descriptionCourte: json['descriptionCourte']?.toString() ?? '',
      sousCategorie: json['sousCategorie']?.toString() ?? '',
      enPromo: json['enPromo'] ?? false,
      cash: json['cash'] ?? false,
      electronique: json['electronique'] ?? false,
      quantite: json['quantite']?.toString() ?? '',
      livrable: json['livrable'] ?? true,
      createdAt:
          json['createdAt'] != null
              ? Timestamp.fromMillisecondsSinceEpoch(json['createdAt'] as int)
              : Timestamp.now(),
      enStock: json['enStock'] ?? true,
      img1: json['img1']?.toString() ?? '',
      img2: json['img2']?.toString() ?? '',
      img3: json['img3']?.toString() ?? '',
      auPanier: json['auPanier'] ?? false,
      jeVeut: json['jeVeut'] ?? false,
      idProduit: idProduit,
      nomProduit: json['nomProduit']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      prix: json['prix']?.toString() ?? '',
      vues: json['vues']?.toString() ?? '0',
      modele: json['modele']?.toString() ?? '',
      marque: json['marque']?.toString() ?? '',
      categorie: json['categorie']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  // Dans produit.dart

  factory Produit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Produit(
      idProduit: doc.id,
      nomProduit: data['nomProduit'] ?? '',
      description: data['description'] ?? '',
      prix: data['prix']?.toString() ?? '0', // Lit le prix
      auPanier:
          data['auPanier'] ?? false, // Important : Lit le statut du panier
      quantite:
          data['quantite']?.toString() ?? '1', // Important : Lit la quantité
      // Assurez-vous que les autres champs sont également mappés correctement
      descriptionCourte: data['descriptionCourte'] ?? '',
      sousCategorie: data['sousCategorie'] ?? '',
      enPromo: data['enPromo'] ?? false,
      cash: data['cash'] ?? false,
      electronique: data['electronique'] ?? false,
      livrable: data['livrable'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      enStock: data['enStock'] ?? true,
      img1: data['img1'] ?? '',
      img2: data['img2'] ?? '',
      img3: data['img3'] ?? '',
      jeVeut: data['jeVeut'] ?? false,
      vues: data['vues']?.toString() ?? '0',
      modele: data['modele'] ?? '',
      marque: data['marque'] ?? '',
      type: data['type'] ?? '',
      categorie: data['categorie'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'descriptionCourte': descriptionCourte,
      'sousCategorie': sousCategorie,
      'enPromo': enPromo,
      'cash': cash,
      'electronique': electronique,
      'quantite': quantite,
      'livrable': livrable,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'enStock': enStock,
      'img1': img1,
      'img2': img2,
      'img3': img3,
      'auPanier': auPanier,
      'jeVeut': jeVeut,
      'idProduit': idProduit,
      'nomProduit': nomProduit,
      'description': description,
      'prix': prix,
      'vues': vues,
      'modele': modele,
      'marque': marque,
      'categorie': categorie,
      'type': type,
    };
  }
}
