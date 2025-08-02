class Utilisateur {
  String idUtilisateur;
  String nomUtilisateur;
  String prenomUtilisateur;
  String emailUtilisateur;
  String numeroUtilisateur;
  String villeUtilisateur;
  
  Utilisateur({
    required this.idUtilisateur,
    required this.nomUtilisateur,
    required this.prenomUtilisateur,
    required this.emailUtilisateur,
    required this.numeroUtilisateur,
    required this.villeUtilisateur,
  });

  Map<String, dynamic> toMap() {
    return {
      'idUtilisateur': idUtilisateur,
      'nomUtilisateur': nomUtilisateur,
      'prenomUtilisateur': prenomUtilisateur,
      'emailUtilisateur': emailUtilisateur,
      'numeroUtilisateur': numeroUtilisateur,
      'villeUtilisateur': villeUtilisateur,
    };
  }

  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      idUtilisateur: map['idUtilisateur'] ?? '',
      nomUtilisateur: map['nomUtilisateur'] ?? '',
      prenomUtilisateur: map['prenomUtilisateur'] ?? '',
      emailUtilisateur: map['emailUtilisateur'] ?? '',
      numeroUtilisateur: map['numeroUtilisateur'] ?? '',
      villeUtilisateur: map['villeUtilisateur'] ?? '',
    );
  }


}
