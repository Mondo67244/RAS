import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/services/base%20de%20donn%C3%A9es/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:ras_app/basicdata/style.dart';

class Souhaits extends StatefulWidget {
  const Souhaits({Key? key}) : super(key: key);

  @override
  State<Souhaits> createState() => SouhaitsState();
}

class SouhaitsState extends State<Souhaits> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<Produit>> _wishlistStream;

  @override
  void initState() {
    super.initState();
    _wishlistStream = _firestoreService.getProduitsStream();
  }

  Future<void> _toggleJeVeut(Produit produit) async {
    try {
      await _firestoreService.updateProductWishlist(produit.idProduit, !produit.jeVeut);
      _messageReponse(
        !produit.jeVeut
            ? '${produit.nomProduit} ajouté à vos souhaits'
            : '${produit.nomProduit} retiré de vos souhaits',
        isSuccess: true,
      );
    } catch (e) {
      _messageReponse('Erreur lors de la mise à jour des souhaits.', isSuccess: false);
    }
  }

  Future<void> _addToCart(Produit produit) async {
    try {
      await _firestoreService.updateProductCart(produit.idProduit, true);
      _messageReponse(
        '${produit.nomProduit} ajouté au panier',
        isSuccess: true,
        icon: Icons.add_shopping_cart_outlined,
      );
    } catch (e) {
      _messageReponse('Erreur lors de l\'ajout au panier.', isSuccess: false);
    }
  }

  void _messageReponse(
    String message, {
    bool isSuccess = true,
    IconData? icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: isSuccess ? styles.vert : styles.erreur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message, style: styles.textebas)),
          ],
        ),
      ),
    );
  }

  Widget _carteEquipement(Produit produit) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1298;

    if (produit.idProduit.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: isWideScreen ? _carteOrdi(produit) : _carteMobile(produit),
    );
  }

  Widget _carteOrdi(Produit produit) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/details', arguments: produit),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageContainer(produit.img1, 150.0, 150.0),
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
                    SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_buildActionButtons(produit, 10.0)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteMobile(Produit produit) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/details', arguments: produit),
      child: Padding(
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
                    SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_buildActionButtons(produit, 10.0)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Produit produit, double size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: styles.bleuvar,
            side: BorderSide(color: styles.bleuvar, width: 1.2),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => _addToCart(produit),
          icon: const Icon(FluentIcons.cart_24_regular, size: 16),
          label: const Text('Ajouter au panier'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _toggleJeVeut(produit),
          icon: Icon(
            FluentIcons.heart_24_filled,
            color: styles.erreur,
            size: size,
          ),
        ),
      ],
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
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              const Icon(Icons.error_outline, color: Colors.grey, size: 50),
          fadeInDuration: const Duration(milliseconds: 300),
        ),
      );
    }

    try {
      final Uint8List imageBytes = base64Decode(imageData);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => const Center(
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
          constraints: isWideScreen
              ? const BoxConstraints(maxWidth: 1200)
              : const BoxConstraints(maxWidth: 400),
          child: StreamBuilder<List<Produit>>(
            stream: _wishlistStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text('Erreur de chargement des souhaits.'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Votre liste de souhaits est vide.'));
              }

              final produitsSouhaites =
                  snapshot.data!.where((p) => p.jeVeut).toList();

              if (produitsSouhaites.isEmpty) {
                return const Center(child: Text('Votre liste de souhaits est vide.'));
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
                      itemCount: produitsSouhaites.length,
                      itemBuilder: (context, index) =>
                          _carteEquipement(produitsSouhaites[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: produitsSouhaites.length,
                      itemBuilder: (context, index) =>
                          _carteEquipement(produitsSouhaites[index]),
                    );
            },
          ),
        ),
      ),
    );
  }
}
