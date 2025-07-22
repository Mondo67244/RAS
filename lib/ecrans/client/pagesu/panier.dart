import 'package:flutter/material.dart';
import 'package:ras_app/services/ponts/pontPanierLocal.dart';
import 'package:ras_app/services/base%20de%20donn%C3%A9es/lienbd.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class Panier extends StatefulWidget {
  const Panier({super.key});

  @override
  State<Panier> createState() => _PanierState();
}

class _PanierState extends State<Panier> {
  late Future<List<Produit>> _cartProductsFuture;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _cartProductsFuture = _getCartProducts();
  }

  Future<List<Produit>> _getCartProducts() async {
    final ids = await LocalCartService.getProductIds();
    if (ids.isEmpty) return [];
    List<Produit> produits = [];
    for (var i = 0; i < ids.length; i += 10) {
      final batch = ids.skip(i).take(10).toList();
      final snapshot = await _firestoreService.produitsCollection
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      produits.addAll(snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Produit(
          descriptionCourte: data['descriptionCourte'] ?? '',
          sousCategorie: data['sousCategorie'] ?? '',
          enPromo: data['enPromo'] ?? false,
          cash: data['cash'] ?? false,
          electronique: data['electronique'] ?? false,
          quantite: data['quantite'] ?? '',
          livrable: data['livrable'] ?? true,
          createdAt: data['createdAt'] ?? Timestamp.now(),
          enStock: data['enStock'] ?? true,
          img1: data['img1'] ?? '',
          img2: data['img2'] ?? '',
          img3: data['img3'] ?? '',
          idProduit: doc.id,
          nomProduit: data['nomProduit'] ?? '',
          description: data['description'] ?? '',
          prix: data['prix'] ?? '',
          vues: data['vues']?.toString() ?? '0',
          modele: data['modele'] ?? '',
          marque: data['marque'] ?? '',
          categorie: data['categorie'] ?? '',
          type: data['type'] ?? '',
          jeVeut: false,
          auPanier: true,
        );
      }));
    }
    return produits;
  }

  Future<void> _removeFromCart(String idProduit) async {
    await LocalCartService.removeProductId(idProduit);
    setState(() {
      _cartProductsFuture = _getCartProducts();
    });
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
          child: FutureBuilder<List<Produit>>(
            future: _cartProductsFuture,
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
              final produitsPanier = snapshot.data!;
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