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

  Map<String, dynamic> toMap() {
    return {
      'idCommande': idCommande,
      'dateCommande': dateCommande,
      'noteCommande': noteCommande,
      'pays': pays,
      'rue': rue,
      'prixCommande': prixCommande,
      'ville': ville,
      'codePostal': codePostal,
      'utilisateur': utilisateur.toMap(),
      'produit': produit.map((p) => p.toMap()).toList(),
      'methodePaiment': methodePaiment,
      'choixLivraison': choixLivraison,
      'enPromo': enPromo,
      'enSouhait': enSouhait,
      'auPanier': auPanier,
    };
  }

  factory Commande.fromMap(Map<String, dynamic> map) {
    return Commande(
      idCommande: map['idCommande'] ?? '',
      dateCommande: map['dateCommande'] ?? '',
      noteCommande: map['noteCommande'] ?? '',
      pays: map['pays'] ?? '',
      rue: map['rue'] ?? '',
      prixCommande: map['prixCommande'] ?? '',
      ville: map['ville'] ?? '',
      codePostal: map['codePostal'] ?? '',
      utilisateur: Utilisateur.fromMap(map['utilisateur']),
      produit: (map['produit'] as List).map((p) => Produit.fromMap(p as Map<String, dynamic>, p['idProduit'])).toList(),
      methodePaiment: map['methodePaiment'] ?? false,
      choixLivraison: map['choixLivraison'] ?? false,
      enPromo: map['enPromo'] ?? false,
      enSouhait: map['enSouhait'] ?? false,
      auPanier: map['auPanier'] ?? false,
    );
  }
}
