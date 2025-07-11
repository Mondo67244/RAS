import 'dart:convert'; // Importé pour le décodage Base64
import 'dart:typed_data'; // Importé pour Uint8List
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/services/lienbd.dart';

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
    _chargerdonneesbasique();
  }

  Future<void> _chargerdonneesbasique() async {
    _produitsFuture = _firestoreService.getProduits();
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

  //Logique du bouton souhait
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
      await _firestoreService.updateProductWishlist(
        produit.idProduit,
        nouvelEtat,
      );
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

  //Logique du bouton panier
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
      icon:
          nouvelEtat
              ? Icons.add_shopping_cart_outlined
              : Icons.remove_shopping_cart_outlined,
    );
    try {
      // APPEL AU SERVICE CENTRALISÉ
      await _firestoreService.updateProductCart(produit.idProduit, nouvelEtat);
    } catch (e) {
      print('Erreur Firestore pour AuPanier: $e');
      _messageReponse('Erreur de mise à jour du panier.', isSuccess: false);
      setState(() {
        // Annulation en cas d'erreur
        if (nouvelEtat) {
          _paniers.remove(produit.idProduit);
        } else {
          _paniers.add(produit.idProduit);
        }
      });
    }
  }

  //Message du bas
  void _messageReponse(
    String message, {
    bool isSuccess = true,
    IconData? icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: isSuccess ? styles.vert : styles.erreur,
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
      body: FutureBuilder<List<Produit>>(
        future: _produitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: styles.rouge),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delivery_dining_outlined,
                    size: 200,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Aucun article trouvé',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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

  //Contenu de la page
  Widget _contenu(List<Produit> produits, {required bool isWideScreen}) {
    final produitsBureautique =
        produits.where((p) => p.categorie == 'Bureautique').toList();
    final produitsPopulaires =
        produits.where((p) => (int.tryParse(p.vues) ?? 0) > 15).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagesEntetes(
            'https://wordpressthemes.live/WCG5/WCM116_kartpul/electronics/wp-content/uploads/2024/09/10.jpg',
            isWide: isWideScreen,
          ),
          const SizedBox(height: 10),
          _sectionProduits('Articles Populaires', produitsPopulaires),
          _imagesEntetes(
            'https://wordpressthemes.live/WCG5/WCM116_kartpul/electronics/wp-content/uploads/2024/09/09.jpg',
            isWide: isWideScreen,
          ),
          const SizedBox(height: 10),
          _sectionProduits(
            'Dans la catégorie Bureautique',
            produitsBureautique,
          ),
          _imagesEntetes(
            'https://wordpressthemes.live/WCG5/WCM116_kartpul/electronics/wp-content/uploads/2024/09/08.jpg',
            isWide: isWideScreen,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  //Images des entetes
  Widget _imagesEntetes(String path, {required bool isWide}) {
    return SizedBox(
      height: isWide ? 90 : 70,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isWide ? 0 : 12),
        child: Image.network(
          path,
          fit: BoxFit.cover,
          loadingBuilder:
              (context, child, loadingProgress) =>
                  loadingProgress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _sectionProduits(String titre, List<Produit> produits) {
    if (produits.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              const Icon(FluentIcons.arrow_right_24_filled),
              const SizedBox(width: 5),
              Text(
                titre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height:
              375, // Garde une hauteur fixe pour la liste horizontale de cartes
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: produits.length,
            itemBuilder: (context, index) => _carteArticle(produits[index]),
          ),
        ),
      ],
    );
  }

  Widget _carteArticle(Produit produit) {
    final bool isSouhait = _souhaits.contains(produit.idProduit);
    final bool isPanier = _paniers.contains(produit.idProduit);
    final bool isWideScreen = MediaQuery.of(context).size.width > 400;

    return SizedBox(
      width: 280,
      child: InkWell(
        onTap:
            () => Navigator.pushNamed(context, '/details', arguments: produit),
        child: Card(
          margin: const EdgeInsets.all(8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //ClipRRECT arrondis les bords du haut
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15.0),
                ),
                child: SizedBox(
                  height: isWideScreen ? 260 : 240,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _appelImages(produit.img1),
                        _appelImages(produit.img2),
                        _appelImages(produit.img3),
                      ],
                    ),
                  ),
                ),
              ),

              //nom du produit et son prix
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nomProduit,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: styles.styleTitre,
                      softWrap: true,
                    ),
                    Center(
                      child: Text(
                        '${produit.prix} CFA',
                        style: styles.stylePrix,
                      ),
                    ),
                  ],
                ),
              ),

              //Les boutons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSouhait
                              ? styles.rouge.withOpacity(0.1)
                              : Colors.white,
                      foregroundColor: styles.rouge,
                      side: BorderSide(color: styles.rouge.withOpacity(0.5)),
                      elevation: 0,
                    ),
                    onPressed: () => _toggleJeVeut(produit),
                    icon: Icon(
                      isSouhait
                          ? FluentIcons.book_star_24_filled
                          : FluentIcons.book_star_24_regular,
                    ),
                    label: Text(isSouhait ? 'Souhaité' : 'Souhait'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPanier ? styles.bleu : Colors.white,
                      foregroundColor: isPanier ? Colors.white : styles.bleu,
                      side: BorderSide(color: styles.bleu.withOpacity(0.5)),
                      elevation: 0,
                    ),
                    onPressed: () => _toggleAuPanier(produit),
                    icon: Icon(
                      isPanier
                          ? FluentIcons.shopping_bag_tag_24_filled
                          : FluentIcons.shopping_bag_tag_24_regular,
                    ),
                    label: Text(isPanier ? 'Ajouté' : 'Panier'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Appeler les images depuis les champs
  Widget _appelImages(String imageData) {
    // Si la donnée est vide, on affiche une icône
    if (imageData.isEmpty) {
      return const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey,
        size: 50,
      );
    }

    if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: BoxFit.contain,
        loadingBuilder:
            (context, child, progress) =>
                progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
        errorBuilder:
            (context, error, stack) =>
                const Icon(Icons.error, color: Colors.grey, size: 50),
      );
    }
    //Logique pour le décodage des images
    try {
      final Uint8List imageBytes = base64.decode(imageData);
      return Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stack) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.grey,
              size: 50,
            ),
      );
    } catch (e) {
      // Si le décodage échoue, on affiche une icône d'erreur
      print('Erreur de décodage Base64: $e');
      return const Icon(
        Icons.broken_image_outlined,
        color: Colors.red,
        size: 50,
      );
    }
  }
}
