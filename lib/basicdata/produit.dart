import 'package:cloud_firestore/cloud_firestore.dart';
class Produit {
String idProduit;
String nomProduit;
String description;
//le pric du produit lors de son ajout a la base de donnée
String prix;
String vues;
String modele;
String marque;
//liste les Produits en catégories
String categorie;
String type;
//si l'utilisateur choisi liste de souhait alors le produit est envoyé dans la collection listesouhait avec son id
//l'utilisateur pourra ensuite voir tous les Produits qu'il a ajouté a la liste des souhaits
bool jeVeut;
bool auPanier;
String img1;
String img2;
String img3;
//methode de paiement acceptée
bool cash;
bool electronique;
bool enStock;
//la date a laquelle le produit a été ajouté a la base de donnée
Timestamp createdAt;
//la quantité disponible du produit
String quantite;
//la quantité livrable du produit
bool livrable;

Produit({
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
}