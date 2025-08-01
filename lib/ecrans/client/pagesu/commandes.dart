import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ras_app/basicdata/commande.dart';
import 'package:ras_app/basicdata/style.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Initialisation du stream des commandes pour l\'utilisateur: ${user.uid}');
      _commandesStream = FirebaseFirestore.instance
          .collection('Commandes')
          .where('utilisateur.idUtilisateur', isEqualTo: user.uid)
          .orderBy('dateCommande', descending: true)
          .snapshots()
          .map((snapshot) {
            print('Récupération de ${snapshot.docs.length} commandes');
            return snapshot.docs.map((doc) {
              try {
                return Commande.fromMap(doc.data());
              } catch (e, stackTrace) {
                print('Erreur lors de la conversion du document ${doc.id}: $e\n$stackTrace');
                rethrow;
              }
            }).toList();
          });
    } else {
      print('Aucun utilisateur connecté pour récupérer les commandes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
      ),
      body: _commandesStream == null
          ? const Center(child: Text('Veuillez vous connecter pour voir vos commandes.'))
          : StreamBuilder<List<Commande>>(
              stream: _commandesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Erreur dans StreamBuilder: ${snapshot.error}');
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucune commande trouvée.'));
                }

                final commandes = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: commandes.length,
                  itemBuilder: (context, index) {
                    final commande = commandes[index];
                    final date = DateTime.parse(commande.dateCommande);
                    final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(date);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: ListTile(
                        title: Text('Commande du $formattedDate'),
                        subtitle: Text('${commande.produits.length} articles'),
                        trailing: Text('${commande.prixCommande} CFA', style: Styles.stylePrix),
                        onTap: () => _showCommandeDetails(context, commande),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showCommandeDetails(BuildContext context, Commande commande) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Détails de la commande'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(commande.dateCommande))}'),
                Text('Total: ${commande.prixCommande} CFA'),
                const SizedBox(height: 16),
                const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...commande.produits.map((p) => ListTile(
                      title: Text(p['nomProduit'] ?? 'Produit inconnu'),
                      trailing: Text('${p['prix'] ?? '0'} CFA x ${p['quantite'] ?? '1'}'),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}