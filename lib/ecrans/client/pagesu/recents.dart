import 'dart:convert';
import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/services/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Recents extends StatefulWidget {
  const Recents({super.key});

  @override
  State<Recents> createState() => _RecentsState();
}

class _RecentsState extends State<Recents> {
  late Future<List<Produit>> _produitsFuture;
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _souhaits = {};
  final Set<String> _paniers = {};

  @override
  void initState() {
    super.initState();
    _produitsFuture = _firestoreService.getProduits();
    _chargerDonneesInitiales();
  }

  Future<void> _chargerDonneesInitiales() async {
    try {
      final produits = await _produitsFuture;
      if (!mounted) return;
      setState(() {
        for (var produit in produits) {
          if (produit.jeVeut) _souhaits.add(produit.idProduit);
          if (produit.auPanier) _paniers.add(produit.idProduit);
        }
      });
    } catch (e) {
      print('Erreur lors du chargement des données initiales: $e');
      _messageReponse('Erreur de chargement des données.', isSuccess: false);
    }
  }

  Future<void> _toggleJeVeut(Produit produit) async {
    final bool nouvelEtat = !_souhaits.contains(produit.idProduit);
    setState(() {
      if (nouvelEtat) {
        _souhaits.add(produit.idProduit);
        _paniers.remove(produit.idProduit);
      } else {
        _souhaits.remove(produit.idProduit);
      }
    });
    _messageReponse(
      nouvelEtat
          ? '${produit.nomProduit} ajouté à vos souhaits'
          : '${produit.nomProduit} retiré de vos souhaits',
      isSuccess: nouvelEtat,
    );
    try {
      await _firestoreService.updateProductWishlist(produit.idProduit, nouvelEtat);
      if (nouvelEtat) {
        await _firestoreService.updateProductCart(produit.idProduit, false);
      }
    } catch (e) {
      print('Erreur Firestore pour JeVeut: $e');
      _messageReponse('Erreur de mise à jour du souhait.', isSuccess: false);
      setState(() {
        if (nouvelEtat) {
          _souhaits.remove(produit.idProduit);
        } else {
          _souhaits.add(produit.idProduit);
        }
      });
    }
  }

  Future<void> _toggleAuPanier(Produit produit) async {
    final bool nouvelEtat = !_paniers.contains(produit.idProduit);
    setState(() {
      if (nouvelEtat) {
        _paniers.add(produit.idProduit);
        _souhaits.remove(produit.idProduit);
      } else {
        _paniers.remove(produit.idProduit);
      }
    });
    _messageReponse(
      nouvelEtat
          ? '${produit.nomProduit} ajouté au panier'
          : '${produit.nomProduit} retiré du panier',
      isSuccess: nouvelEtat,
      icon: nouvelEtat ? Icons.add_shopping_cart_outlined : Icons.remove_shopping_cart_outlined,
    );
    try {
      await _firestoreService.updateProductCart(produit.idProduit, nouvelEtat);
      if (nouvelEtat) {
        await _firestoreService.updateProductWishlist(produit.idProduit, false);
      }
    } catch (e) {
      print('Erreur Firestore pour AuPanier: $e');
      _messageReponse('Erreur de mise à jour du panier.', isSuccess: false);
      setState(() {
        if (nouvelEtat) {
          _paniers.remove(produit.idProduit);
        } else {
          _paniers.add(produit.idProduit);
        }
      });
    }
  }

  void _messageReponse(String message, {bool isSuccess = true, IconData? icon}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Articles récents',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: FutureBuilder<List<Produit>>(
        future: _produitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: styles.rouge),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: TextStyle(color: styles.erreur, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delivery_dining_outlined,
                    size: 150,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun article trouvé',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          final produits = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideScreen = constraints.maxWidth > 600;
              return _contenu(produits, isWideScreen: isWideScreen);
            },
          );
        },
      ),
    );
  }

  Widget _contenu(List<Produit> produits, {required bool isWideScreen}) {
    final produitsBureautique = produits.where((p) => p.type == 'Bureautique').toList();
    final produitsPopulaires = produits.where((p) => (int.tryParse(p.vues) ?? 0) > 15).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagesEntetes(
            'https://wordpressthemes.live/WCG5/WCM116_kartpul/electronics/wp-content/uploads/2024/09/10.jpg',
            isWide: isWideScreen,
          ),
          const SizedBox(height: 24),
          _sectionProduits('Articles Populaires', produitsPopulaires, isWideScreen),
          const SizedBox(height: 24),
          _imagesEntetes(
            'https://wordpressthemes.live/WCG5/WCM116_kartpul/electronics/wp-content/uploads/2024/09/09.jpg',
            isWide: isWideScreen,
          ),
          const SizedBox(height: 24),
          _sectionProduits('Appareils pour la Bureautique', produitsBureautique, isWideScreen),
          const SizedBox(height: 24),
          _imagesEntetes(
            'https://wordpressthemes.live/WCG5/WCM116_kartpul/electronics/wp-content/uploads/2024/09/08.jpg',
            isWide: isWideScreen,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _imagesEntetes(String path, {required bool isWide}) {
    return SizedBox(
      height: isWide ? 120 : 100,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: path,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Icon(Icons.error_outline, color: Colors.grey.shade400, size: 60),
          fadeInDuration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  Widget _sectionProduits(String titre, List<Produit> produits, bool isWideScreen) {
    if (produits.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Row(
            children: [
              Icon(FluentIcons.arrow_right_24_filled, color: styles.bleu, size: 24),
              const SizedBox(width: 8),
              Text(
                titre,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: isWideScreen ? 420 : 400,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: produits.length,
            itemBuilder: (context, index) => _carteArticle(produits[index], isWideScreen),
          ),
        ),
      ],
    );
  }

  Widget _carteArticle(Produit produit, bool isWideScreen) {
    final bool isSouhait = _souhaits.contains(produit.idProduit);
    final bool isPanier = _paniers.contains(produit.idProduit);
    final List<String> images = [produit.img1, produit.img2, produit.img3].where((img) => img.isNotEmpty).toList();
    final PageController pageController = PageController();

    return SizedBox(
      
      width: isWideScreen ? 300 : 280,
      
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/details', arguments: produit),
        child: Card(
          margin: const EdgeInsets.all(10),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                              itemBuilder: (context, index) => _appelImages(images[index]),
                            ),
                            if (images.length > 1) ...[
                              Positioned(
                                bottom: 12,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(images.length, (index) {
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: pageController.hasClients && pageController.page?.round() == index ? 12 : 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: pageController.hasClients && pageController.page?.round() == index
                                            ? styles.rouge
                                            : Colors.grey.shade300,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              if (pageController.hasClients && (pageController.page?.round() ?? 0) > 0)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _fleche(
                                    icon: Icons.arrow_back_ios_new,
                                    onPressed: () => pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                ),
                              if (pageController.hasClients && (pageController.page?.round() ?? 0) < images.length - 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _fleche(
                                    icon: Icons.arrow_forward_ios,
                                    onPressed: () => pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
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
                          //Prix et chip
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: produit.enStock ? styles.vert.withOpacity(0.1) : styles.erreur.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              produit.enStock ? 'En stock' : 'Rupture de stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: produit.enStock ? styles.vert : styles.erreur,
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
                          //Bouton souhait
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: styles.rouge,
                                side: BorderSide(color: styles.rouge, width: 1.2),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: produit.enStock ? () => _toggleJeVeut(produit) : null,
                              icon: Icon(
                                isSouhait ? FluentIcons.book_star_24_filled : FluentIcons.book_star_24_regular,
                                size: 18,
                              ),
                              label: Text(
                                isSouhait ? 'Souhaité' : 'Souhait',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          //Bouton Panier
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: produit.enStock ? styles.bleu : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: produit.enStock ? () => _toggleAuPanier(produit) : null,
                              icon: Icon(
                                isPanier ? FluentIcons.shopping_bag_tag_24_filled : FluentIcons.shopping_bag_tag_24_regular,
                                size: 18,
                              ),
                              label: Text(
                                isPanier ? 'Ajouté' : 'Panier',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

  Widget _appelImages(String imageData) {
    if (imageData.isEmpty) {
      return SizedBox(
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 60),
        ),
      );
    }

    if (imageData.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageData,
        fit: BoxFit.contain,
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(
          Icons.error_outline,
          color: Colors.grey,
          size: 60,
        ),
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
          child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 60),
        ),
      );
    }
  }
}

