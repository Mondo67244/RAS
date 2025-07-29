import 'dart:convert';
import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatelessWidget {
  final Produit produit;
  final bool isPanier;
  final bool isWideScreen;
  final VoidCallback onTogglePanier;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.produit,
    required this.isPanier,
    required this.isWideScreen,
    required this.onTogglePanier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> images = [produit.img1, produit.img2, produit.img3]
        .where((img) => img.isNotEmpty)
        .toList();
    final PageController pageController = PageController();

    return SizedBox(
      width: isWideScreen ? 280 : 260,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          margin: const EdgeInsets.all(8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                child: SizedBox(
                  height: isWideScreen ? 250 : 225,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      images.isEmpty
                          ? Center(
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: Colors.grey.shade400, size: 50),
                            )
                          : PageView.builder(
                              controller: pageController,
                              itemCount: images.length,
                              itemBuilder: (context, index) =>
                                  _appelImages(images[index], context),
                            ),
                      if (produit.enPromo)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: AnimatedOpacity(
                            opacity: produit.enPromo ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 400),
                            child: Chip(
                              backgroundColor: Colors.red.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Styles.rouge, width: 1),
                              ),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.whatshot_outlined,
                                      size: 14, color: const Color.fromARGB(255, 222, 118, 7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'En Promo!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Styles.rouge,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nomProduit,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${produit.prix} CFA',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Styles.rouge,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: produit.enStock
                                ?Styles.vert.withAlpha((0.1 * 255).round())
                                : Styles.erreur.withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            produit.enStock ? 'En stock' : 'Rupture',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: produit.enStock ? Styles.vert : Styles.erreur,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: produit.enStock ? onTogglePanier : null,
                            icon: Icon(
                              isPanier
                                  ? FluentIcons.shopping_bag_tag_24_filled
                                  : FluentIcons.shopping_bag_tag_24_regular,
                              size: 16,
                            ),
                            label: Text(
                              isPanier ? 'Ajouté' : 'Ajouter au Panier',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isPanier ? Colors.blue.shade50 : Styles.bleu,
                              foregroundColor: isPanier ? Styles.bleu : Styles.blanc,
                              side: BorderSide(color: const Color.fromARGB(255, 11, 7, 115), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
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
      ),
    );
  }

  Widget _appelImages(String imageData, BuildContext context) {
    if (imageData.isEmpty) {
      return SizedBox(
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Colors.grey, size: 60),
        ),
      );
    }

    if (imageData.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageData,
        fit: BoxFit.cover,
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const Icon(Icons.error_outline, color: Colors.grey, size: 60),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    }

    try {
      final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=]+');
      if (!base64Regex.hasMatch(imageData)) {
        throw const FormatException('Chaîne Base64 invalide');
      }

      final Uint8List imageBytes = base64Decode(imageData);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.red,
          size: 60,
        ),
      );
    } catch (e) {
      print('Erreur de décodage Base64: $e');
      return SizedBox(
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        child: const Center(
          child:
              Icon(Icons.broken_image_outlined, color: Colors.red, size: 60),
        ),
      );
    }
  }
}
