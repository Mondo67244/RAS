
import 'dart:convert';
import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatelessWidget {
  final Produit produit;
  final bool isSouhait;
  final bool isPanier;
  final bool isWideScreen;
  final VoidCallback onToggleSouhait;
  final VoidCallback onTogglePanier;

  const ProductCard({
    super.key,
    required this.produit,
    required this.isSouhait,
    required this.isPanier,
    required this.isWideScreen,
    required this.onToggleSouhait,
    required this.onTogglePanier,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> images = [produit.img1, produit.img2, produit.img3]
        .where((img) => img.isNotEmpty)
        .toList();
    final PageController pageController = PageController();

    return SizedBox(
      width: isWideScreen ? 300 : 280,
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/details', arguments: produit),
        child: Card(
          margin: const EdgeInsets.all(10),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: isWideScreen ? 250 : 230,
                  child: images.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                            size: 60,
                          ),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            PageView.builder(
                              controller: pageController,
                              itemCount: images.length,
                              itemBuilder: (context, index) =>
                                  _appelImages(images[index], context),
                            ),
                            if (images.length > 1) ...[
                              Positioned(
                                bottom: 12,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:
                                      List.generate(images.length, (index) {
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: pageController.hasClients &&
                                              pageController.page?.round() ==
                                                  index
                                          ? 12
                                          : 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: pageController.hasClients &&
                                                pageController.page?.round() ==
                                                    index
                                            ? styles.rouge
                                            : Colors.grey.shade300,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              if (pageController.hasClients &&
                                  (pageController.page?.round() ?? 0) > 0)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _fleche(
                                    icon: Icons.arrow_back_ios_new,
                                    onPressed: () =>
                                        pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                ),
                              if (pageController.hasClients &&
                                  (pageController.page?.round() ?? 0) <
                                      images.length - 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _fleche(
                                    icon: Icons.arrow_forward_ios,
                                    onPressed: () => pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            produit.nomProduit,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${produit.prix} CFA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: styles.rouge,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: produit.enStock
                                      ? styles.vert.withOpacity(0.1)
                                      : styles.erreur.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  produit.enStock
                                      ? 'En stock'
                                      : 'Rupture de stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: produit.enStock
                                        ? styles.vert
                                        : styles.erreur,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: styles.rouge,
                                side: BorderSide(
                                    color: styles.rouge, width: 1.2),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: produit.enStock
                                  ? onToggleSouhait
                                  : null,
                              icon: Icon(
                                isSouhait
                                    ? FluentIcons.book_star_24_filled
                                    : FluentIcons.book_star_24_regular,
                                size: 18,
                              ),
                              label: Text(
                                isSouhait ? 'Souhaité' : 'Souhait',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: produit.enStock
                                    ? styles.bleu
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: produit.enStock
                                  ? onTogglePanier
                                  : null,
                              icon: Icon(
                                isPanier
                                    ? FluentIcons.shopping_bag_tag_24_filled
                                    : FluentIcons
                                        .shopping_bag_tag_24_regular,
                                size: 18,
                              ),
                              label: Text(
                                isPanier ? 'Ajouté' : 'Panier',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fleche({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
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
        fit: BoxFit.contain,
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const Icon(Icons.error_outline, color: Colors.grey, size: 60),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    }

    try {
      final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
      if (!base64Regex.hasMatch(imageData)) {
        throw const FormatException('Chaîne Base64 invalide');
      }

      final Uint8List imageBytes = base64Decode(imageData);
      return Image.memory(
        imageBytes,
        fit: BoxFit.contain,
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
