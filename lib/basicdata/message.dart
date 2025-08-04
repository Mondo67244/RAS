import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String idMessage;
  String contenuMessage;
  String idExpediteur; // ID de l'utilisateur qui envoie le message
  String idDestinataire; // ID de l'utilisateur qui reçoit le message
  String idProduit; // ID du produit concerné (si applicable)
  String idConversation; // ID de la conversation
  Timestamp timestamp;
  bool lu; // Indique si le message a été lu

  Message({
    required this.idMessage,
    required this.contenuMessage,
    required this.idExpediteur,
    required this.idDestinataire,
    required this.idProduit,
    required this.idConversation,
    required this.timestamp,
    this.lu = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'idMessage': idMessage,
      'contenuMessage': contenuMessage,
      'idExpediteur': idExpediteur,
      'idDestinataire': idDestinataire,
      'idProduit': idProduit,
      'idConversation': idConversation,
      'timestamp': timestamp,
      'lu': lu,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      idMessage: id,
      contenuMessage: map['contenuMessage'] ?? '',
      idExpediteur: map['idExpediteur'] ?? '',
      idDestinataire: map['idDestinataire'] ?? '',
      idProduit: map['idProduit'] ?? '',
      idConversation: map['idConversation'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      lu: map['lu'] ?? false,
    );
  }

}