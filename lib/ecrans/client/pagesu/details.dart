import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';

class Details extends StatefulWidget {
  const Details({super.key, required this.produit});
  final Produit produit;

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  bool _enStock = true;

  @override
  void initState() {
    super.initState();
    _verif();
  }

  void _verif() {
    if (widget.produit.enStock == false) {
      setState(() {
        _enStock = false;
      });
    }
  }

  Widget _afficherImages() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double hauteurMax = constraints.maxHeight;
        double hauteurMin = constraints.minHeight;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: hauteurMin,
              maxHeight: hauteurMax,
            ),
            child: Row(
              children: [
               
                SizedBox(
                  height: hauteurMax,
                  child: Image.network(
                    widget.produit.img1,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      print(stackTrace);
                      return const Icon(Icons.error_outline, size: 50);
                    },
                  ),
                ),
                SizedBox(
                  height: hauteurMax,
                  child: Image.network(
                    widget.produit.img2,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error_outline, size: 50),
                  ),
                ),
                SizedBox(
                  height: hauteurMax,
                  child: Image.network(
                    widget.produit.img3,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error_outline, size: 50),
                  ),
                ),
                
                
                
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget pour afficher les détails des produits
  Widget _afficherDetailsProduits() {
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.produit.nomProduit,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Produit en stock: ${_enStock ? 'Oui' : 'Non'}',
            style: TextStyle(fontSize: 18, color: _enStock ? Colors.green : Colors.red),
          ),
          const SizedBox(height: 16),
          const Text(
            'Description longue du produit...',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
            },
            child: const Text('Ajouter au Panier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: style.blanc,
        title: const Text(
          'Détails de l\'article',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: style.rouge,
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(
                  flex: 1, // Prend la moitié de la largeur
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 700,
                      child: _afficherImages()),
                  ),
                ),
                Expanded(
                  flex: 1, // Prend l'autre moitié de la largeur
                  child: _afficherDetailsProduits(),
                ),
              ],
            );
          } else {
            // Mode Mobile : les images en haut, les détails en bas
            return Column(
              children: [
                
                Expanded(
                   flex: 2, 
                   child: _afficherImages(),
                ),
                Expanded(
                   flex: 3, // Les détails prennent 3/5 de la hauteur
                   child: _afficherDetailsProduits(),
                ),
                // SizedBox(height: 300, child: _afficherImages()),
                // Expanded(child: _afficherDetailsProduits()), 
              ],
            );
          }
        },
      ),
    );
  }
}