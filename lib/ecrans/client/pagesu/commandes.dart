// commandes.dart

import 'package:RAS/ecrans/client/pagesu/payment_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
    _chargementCommandes();
  }

  void _chargementCommandes() {
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

  Widget _statut(String status) {
    Color chipColor;
    String displayText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'payé':
      case 'paye':
        chipColor = Colors.green;
        displayText = 'Payé';
        icon = FluentIcons.checkmark_circle_24_filled;
        break;
      case 'erreur':
        chipColor = Colors.red;
        displayText = 'Erreur';
        icon = FluentIcons.error_circle_24_filled;
        break;
      case 'en attente':
      default:
        chipColor = Colors.orange;
        displayText = 'En attente';
        icon = FluentIcons.clock_24_filled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vide(String message, IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chargement() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            SizedBox(height: 20),
            Text(
              'Chargement des commandes...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteCommande(Commande commande) {
    final date = DateTime.parse(commande.dateCommande);
    final formattedDate = DateFormat(
      'dd MMMM yyyy à HH:mm',
      'fr_FR',
    ).format(date);
    final String displayId =
        commande.idCommande.length >= 5
            ? commande.idCommande.substring(0, 5).toUpperCase()
            : commande.idCommande.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _details(context, commande),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Styles.rouge.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                FluentIcons.receipt_bag_24_filled,
                                color: Styles.rouge,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Commande #$displayId',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statut(commande.statutPaiement),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        FluentIcons.shopping_bag_24_filled,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${commande.produits.length} articles',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${commande.prixCommande} CFA',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        backgroundColor: Styles.rouge,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Styles.rouge, Colors.red.shade700],
          ),
        ),
        child:
            _commandesStream == null
                ? _vide(
                  "Veuillez vous connecter pour voir vos commandes.",
                  FluentIcons.person_24_filled,
                )
                : StreamBuilder<List<Commande>>(
                  stream: _commandesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _chargement();
                    }
                    if (snapshot.hasError) {
                      return _vide(
                        "Une erreur est survenue.",
                        FluentIcons.error_circle_24_filled,
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _vide(
                        "Vous n'avez aucune commande.",
                        FluentIcons.receipt_bag_24_filled,
                      );
                    }

                    final commandes = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: commandes.length,
                      itemBuilder: (context, index) {
                        return _carteCommande(commandes[index]);
                      },
                    );
                  },
                ),
      ),
    );
  }

  void _suppression(BuildContext context, Commande commande) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône d'avertissement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FluentIcons.warning_24_filled,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),

                // Titre
                const Text(
                  'Confirmer la suppression',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  'Voulez-vous vraiment supprimer cette commande ?\nCette action est irréversible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('Commandes')
                                .doc(commande.idCommande)
                                .delete();
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Commande supprimée.'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Erreur lors de la suppression.',
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _paiement(BuildContext context, Commande commande) async {
    // Ferme le dialogue des détails de la commande
    Navigator.of(context).pop();

    // Navigue vers la page de paiement et attend un résultat
    final paymentResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentPage(commande: commande)),
    );

    // Affiche un message en fonction du résultat du paiement
    if (paymentResult == 'ACCEPTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement effectué avec succès !'),
          backgroundColor: Styles.vert,
        ),
      );
    } else if (paymentResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le paiement a échoué ou a été annulé.'),
          backgroundColor: Styles.erreur,
        ),
      );
    }
  }

  void _details(BuildContext context, Commande commande) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête avec gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Styles.rouge, Colors.red.shade700],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //Row du titre et de l'id de la commande
                            Row(
                              children: [
                                Icon(
                                  FluentIcons.receipt_bag_24_filled,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Détails de la commande',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Commande #${commande.idCommande.substring(0, 5).toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _statut(commande.statutPaiement),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      //Row du bouton de suppression et du statut de la commande
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(
                              FluentIcons.delete_24_filled,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _suppression(dialogContext, commande);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Contenu
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informations de la commande
                        _section('Informations', [
                          _ligne(
                            'Date',
                            DateFormat(
                              'dd MMMM yyyy à HH:mm',
                              'fr_FR',
                            ).format(DateTime.parse(commande.dateCommande)),
                          ),
                          _ligne(
                            'Méthode de paiement',
                            commande.methodePaiment,
                          ),
                          _ligne('Livraison', commande.choixLivraison),
                          if (commande.numeroPaiement.isNotEmpty)
                            _ligne(
                              'Numéro de paiement',
                              commande.numeroPaiement,
                            ),
                        ]),

                        const SizedBox(height: 20),

                        // Articles
                        _section(
                          'Articles (${commande.produits.length})',
                          commande.produits.map((produit) {
                            return _ligneProduit(
                              produit['nomProduit'] ?? 'Produit inconnu',
                              produit['prix'] ?? '0',
                              produit['quantite'] ?? 1,
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Total
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '${commande.prixCommande} CFA',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Fermer',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (commande.statutPaiement.toLowerCase() ==
                          'en attente') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _paiement(dialogContext, commande),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Payer maintenant',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _ligne(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _ligneProduit(String name, String price, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$price CFA x $quantity',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
