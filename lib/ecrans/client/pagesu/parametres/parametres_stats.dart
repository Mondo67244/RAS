import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:RAS/basicdata/style.dart';

class ParametresStatsPage extends StatelessWidget {
  const ParametresStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Styles.blanc,
        appBar: AppBar(
          title: const Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Styles.rouge,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        body: const Center(child: Text('Veuillez vous connecter.')),
      );
    }

    final stream =
        FirebaseFirestore.instance
            .collection('Commandes')
            .where('utilisateur.idUtilisateur', isEqualTo: user.uid)
            .where('statutPaiement', isEqualTo: 'Payé')
            .snapshots();

    return Scaffold(
      backgroundColor: Styles.blanc,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/kanjad.png',
              key: const ValueKey('logo'),
              width: 140,
              height: 50,
            ),
            Transform.translate(
              offset: const Offset(-20, 12),
              child: const Text(
                'Statistiques',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          int totalArticles = 0;
          double totalDepenses = 0;
          final Map<String, int> parTypes = {};
          final List<Map<String, dynamic>> historique = [];
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final List produits = data['produits'] ?? [];
            for (final p in produits) {
              final int q =
                  (p['quantite'] is int)
                      ? p['quantite']
                      : int.tryParse('${p['quantite']}') ?? 0;
              final double prix = double.tryParse('${p['prix']}') ?? 0;
              totalArticles += q;
              totalDepenses += q * prix;
              final type = (p['type'] ?? 'Inconnu').toString();
              parTypes[type] = (parTypes[type] ?? 0) + q;
            }
            historique.add({
              'date': data['dateCommande'] ?? '',
              'montant': data['prixCommande'] ?? '0',
            });
          }

          return Center(
            child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600 ? 700 : 500,
          ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row with total expenses and number of articles
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dépense totale',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${NumberFormat('#,##0', 'fr_FR').format(totalDepenses)} CFA',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Articles achetés',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$totalArticles',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Répartition par type',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...parTypes.entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.label_outline,
                                          color: Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          e.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${e.value}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Historique des transactions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...historique.map((h) {
                              String date = h['date'];
                              try {
                                final d = DateTime.parse(date);
                                date = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(d);
                              } catch (_) {}
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          color: Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${h['montant']} CFA',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}