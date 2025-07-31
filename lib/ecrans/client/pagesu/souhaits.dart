import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/services/base%20de%20donn%C3%A9es/lienbd.dart';
import 'package:ras_app/services/panier/panier_local.dart';
import 'package:ras_app/services/souhaits/souhaits_local.dart';

class Souhaits extends StatefulWidget {
  const Souhaits({Key? key}) : super(key: key);

  @override
  State<Souhaits> createState() => SouhaitsState();
}

class SouhaitsState extends State<Souhaits> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<Produit>> _wishlistStream;
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal();
  final PanierLocal _panierLocal = PanierLocal();

  List<String> _idsSouhaits = [];
  List<String> _idsPanier = [];
  bool _isLoading = true;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _wishlistStream = _firestoreService.getProduitsStream();
    _initFuture = _initSouhaitsLocal();
    _initPanierLocal();
  }

  Future<void> _actualiser() async {
    setState(() {
      _isLoading = true;
    });
    await _initSouhaitsLocal();
    await _initPanierLocal();
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liste de souhaits mise à jour !'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _initSouhaitsLocal() async {
    await _souhaitsLocal.init();
    final ids = await _souhaitsLocal.getSouhaits();
    setState(() {
      _idsSouhaits = ids;
      _isLoading = false;
    });
  }

  Future<void> _initPanierLocal() async {
    await _panierLocal.init();
    final ids = await _panierLocal.getPanier();
    setState(() {
      _idsPanier = ids;
    });
  }

  Future<void> _toggleJeVeut(Produit produit) async {
    await _souhaitsLocal.retirerDesSouhaits(produit.idProduit);
    setState(() {
      _idsSouhaits.remove(produit.idProduit);
    });
    _messageReponse(
      '${produit.nomProduit} retiré de vos souhaits',
      isSuccess: false,
    );
  }

  Future<void> _addToCart(Produit produit) async {
    if (_idsPanier.contains(produit.idProduit)) {
      _messageReponse(
        '${produit.nomProduit} est déjà dans le panier.',
        isSuccess: false,
      );
      return;
    }
    await _panierLocal.ajouterAuPanier(produit.idProduit);
    setState(() {
      _idsPanier.add(produit.idProduit);
    });
    _messageReponse(
      '${produit.nomProduit} ajouté au panier',
      isSuccess: true,
      icon: Icons.add_shopping_cart_outlined,
    );

    if (_idsSouhaits.contains(produit.idProduit)) {
      await _souhaitsLocal.retirerDesSouhaits(produit.idProduit);
      setState(() {
        _idsSouhaits.remove(produit.idProduit);
      });
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

  
  Widget _buildProductCard(Produit produit) {
    final bool isInPanier = _idsPanier.contains(produit.idProduit);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      clipBehavior:
          Clip.antiAlias, // Assure que l'image respecte les bords arrondis
      child: InkWell(
        onTap:
            () => Navigator.pushNamed(context, '/details', arguments: produit),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Image
            AspectRatio(
              aspectRatio:
                  20 / 13, // Un ratio commun pour les images de produits
              child: _image(produit.img1),
            ),

            // Section Contenu (Titre, description et actions)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      produit.nomProduit.isNotEmpty
                          ? produit.nomProduit
                          : 'Produit sans nom',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      produit.descriptionCourte.isNotEmpty
                          ? produit.descriptionCourte
                          : 'Aucune description',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Section des actions (Boutons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bouton Ajouter au panier
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Styles.bleuvar.withOpacity(0.1),
                              foregroundColor: Styles.bleuvar,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed:
                                isInPanier ? null : () => _addToCart(produit),
                            child: Text(
                              isInPanier ? 'Déjà au panier' : 'Ajouter au panier',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bouton Retirer des souhaits
                        IconButton(
                          iconSize: 17,
                          onPressed: () => _toggleJeVeut(produit),
                          icon: const Icon(
                            FluentIcons.delete_24_regular,
                            color: Styles.erreur,
                            size: 20,
                          ),
                          tooltip: 'Retirer de la liste de souhaits',
                          style: IconButton.styleFrom(
                            backgroundColor: Styles.erreur.withOpacity(0.1),
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
    );
  }

  //Permet d'afficher les images des produits
  Widget _image(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return Container(
        color: Colors.grey[200],
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
      return CachedNetworkImage(
        imageUrl: imageData,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 50,
              ),
            ),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    }

    try {
      final Uint8List imageBytes = base64Decode(imageData);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.red,
                  size: 50,
                ),
              ),
            ),
      );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final screenWidth = MediaQuery.of(context).size.width;
     bool isWideScreen = screenWidth > 500;

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de la liste de souhaits...'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Styles.blanc,
          floatingActionButton: FloatingActionButton.extended(
            foregroundColor: Styles.bleu,
            backgroundColor: Styles.blanc,
            label: const Row(
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 10),
                Text(
                  'Actualiser',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            onPressed: _actualiser,
            tooltip: 'Rafraîchir la liste',
          ),
          body: Center(
            child: RefreshIndicator(
              onRefresh: _actualiser,
              child: StreamBuilder<List<Produit>>(
                stream: _wishlistStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _isLoading) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Aucun produit trouvé.'));
                  }
            
                  final produitsSouhaites =
                      (snapshot.data ?? [])
                          .where((p) => _idsSouhaits.contains(p.idProduit))
                          .toList();
            
                  if (produitsSouhaites.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Votre liste de souhaits est vide.\nLes produits ajoutés s\'afficherons ici',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }
            
                  //Afficher les cartes en fonction de la taille de l'écran
                  return Container(
                    constraints: isWideScreen ? BoxConstraints(maxWidth: 1000) : BoxConstraints(maxWidth: 280),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 290.0,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: produitsSouhaites.length,
                      // Appel du widget de cartes
                      itemBuilder:
                          (context, index) =>
                              _buildProductCard(produitsSouhaites[index]),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
