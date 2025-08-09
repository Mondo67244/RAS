import 'package:flutter/material.dart';
import 'package:RAS/basicdata/facture.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:RAS/services/synchronisation/facture_pdf_service.dart';

class VoirFacture extends StatelessWidget {
  final Facture facture;

  const VoirFacture({super.key, required this.facture});

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final dateFacture = DateTime.parse(facture.dateFacture);
    final date = dateFormat.format(dateFacture);
    final idFact = facture.idFacture;
    return Scaffold(
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
                'Facturation',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Imprimer',
            icon: const Icon(Icons.print),
            onPressed: () async {
              final bytes = await FacturePdfService.generateFacturePdf(facture);
              await Printing.layoutPdf(onLayout: (format) async => bytes);
            },
          ),
          IconButton(
            tooltip: 'Télécharger',
            icon: const Icon(Icons.download),
            onPressed: () async {
              final bytes = await FacturePdfService.generateFacturePdf(facture);
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'Facture_${facture.idFacture}.pdf',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: isWideScreen ? BoxConstraints(maxWidth: 600) : BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                // Header with logo
                Container(
                  padding: EdgeInsets.all(8),
                  color: Styles.rouge,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Royal Advanced Services',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Styles.blanc,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            idFact,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Styles.blanc,
                            ),
                          ),
                          Text(
                            'Du $date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Styles.blanc,
                            ),
                          ),
                        ],
                      ),
                      Image.asset('assets/images/kanjad.png', height: 60),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(thickness: 1),
                const SizedBox(height: 20),
            
                // Client information
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations du client: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${facture.utilisateur.prenomUtilisateur} ${facture.utilisateur.nomUtilisateur}',
                          ),
                          Text(facture.utilisateur.emailUtilisateur),
                          Text(facture.utilisateur.numeroUtilisateur),
                          Text(facture.utilisateur.villeUtilisateur),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
            
                // Products table
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        color: Colors.grey[300],
                        padding: const EdgeInsets.all(8.0),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Produit',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Qté',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Prix',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
            
                      // Product list
                      ...facture.produits.map((produit) {
                        final quantite = int.parse(produit.quantite);
                        final prix = double.parse(produit.prix);
                        final total = quantite * prix;
            
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey)),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(produit.nomProduit)),
                              Expanded(
                                child: Text(
                                  quantite.toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${prix.toStringAsFixed(0)} CFA',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${total.toStringAsFixed(0)} CFA',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
            
                      // Total
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Total: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${facture.prixFacture} CFA',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            
                const SizedBox(height: 20),
            
                // Footer
                const Text(
                  'Merci d\'avoir choisi Kanjad pour vos achats!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
