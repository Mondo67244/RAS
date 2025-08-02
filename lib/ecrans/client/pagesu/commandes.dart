import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/style.dart';

class Commandes extends StatefulWidget {
  const Commandes({super.key});

  @override
  State<Commandes> createState() => _CommandesState();
}

class _CommandesState extends State<Commandes> {
  Stream<List<Commande>>? _commandesStream;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _initializeCommandesStream();
  }

  void _initializeCommandesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _commandesStream = FirebaseFirestore.instance
          .collection('Commandes')
          .where('utilisateur.idUtilisateur', isEqualTo: user.uid)
          .orderBy('dateCommande', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) {
                  try {
                    return Commande.fromMap(doc.data());
                  } catch (e) {
                    print('Erreur de parsing pour le document ${doc.id}: $e');
                    return Commande(
                      idCommande: doc.id,
                      dateCommande: DateTime.now().toIso8601String(),
                      noteCommande: 'Erreur de chargement',
                      pays: '',
                      rue: '',
                      prixCommande: '0',
                      ville: '',
                      codePostal: '',
                      utilisateur: Utilisateur(
                        idUtilisateur: user.uid,
                        nomUtilisateur: 'N/A',
                        prenomUtilisateur: '',
                        emailUtilisateur: '',
                        numeroUtilisateur: '',
                        villeUtilisateur: '',
                      ),
                      produits: [],
                      methodePaiment: '',
                      choixLivraison: '',
                      numeroPaiement: '',
                      statutPaiement: 'erreur',
                    );
                  }
                }).toList(),
          );
    }
  }

  // Widget pour le "chip" de statut
  Widget _buildStatusChip(String status) {
    Color chipColor;
    String displayText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'payé':
      case 'paye':
        chipColor = Styles.vert;
        displayText = 'Payé';
        icon = Icons.check_circle_outline;
        break;
      case 'erreur':
        chipColor = Styles.erreur;
        displayText = 'Erreur';
        icon = Icons.warning_amber_rounded;
        break;
      case 'en attente':
      default:
        chipColor = Styles.bleu;
        displayText = 'En attente';
        icon = Icons.hourglass_empty_rounded;
    }

    return Chip(
      avatar: Icon(icon, color: Styles.blanc, size: 18),
      label: Text(displayText, style: Styles.textebas.copyWith(fontSize: 12)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mes Commandes', style: Styles.textebas),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
        centerTitle: true,
        elevation: 3.0,
      ),
      body:
          _commandesStream == null
              ? _buildMessageCentral("Veuillez vous connecter.", Icons.login)
              : StreamBuilder<List<Commande>>(
                stream: _commandesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Styles.rouge),
                    );
                  }
                  if (snapshot.hasError) {
                    return _buildMessageCentral(
                      "Une erreur est survenue.",
                      Icons.error_outline,
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildMessageCentral(
                      "Vous n'avez aucune commande.",
                      Icons.receipt_long_outlined,
                    );
                  }

                  final commandes = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    itemCount: commandes.length,
                    itemBuilder: (context, index) {
                      final commande = commandes[index];
                      final date = DateTime.parse(commande.dateCommande);
                      final formattedDate = DateFormat(
                        'dd MMMM yyyy à HH:mm',
                        'fr_FR',
                      ).format(date);

                      final String displayId =
                          commande.idCommande.length >= 6
                              ? commande.idCommande
                                  .substring(0, 6)
                                  .toUpperCase()
                              : commande.idCommande.toUpperCase();

                      return Card(
                        key: ValueKey(commande.idCommande),
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showCommandeDetails(context, commande),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Commande #$displayId',
                                        style: Styles.styleTitre.copyWith(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    _buildStatusChip(commande.statutPaiement),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${commande.produits.length} articles',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${commande.prixCommande} CFA',
                                      style: Styles.stylePrix.copyWith(
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _buildMessageCentral(String message, IconData icon) {
    return Center(
      child: Opacity(
        opacity: 0.7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  // Affiche la boîte de dialogue de confirmation de suppression
  void _showDeleteConfirmationDialog(BuildContext context, Commande commande) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Utiliser un contexte différent pour le dialogue interne
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Confirmer la suppression',
            style: Styles.styleTitre,
          ),
          content: const Text(
            'Voulez-vous vraiment supprimer cette commande ? Cette action est irréversible.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Ferme seulement ce dialogue
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.erreur,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Supprimer', style: Styles.textebas),
              onPressed: () async {
                try {
                  // Supprimer la commande de Firestore
                  await FirebaseFirestore.instance
                      .collection('Commandes')
                      .doc(commande.idCommande)
                      .delete();

                  // Fermer les deux boîtes de dialogue
                  Navigator.of(
                    dialogContext,
                  ).pop(); // Ferme le dialogue de confirmation
                  Navigator.of(context).pop(); // Ferme le dialogue des détails

                  // Afficher un message de succès
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commande supprimée avec succès.'),
                      backgroundColor: Styles.vert,
                    ),
                  );
                } catch (e) {
                  // Afficher un message d'erreur en cas de problème
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Erreur lors de la suppression de la commande.',
                      ),
                      backgroundColor: Styles.erreur,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Placeholder pour la logique de paiement
  void _handlePayment(BuildContext context, Commande commande) {
    // Ferme le dialogue des détails
    Navigator.of(context).pop();

    // Affiche une SnackBar pour simuler le début du paiement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Initialisation du paiement pour la commande #${commande.idCommande.substring(0, 6)}...',
        ),
        backgroundColor: Styles.bleu,
      ),
    );

    // C'est ici que vous appellerez votre API de paiement
    // exemple: paymentApi.initiatePayment(commande.numeroPaiement, commande.prixCommande);
  }

  // Boîte de dialogue des détails, maintenant avec les boutons d'action
  void _showCommandeDetails(BuildContext context, Commande commande) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          // Le titre contient maintenant le bouton supprimer
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Détails', style: Styles.styleTitre),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Styles.erreur),
                onPressed: () {
                  // Appelle le dialogue de confirmation de suppression
                  _showDeleteConfirmationDialog(context, commande);
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Center(child: _buildStatusChip(commande.statutPaiement)),
                const Divider(height: 25),
                const Text('Articles:', style: Styles.styleTitre),
                const SizedBox(height: 5),
                ...commande.produits.map(
                  (p) => ListTile(
                    title: Text(
                      p['nomProduit'] ?? 'Produit inconnu',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Text(
                      '${p['prix'] ?? '0'} CFA x ${p['quantite'] ?? '1'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const Divider(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: Styles.styleTitre),
                    Text(
                      '${commande.prixCommande} CFA',
                      style: Styles.stylePrix.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Les actions contiennent maintenant le bouton "Payer" de manière conditionnelle
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Fermer',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Affiche le bouton "Payer" seulement si le statut est "En attente"
            if (commande.statutPaiement.toLowerCase() == 'en attente')
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.vert,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _handlePayment(context, commande);
                },
                child: const Text('Payer Maintenant', style: Styles.textebas),
              ),
          ],
        );
      },
    );
  }
}
