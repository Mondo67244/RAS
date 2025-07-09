import 'package:ras_app/basicdata/utilisateur.dart';
import 'package:ras_app/basicdata/produit.dart';

class Facture {
  String idFacture;
  String dateFacture;
  final Utilisateur utilisateur;
  final List<Produit> Produits;
  int prixFacture;
  int quantite;
  Facture({
    required this.quantite,
    required this.prixFacture,
    required this.idFacture,
    required this.dateFacture,
    required this.utilisateur,
    required this.Produits,
  });
}