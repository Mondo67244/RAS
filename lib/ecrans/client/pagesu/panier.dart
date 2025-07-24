import 'package:flutter/material.dart';
import 'package:ras_app/services/base%20de%20donn%C3%A9es/lienbd.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class Panier extends StatefulWidget {
  const Panier({Key? key}) : super(key: key);

  @override
  State<Panier> createState() => PanierState();
}

class PanierState extends State<Panier> {
  late Stream<List<Produit>> _cartProductsStream;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _cartProductsStream = _firestoreService.getProduitsStream();
  }

  Future<void> _removeFromCart(String idProduit) async {
    try {
      await _firestoreService.updateProductCart(idProduit, false);
    } catch (e) {
      // Gérer l'erreur, par exemple, afficher un message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression du produit: $e')),
      );
    }
  }

  Widget _buildProductCard(Produit produit) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1298;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: isWideScreen ? _carteOrdi(produit) : _carteMobile(produit),
    );
  }

  Widget _carteOrdi(Produit produit) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageContainer(produit.img1, 120.0, 120.0),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 250,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nomProduit.isNotEmpty
                        ? produit.nomProduit
                        : 'Produit sans nom',
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 250,
                    child: Text(
                      produit.descriptionCourte.isNotEmpty
                          ? produit.descriptionCourte
                          : 'Aucune description',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: styles.erreur,
                          side: BorderSide(color: styles.erreur, width: 1.2),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _removeFromCart(produit.idProduit),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Supprimer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteMobile(Produit produit) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageContainer(produit.img1, 100.0, 100.0),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 124,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nomProduit.isNotEmpty
                        ? produit.nomProduit
                        : 'Produit sans nom',
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 250,
                    child: Text(
                      produit.descriptionCourte.isNotEmpty
                          ? produit.descriptionCourte
                          : 'Aucune description',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: styles.erreur,
                          side: BorderSide(color: styles.erreur, width: 1.2),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _removeFromCart(produit.idProduit),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Supprimer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer(String? imageData, double width, double height) {
    if (imageData == null || imageData.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 50,
          ),
        ),
      );
    }

    if (imageData.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageData,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget:
              (context, url, error) => const Icon(Icons.error_outline, color: Colors.grey, size: 50),
          fadeInDuration: const Duration(milliseconds: 300),
        ),
      );
    }

    try {
      final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
      if (!base64Regex.hasMatch(imageData)) {
        throw const FormatException('Chaîne Base64 invalide');
      }

      final Uint8List imageBytes = base64Decode(imageData);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder:
              (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.red,
                  size: 50,
                ),
              ),
        ),
      );
    } catch (e) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1298;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints:
              isWideScreen
                  ? BoxConstraints(maxWidth: 1200)
                  : BoxConstraints(maxWidth: 400),
          child: StreamBuilder<List<Produit>>(
            stream: _cartProductsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Erreur de chargement du panier.'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Votre panier est vide.'),
                );
              }
              final produitsPanier = snapshot.data!.where((p) => p.auPanier).toList();

              if (produitsPanier.isEmpty) {
                return const Center(
                  child: Text('Votre panier est vide.'),
                );
              }
              return isWideScreen
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.9,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: produitsPanier.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(produitsPanier[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: produitsPanier.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(produitsPanier[index]),
                    );
            },
          ),
        ),
      ),
    );
  }
}