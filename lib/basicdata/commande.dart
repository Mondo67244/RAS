import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/utilisateur.dart';

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
  final List<Map<String, dynamic>> produits;
  String methodePaiment;
  String choixLivraison;

  Commande({
    required this.methodePaiment,
    required this.prixCommande,
    required this.choixLivraison,
    required this.dateCommande,
    required this.produits,
    required this.idCommande,
    required this.utilisateur,
    required this.noteCommande,
    required this.pays,
    required this.rue,
    required this.ville,
    required this.codePostal,
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
      'produits': produits,
      'methodePaiment': methodePaiment,
      'choixLivraison': choixLivraison,
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
      utilisateur: Utilisateur.fromMap(map['utilisateur'] ?? {}),
      produits: List<Map<String, dynamic>>.from(map['produits'] ?? []),
      methodePaiment: map['methodePaiment'] ?? '',
      choixLivraison: map['choixLivraison'] ?? '',
    );
  }
}