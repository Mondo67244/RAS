import 'dart:convert';
import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/services/panier/panier_local.dart';
import 'package:ras_app/services/souhaits/souhaits_local.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Details extends StatefulWidget {
  const Details({super.key, required this.produit});
  final Produit produit;

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  final PanierLocal _panierLocal = PanierLocal();
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal();
  late PageController _pageController;
  int _currentPage = 0;
  List<String> _images = [];
  late Produit produit;
  bool _clic = false;
  @override
  void initState() {
    super.initState();
    produit = widget.produit;
    _images =
        [
          produit.img1,
          produit.img2,
          produit.img3,
        ].where((img) => img.isNotEmpty).toList();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
    _checkInitialStates();
  }

  Future<void> _checkInitialStates() async {
    await _panierLocal.init();
    await _souhaitsLocal.init();
    final panierIds = await _panierLocal.getPanier();
    final souhaitsIds = await _souhaitsLocal.getSouhaits();

    setState(() {
      produit = produit.copyWith(
        auPanier: panierIds.contains(produit.idProduit),
        jeVeut: souhaitsIds.contains(produit.idProduit),
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleSouhait(Produit produit) async {
    final bool isCurrentlyWished = produit.jeVeut;
    try {
      if (isCurrentlyWished) {
        await _souhaitsLocal.retirerDesSouhaits(produit.idProduit);
        _messageReponse(
          'Retiré des souhaits',
          icon: FluentIcons.book_star_24_regular,
        );
      } else {
        // If adding to wishlist, remove from cart if present
        if (produit.auPanier) {
          await _panierLocal.retirerDuPanier(produit.idProduit);
        }
        await _souhaitsLocal.ajouterAuxSouhaits(produit.idProduit);
        _messageReponse(
          'Ajouté aux souhaits',
          icon: FluentIcons.class_20_filled,
        );
      }
      setState(() {
        produit = produit.copyWith(
          jeVeut: !isCurrentlyWished,
          auPanier:
              isCurrentlyWished
                  ? produit.auPanier
                  : false, // If adding to wishlist, ensure not in cart
        );
      });
    } catch (e) {
      _messageReponse(
        'Erreur: Impossible de modifier les souhaits',
        isSuccess: false,
        icon: Icons.error,
      );
    }
  }

  void _togglePanier(Produit produit) async {
    final bool isCurrentlyInCart = produit.auPanier;
    try {
      if (isCurrentlyInCart) {
        await _panierLocal.retirerDuPanier(produit.idProduit);
        _messageReponse(
          'Retiré du panier',
          icon: FluentIcons.shopping_bag_tag_24_regular,
        );
      } else {
        // If adding to cart, remove from wishlist if present
        if (produit.jeVeut) {
          await _souhaitsLocal.retirerDesSouhaits(produit.idProduit);
        }
        await _panierLocal.ajouterAuPanier(produit.idProduit);
        _messageReponse(
          'Ajouté au panier',
          icon: FluentIcons.shopping_bag_tag_24_filled,
        );
      }
      setState(() {
        produit = produit.copyWith(
          auPanier: !isCurrentlyInCart,
          jeVeut:
              isCurrentlyInCart
                  ? produit.jeVeut
                  : false, // If adding to cart, ensure not in wishlist
        );
      });
    } catch (e) {
      _messageReponse(
        'Erreur: Impossible de modifier le panier',
        isSuccess: false,
        icon: Icons.error,
      );
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
        backgroundColor: isSuccess ? Styles.vert : Styles.erreur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message, style: Styles.textebas)),
          ],
        ),
      ),
    );
  }

  Widget _montreLesImages() {
    if (_images.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              "Aucune image disponible",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _images.length,
          itemBuilder: (context, index) => _appelImages(_images[index]),
        ),
        Positioned(
          bottom: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_images.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentPage == index ? 12 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentPage == index
                          ? Styles.rouge
                          : Colors.white.withAlpha((0.7 * 255).round()),
                ),
              );
            }),
          ),
        ),
        if (_images.length > 1) ...[
          if (_currentPage > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: _fleches(
                icon: Icons.arrow_back_ios_new,
                onPressed:
                    () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
              ),
            ),
          if (_currentPage < _images.length - 1)
            Align(
              alignment: Alignment.centerRight,
              child: _fleches(
                icon: Icons.arrow_forward_ios,
                onPressed:
                    () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _fleches({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.5 * 255).round()),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _detailsContenu(Produit produit) {
    final constraints = MediaQuery.of(context).size.width > 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          constraints
              ? const SizedBox(height: 120)
              : const SizedBox(height: 10),
          Text(
            produit.nomProduit,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (produit.enPromo)
                Row(
                  children: [
                    Text(
                      '${produit.prix} CFA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Styles.rouge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${produit.ancientPrix} CFA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '${produit.prix} CFA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Styles.rouge,
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      produit.enStock
                          ? Styles.vert.withAlpha((0.1 * 255).round())
                          : Styles.erreur.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  produit.enStock ? 'En stock' : 'Rupture',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: produit.enStock ? Styles.vert : Styles.erreur,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            'Caractéristiques du produit :',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          _carteDetails(produit),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              //Bouton souhait
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Styles.rouge,
                  side: BorderSide(color: Styles.rouge, width: 1.5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    produit.enStock ? () => _toggleSouhait(produit) : null,
                icon: Icon(
                  produit.jeVeut
                      ? FluentIcons.class_20_filled
                      : FluentIcons.book_star_24_regular,
                  size: 20,
                ),
                label: Text(
                  produit.jeVeut ? 'Souhaité' : 'Je Souhaite',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              //Bouton Panier
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      produit.enStock ? Styles.bleu : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    produit.enStock ? () => _togglePanier(produit) : null,
                icon: Icon(
                  produit.auPanier
                      ? FluentIcons.shopping_bag_tag_24_filled
                      : FluentIcons.shopping_bag_tag_24_regular,
                  size: 20,
                ),
                label: Text(
                  produit.auPanier ? 'Ajouté ! ' : 'Ajouter au Panier',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailsContenumob(Produit produit) {
    final constraints = MediaQuery.of(context).size.width > 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          constraints
              ? const SizedBox(height: 150)
              : const SizedBox(height: 10),
          Text(
            produit.nomProduit,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (produit.enPromo)
                Row(
                  children: [
                    Text(
                      '${produit.prix} CFA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Styles.rouge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${produit.ancientPrix} CFA',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '${produit.prix} CFA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Styles.rouge,
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      produit.enStock
                          ? Styles.vert.withAlpha((0.1 * 255).round())
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

          const SizedBox(height: 24),
          Text(
            'Caractéristiques du produit :',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          _carteDetails(produit),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Styles.bleu,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (){
                    setState(() {
                      _clic = !_clic;
                    });
                  },
                  icon: Icon(
                    _clic
                        ? FluentIcons.heart_24_filled
                        : FluentIcons.heart_24_regular,
                    size: 20,
                  ),
                  label: Text(
                    _clic ? 'Aimé' : 'J\'aime',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                //Le bouton Enregistrer
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Styles.rouge,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: produit.enStock ? () => _toggleSouhait(produit) : null,
                  icon: Icon(
                    produit.jeVeut
                        ? FluentIcons.class_20_filled
                        : FluentIcons.book_star_24_regular,
                    size: 20,
                  ),
                  label: Text(
                    produit.jeVeut ? 'Enregistré !' : 'Enregistrer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Text(
            'Description Détaillée:',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            produit.description.isNotEmpty
                ? produit.description
                : "Aucune description fournie pour ce produit.",
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
          _methodePaiment(produit),

          if (MediaQuery.of(context).size.width > 600) ...[
            const SizedBox(height: 32),
            _boutons(produit),
          ],
        ],
      ),
    );
  }

  //Description détaillée
  Widget _detailsTxt(Produit produit) {
    final constraints = MediaQuery.of(context).size.width > 1200;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            constraints
                ? const SizedBox(height: 150)
                : const SizedBox(height: 12),
            Text(
              'Description Détaillée:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              produit.description.isNotEmpty
                  ? produit.description
                  : "Aucune description fournie pour ce produit.",
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Méthode de paiement
  Widget _methodePaiment(Produit produit) {
    final cash = produit.cash;
    final electro = produit.electronique;
    String methode = '';

    if (cash == true && electro == true) {
      methode = 'En Espece ou Mobile Money (MTN/ORANGE)';
    } else if (cash == true && electro == false) {
      methode = 'Espece';
    } else if (cash == false && electro == true) {
      methode = 'Mobile Money (MTN/ORANGE)';
    } else {
      methode = 'En attente de confirmation';
    }

    return Column(
      children: [
        Text(
          'Méthodes de paiement acceptées : ',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        Text(
          methode,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  //Container contenant les détails de l'article
  Widget _carteDetails(Produit produit) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _detailsIndividuels(
              FluentIcons.tag_24_regular,
              'Marque',
              produit.marque,
            ),
            const Divider(height: 24),
            _detailsIndividuels(
              FluentIcons.box_24_regular,
              'Modèle',
              produit.modele,
            ),
            const Divider(height: 24),
            _detailsIndividuels(
              FluentIcons.apps_list_detail_24_regular,
              'Type',
              produit.type,
            ),
            const Divider(height: 24),

            _detailsIndividuels(
              FluentIcons.send_clock_20_regular,

              'Livrable',
              produit.livrable ? 'Oui' : 'Non',
            ),
            const Divider(height: 24),

            _detailsIndividuels(
              FluentIcons.document_bullet_list_16_regular,
              'Quantité Dispo',
              produit.quantite,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _detailsIndividuels(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 22),
        const SizedBox(width: 16),
        Text(
          '$label :',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _boutons(Produit produit) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  produit.enStock ? Styles.bleu : Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: produit.enStock ? () => _togglePanier(produit) : null,
            icon: Icon(
              produit.auPanier
                  ? FluentIcons.shopping_bag_tag_24_filled
                  : FluentIcons.shopping_bag_tag_24_regular,
              size: 20,
            ),
            label: Text(
              produit.auPanier ? 'Ajouté au Panier ' : 'Ajouter au Panier',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _appelImages(String imageData) {
    if (imageData.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 60,
        ),
      );
    }

    if (imageData.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageData,
        fit: BoxFit.contain,
        placeholder:
            (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget:
            (context, url, error) =>
                const Icon(Icons.error_outline, color: Colors.grey, size: 60),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    }

    try {
      // Vérifier si la chaîne est un Base64 valide
      final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
      if (!base64Regex.hasMatch(imageData)) {
        throw const FormatException('Chaîne Base64 invalide');
      }

      final Uint8List imageBytes = base64Decode(imageData);
      return Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.red,
              size: 60,
            ),
      );
    } catch (e) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 60),
      );
    }
  }

  //Interface principale
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.produit.nomProduit,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        shadowColor: Colors.black.withAlpha((0.1 * 255).round()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1200) {
              return Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 1300),
                  child: Row(
                    key: const Key('layout Web'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _montreLesImages()),
                      Expanded(flex: 3, child: _detailsContenu(produit)),
                      Expanded(flex: 3, child: _detailsTxt(produit)),
                    ],
                  ),
                ),
              );
            }
            if (constraints.maxWidth > 964) {
              return Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 900),
                  child: Row(
                    key: const Key('layout tablet'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _montreLesImages()),
                      Expanded(flex: 2, child: _detailsContenumob(produit)),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  key: const Key('layout Mobile'),
                  children: [
                    Expanded(flex: 2, child: _montreLesImages()),
                    Expanded(flex: 3, child: _detailsContenumob(produit)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar:
          MediaQuery.of(context).size.width <= 600
              ? BottomAppBar(
                elevation: 8,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _boutons(produit),
              )
              : null,
    );
  }
}
