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
  String methodeLivraison;

  Produit({
    required this.idProduit,
    required this.nomProduit,
    required this.description,
    required this.descriptionCourte,
    required this.prix,
    required this.vues,
    required this.modele,
    required this.marque,
    required this.categorie,
    required this.type,
    required this.sousCategorie,
    required this.jeVeut,
    required this.auPanier,
    required this.img1,
    required this.img2,
    required this.img3,
    required this.cash,
    required this.electronique,
    required this.enStock,
    required this.createdAt,
    required this.quantite,
    required this.livrable,
    required this.enPromo,
    required this.methodeLivraison,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomProduit': nomProduit,
      'description': description,
      'descriptionCourte': descriptionCourte,
      'prix': prix,
      'vues': vues,
      'modele': modele,
      'marque': marque,
      'categorie': categorie,
      'type': type,
      'sousCategorie': sousCategorie,
      'jeVeut': jeVeut,
      'auPanier': auPanier,
      'img1': img1,
      'img2': img2,
      'img3': img3,
      'cash': cash,
      'electronique': electronique,
      'enStock': enStock,
      'createdAt': createdAt,
      'quantite': quantite,
      'livrable': livrable,
      'enPromo': enPromo,
      'methodeLivraison': methodeLivraison,
    };
  }

  factory Produit.fromMap(Map<String, dynamic> map, String id) {
    return Produit(
      idProduit: id,
      nomProduit: map['nomProduit'] ?? '',
      description: map['description'] ?? '',
      descriptionCourte: map['descriptionCourte'] ?? '',
      prix: map['prix'] ?? '',
      vues: map['vues']?.toString() ?? '0',
      modele: map['modele'] ?? '',
      marque: map['marque'] ?? '',
      categorie: map['categorie'] ?? '',
      type: map['type'] ?? '',
      sousCategorie: map['sousCategorie'] ?? '',
      jeVeut: map['jeVeut'] ?? false,
      auPanier: map['auPanier'] ?? false,
      img1: map['img1'] ?? '',
      img2: map['img2'] ?? '',
      img3: map['img3'] ?? '',
      cash: map['cash'] ?? false,
      electronique: map['electronique'] ?? false,
      enStock: map['enStock'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      quantite: map['quantite'] ?? '',
      livrable: map['livrable'] ?? true,
      enPromo: map['enPromo'] ?? false,
      methodeLivraison: map['methodeLivraison'] ?? '',
    );
  }

  factory Produit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return Produit(
      idProduit: snapshot.id,
      nomProduit: data['nomProduit'] ?? '',
      description: data['description'] ?? '',
      descriptionCourte: data['descriptionCourte'] ?? '',
      prix: data['prix']?.toString() ?? '',
      vues: data['vues']?.toString() ?? '0',
      modele: data['modele'] ?? '',
      marque: data['marque'] ?? '',
      categorie: data['categorie'] ?? '',
      type: data['type'] ?? '',
      sousCategorie: data['sousCategorie'] ?? '',
      jeVeut: data['jeVeut'] ?? false,
      auPanier: data['auPanier'] ?? false,
      img1: data['img1'] ?? '',
      img2: data['img2'] ?? '',
      img3: data['img3'] ?? '',
      cash: data['cash'] ?? false,
      electronique: data['electronique'] ?? false,
      enStock: data['enStock'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      quantite: data['quantite'] ?? '',
      livrable: data['livrable'] ?? true,
      enPromo: data['enPromo'] ?? false,
      methodeLivraison: data['methodeLivraison'] ?? '',
    );
  }

  Produit copyWith({
    String? idProduit,
    String? nomProduit,
    String? description,
    String? descriptionCourte,
    String? prix,
    String? vues,
    String? modele,
    String? marque,
    String? categorie,
    String? type,
    String? sousCategorie,
    bool? jeVeut,
    bool? auPanier,
    String? img1,
    String? img2,
    String? img3,
    bool? cash,
    bool? electronique,
    bool? enStock,
    Timestamp? createdAt,
    String? quantite,
    bool? livrable,
    bool? enPromo,
    String? methodeLivraison,
  }) {
    return Produit(
      idProduit: idProduit ?? this.idProduit,
      nomProduit: nomProduit ?? this.nomProduit,
      description: description ?? this.description,
      descriptionCourte: descriptionCourte ?? this.descriptionCourte,
      prix: prix ?? this.prix,
      vues: vues ?? this.vues,
      modele: modele ?? this.modele,
      marque: marque ?? this.marque,
      categorie: categorie ?? this.categorie,
      type: type ?? this.type,
      sousCategorie: sousCategorie ?? this.sousCategorie,
      jeVeut: jeVeut ?? this.jeVeut,
      auPanier: auPanier ?? this.auPanier,
      img1: img1 ?? this.img1,
      img2: img2 ?? this.img2,
      img3: img3 ?? this.img3,
      cash: cash ?? this.cash,
      electronique: electronique ?? this.electronique,
      enStock: enStock ?? this.enStock,
      createdAt: createdAt ?? this.createdAt,
      quantite: quantite ?? this.quantite,
      livrable: livrable ?? this.livrable,
      enPromo: enPromo ?? this.enPromo,
      methodeLivraison: methodeLivraison ?? this.methodeLivraison,
    );
  }
}
