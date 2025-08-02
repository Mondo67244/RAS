import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/basicdata/style.dart';

class PaymentPage extends StatefulWidget {
  final Commande commande;

  const PaymentPage({
    super.key,
    required this.commande,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _selectedPaymentMethod;
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec le numéro de paiement de la commande si disponible
    if (widget.commande.numeroPaiement.isNotEmpty) {
      _phoneController.text = widget.commande.numeroPaiement;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Commandes')
          .doc(transactionId)
          .update({'statutPaiement': 'Payé'});
      print('Statut de la commande mis à jour avec succès.');
    } catch (e) {
      print('Erreur lors de la mise à jour du statut de la commande: $e');
    }
  }

  void _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une méthode de paiement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod != 'CASH' && _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre numéro de téléphone'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simuler le traitement du paiement
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });

    // Mettre à jour le statut dans Firestore
    await _updateOrderStatus(widget.commande.idCommande);

    // Afficher le message de succès
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement de ${widget.commande.prixCommande} CFA effectué avec succès !'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Retourner à la page précédente après un délai
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop('success');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double amountToPay;
    try {
      amountToPay = double.parse(widget.commande.prixCommande);
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: Styles.rouge,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Le montant de la commande est invalide.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Styles.rouge,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isSuccess 
        ? _buildSuccessView()
        : _buildPaymentView(amountToPay),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Styles.rouge, Colors.red.shade700],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                FluentIcons.checkmark_circle_24_filled,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Paiement Réussi !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.commande.prixCommande} CFA',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Votre commande a été confirmée',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentView(double amountToPay) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Styles.rouge, Colors.red.shade700],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête avec montant
              Container(
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
                  children: [
                    const Icon(
                      FluentIcons.payment_24_filled,
                      size: 60,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Montant à payer',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${amountToPay.toStringAsFixed(0)} CFA',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Commande #${widget.commande.idCommande.substring(0,4).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Méthodes de paiement
              Container(
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Méthode de paiement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // MTN Mobile Money
                    _buildPaymentOption(
                      'MTN Mobile Money',
                      FluentIcons.phone_24_filled,
                      Colors.orange,
                      'MTN',
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Orange Money
                    _buildPaymentOption(
                      'Orange Money',
                      FluentIcons.phone_24_filled,
                      Colors.orange.shade700,
                      'ORANGE',
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Paiement en espèces
                    _buildPaymentOption(
                      'Paiement en espèces',
                      FluentIcons.money_24_filled,
                      Colors.green,
                      'CASH',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Champ numéro de téléphone (si nécessaire)
              if (_selectedPaymentMethod != null && _selectedPaymentMethod != 'CASH')
                Container(
                  padding: const EdgeInsets.all(20),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Numéro ${_selectedPaymentMethod == 'MTN' ? 'MTN' : 'Orange'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Ex: 672123456',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(FluentIcons.phone_24_filled),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 30),
              
              // Bouton de paiement
              ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Styles.rouge,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : const Text(
                        'Payer maintenant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, Color color, String value) {
    final isSelected = _selectedPaymentMethod == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                FluentIcons.checkmark_circle_24_filled,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}