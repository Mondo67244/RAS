import 'package:ras_app/basicdata/utilisateur.dart';
import 'package:ras_app/basicdata/produit.dart';

class Commande {
  String idCommande;
  String dateCommande;
  String noteCommande;
  String pays;
  String rue;
  String prixCommande;
  String ville;
  String codePostal;
  final Utilisateur utilisateur;
  final List<Produit> produit;
  bool methodePaiment;
  bool choixLivraison;
  bool enPromo;
  bool enSouhait;
  bool auPanier;
  Commande({
    required this.enSouhait,
    required this.auPanier,
    required this.methodePaiment,
    required this.enPromo,
    required this.prixCommande,
    required this.choixLivraison,
    required this.dateCommande,
    required this.produit,
    required this.idCommande,
    required this.utilisateur,
    required this.noteCommande,
    required this.pays,
    required this.rue,
    required this.ville,
    required this.codePostal
  });
}