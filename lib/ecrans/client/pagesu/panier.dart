import 'package:flutter/material.dart';
import 'package:ras_app/services/base%20de%20donn%C3%A9es/lienbd.dart'; // Assurez-vous que ce service existe et est correct
import 'package:ras_app/basicdata/produit.dart'; // Votre classe Produit
// import 'package:ras_app/basicdata/style.dart'; // Vous pouvez décommenter si vous utilisez ce fichier
import 'dart:async';
import 'package:intl/intl.dart'; // Pour le formatage des nombres

class Panier extends StatefulWidget {
  const Panier({Key? key}) : super(key: key);

  @override
  State<Panier> createState() => PanierState();
}

class PanierState extends State<Panier> {
  late Stream<List<Produit>> _cartProductsStream;
  final FirestoreService _firestoreService = FirestoreService();

  // Variables d'état pour gérer les sélections de l'utilisateur
  String? _selectedPaymentMethod;
  String? _selectedDeliveryMethod;
  bool _confirmTerms = false;
  final TextEditingController _paymentNumberController =
      TextEditingController();

  // Map pour gérer localement les quantités
  Map<String, int> _productQuantities = {};

  @override
  void initState() {
    super.initState();
    _cartProductsStream = _firestoreService.getProduitsStream();

    _cartProductsStream.listen((products) {
      if (!mounted) return;
      setState(() {
        _productQuantities = {
          for (var p in products.where((p) => p.auPanier))
            p.idProduit: int.tryParse(p.quantite) ?? 1,
        };
      });
    });
  }

  void _updateQuantity(String productId, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _productQuantities[productId] = newQuantity;
      });
      // Optionnel : Mettre à jour dans Firestore pour la persistance
      // _firestoreService.updateProductQuantity(productId, newQuantity);
    } else {
      _removeFromCart(productId);
    }
  }

  Future<void> _removeFromCart(String idProduit) async {
    try {
      await _firestoreService.updateProductCart(idProduit, false);
      setState(() {
        _productQuantities.remove(idProduit);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression du produit: $e')),
      );
    }
  }

  String _formatPrice(double price) {
    final format = NumberFormat("#,##0", "fr_FR");
    return "${format.format(price)} CFA";
  }

  @override
  void dispose() {
    _paymentNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Produit>>(
        stream: _cartProductsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur de chargement du panier : ${snapshot.error}'),
            );
          }

          final produitsPanier =
              snapshot.data?.where((p) => p.auPanier).toList() ?? [];

          if (produitsPanier.isEmpty) {
            return const Center(child: Text('Votre panier est vide.'));
          }

          double grandTotal = 0;
          for (var produit in produitsPanier) {
            double prix = double.tryParse(produit.prix) ?? 0.0;
            int currentQuantity =
                _productQuantities[produit.idProduit] ??
                (int.tryParse(produit.quantite) ?? 1);
            grandTotal += prix * currentQuantity;
          }

          // LayoutBuilder est idéal pour construire une UI responsive
          return LayoutBuilder(
            builder: (context, constraints) {
              // On définit un point de rupture : 800 pixels
              // En dessous, tout est en colonne. Au-dessus, en 2 colonnes.
              if (constraints.maxWidth < 700) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCartDetailsColumn(produitsPanier, grandTotal),
                      const SizedBox(height: 24),
                      const Divider(),
                      _buildActionDetailsColumn(),
                    ],
                  ),
                );
              } else {
                // MISE EN PAGE LARGE (deux colonnes)
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2, // Le panier prend 2/3 de la largeur
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildCartDetailsColumn(
                          produitsPanier,
                          grandTotal,
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 1, // Les actions prennent 1/3 de la largeur
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildActionDetailsColumn(),
                      ),
                    ),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }

  // WIDGET POUR LA PARTIE GAUCHE (détails du panier)
  Widget _buildCartDetailsColumn(
    List<Produit> produitsPanier,
    double grandTotal,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prêt à Commander ?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Récapitulatif des choix :',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: produitsPanier.length,
          itemBuilder: (context, index) {
            return _buildCartItemCard(produitsPanier[index]);
          },
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total avec frais de livraison :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                _formatPrice(grandTotal),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET POUR LA PARTIE DROITE (actions de l'utilisateur)
  Widget _buildActionDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPaymentSection(),
        const SizedBox(height: 24),
        const Divider(),
        _buildDeliverySection(),
        const SizedBox(height: 24),
        _buildConfirmationSection(),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _confirmTerms ? () {} : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFF191970,
            ), // Couleur bleu marine de l'image
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Valider la commande',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // WIDGET POUR UN ARTICLE INDIVIDUEL DANS LE PANIER
  Widget _buildCartItemCard(Produit produit) {
    int quantity =
        _productQuantities[produit.idProduit] ??
        (int.tryParse(produit.quantite) ?? 1);
    double prix = double.tryParse(produit.prix) ?? 0.0;
    double itemTotal = prix * quantity;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'x$quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produit.nomProduit,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.add,
                              onPressed:
                                  () => _updateQuantity(
                                    produit.idProduit,
                                    quantity + 1,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onPressed:
                                  () => _updateQuantity(
                                    produit.idProduit,
                                    quantity - 1,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatPrice(itemTotal),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir une méthode de paiement :',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        _buildRadioTile('MTN Mobile Money', 'MTN'),
        _buildRadioTile('Orange Money', 'ORANGE'),
        _buildRadioTile('Monnaie Physique', 'CASH'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _paymentNumberController,
          decoration: InputDecoration(
            labelText: 'Entrer le numéro de paiement',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildRadioTile(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged:
          (newValue) => setState(() => _selectedPaymentMethod = newValue),
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.red[700],
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir une méthode de livraison :',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        CheckboxListTile(
          title: const Text('Je veux être livré à Domicile'),
          value: _selectedDeliveryMethod == 'domicile',
          onChanged:
              (value) => setState(
                () => _selectedDeliveryMethod = value! ? 'domicile' : null,
              ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.red[700],
        ),
        CheckboxListTile(
          title: const Text('Je viendrai prendre en boutique'),
          value: _selectedDeliveryMethod == 'boutique',
          onChanged:
              (value) => setState(
                () => _selectedDeliveryMethod = value! ? 'boutique' : null,
              ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.red[700],
        ),
      ],
    );
  }

  Widget _buildConfirmationSection() {
    return Row(
      children: [
        Checkbox(
          value: _confirmTerms,
          onChanged: (value) => setState(() => _confirmTerms = value!),
          activeColor: Colors.red[700],
        ),
        const Expanded(
          child: Text(
            "Je confirme mes choix et m'engage à payer le prix total des articles",
          ),
        ),
      ],
    );
  }
}
