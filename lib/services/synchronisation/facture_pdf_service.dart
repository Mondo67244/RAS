import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:RAS/basicdata/facture.dart';

class FacturePdfService {
  static Future<Uint8List> generateFacturePdf(Facture facture) async {
    final pw.Document document = pw.Document();

    // Logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/kanjad.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final date = DateTime.tryParse(facture.dateFacture) ?? DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);

    // Helpers
    String formatPrice(num value) => '${value.toStringAsFixed(0)} CFA';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.red600,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Royal Advanced Services',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        facture.idFacture,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Du $dateStr',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(
                      height: 48,
                      width: 140,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Image(logoImage, height: 48),
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),

            // Client info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Informations du client: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${facture.utilisateur.prenomUtilisateur} ${facture.utilisateur.nomUtilisateur}',
                      ),
                      if (facture.utilisateur.emailUtilisateur.isNotEmpty)
                        pw.Text(facture.utilisateur.emailUtilisateur),
                      if (facture.utilisateur.numeroUtilisateur.isNotEmpty)
                        pw.Text(facture.utilisateur.numeroUtilisateur),
                      if (facture.utilisateur.villeUtilisateur.isNotEmpty)
                        pw.Text(facture.utilisateur.villeUtilisateur),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Products table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Produit',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Qté',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Prix',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...facture.produits.map((p) {
                  final int qty = int.tryParse(p.quantite) ?? 0;
                  final double price = double.tryParse(p.prix) ?? 0;
                  final double total = qty * price;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(p.nomProduit),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$qty', textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          formatPrice(price),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          formatPrice(total),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 8),

            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  formatPrice(facture.prixFacture),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Center(
              child: pw.Text(
                "Merci d'avoir choisi Kanjad pour vos achats!",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ];
        },
      ),
    );

    return document.save();
  }
}
