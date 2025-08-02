import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/produit.dart';

class Facture {
  String idFacture;
  String dateFacture;
  final Utilisateur utilisateur;
  final List<Produit> produits;
  int prixFacture;
  int quantite;
  Facture({
    required this.quantite,
    required this.prixFacture,
    required this.idFacture,
    required this.dateFacture,
    required this.utilisateur,
    required this.produits,
  });

  Map<String, dynamic> toMap() {
    return {
      'idFacture': idFacture,
      'dateFacture': dateFacture,
      'utilisateur': utilisateur.toMap(),
      'produits': produits.map((p) => p.toMap()).toList(),
      'prixFacture': prixFacture,
      'quantite': quantite,
    };
  }

  factory Facture.fromMap(Map<String, dynamic> map) {
    return Facture(
      idFacture: map['idFacture'] ?? '',
      dateFacture: map['dateFacture'] ?? '',
      utilisateur: Utilisateur.fromMap(map['utilisateur']),
      produits: (map['produits'] as List).map((p) => Produit.fromMap(p as Map<String, dynamic>, p['idProduit'])).toList(),
      prixFacture: map['prixFacture'] ?? 0,
      quantite: map['quantite'] ?? 0,
    );
  }
}
