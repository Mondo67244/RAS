import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/services/base%20de%20donn%C3%A9es/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/services/souhaits/souhaits_local.dart';
import 'package:ras_app/services/panier/panier_local.dart';

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

  @override
  void initState() {
    super.initState();
    _wishlistStream = _firestoreService.getProduitsStream();
    _initSouhaitsLocal();
    _initPanierLocal();
  }

  Future<void> _initSouhaitsLocal() async {
    await _souhaitsLocal.init();
    final ids = await _souhaitsLocal.getSouhaits();
    setState(() {
      _idsSouhaits = ids;
    });
    print('SouhaitsLocal IDs: $_idsSouhaits'); // ADDED LOG
  }

  Future<void> _initPanierLocal() async {
    await _panierLocal.init();
    final ids = await _panierLocal.getPanier();
    setState(() {
      _idsPanier = ids;
    });
  }

  Future<void> _toggleJeVeut(Produit produit) async {
    if (_idsSouhaits.contains(produit.idProduit)) {
      await _souhaitsLocal.retirerDesSouhaits(produit.idProduit);
      setState(() {
        _idsSouhaits.remove(produit.idProduit);
      });
      _messageReponse(
        '${produit.nomProduit} retiré de vos souhaits',
        isSuccess: false,
      );
    } else {
      await _souhaitsLocal.ajouterAuxSouhaits(produit.idProduit);
      setState(() {
        _idsSouhaits.add(produit.idProduit);
      });
      _messageReponse(
        '${produit.nomProduit} ajouté à vos souhaits',
        isSuccess: true,
      );
    }
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

    // Remove from wishlist if it was there
    if (_idsSouhaits.contains(produit.idProduit)) {
      await _souhaitsLocal.retirerDesSouhaits(produit.idProduit);
      setState(() {
        _idsSouhaits.remove(produit.idProduit);
      });
      _messageReponse(
        '${produit.nomProduit} retiré de vos souhaits',
        isSuccess: false,
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
                height: 130,
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
    final bool isInPanier = _idsPanier.contains(produit.idProduit);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isInPanier ? Colors.blue.shade50 : Colors.white,
            foregroundColor: isInPanier ? Colors.blue : Styles.bleuvar,
            side: BorderSide(color: Styles.bleuvar, width: 1.2),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isInPanier ? null : () => _addToCart(produit),
          
          label: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(isInPanier ? 'Ajouté' : 'Ajouter au panier'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _toggleJeVeut(produit),
          icon: Icon(
            FluentIcons.delete_12_filled,
            color: Styles.erreur,
            size: 16,
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
          placeholder:
              (context, url) =>
                  const Center(child: CircularProgressIndicator()),
          errorWidget:
              (context, url, error) =>
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
                  ? const BoxConstraints(maxWidth: 1200)
                  : const BoxConstraints(maxWidth: 400),
          child: StreamBuilder<List<Produit>>(
            stream: _wishlistStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              if (snapshot.hasError) {
                print('Firestore Stream Error: ${snapshot.error}'); // ADDED LOG
                return const Center(
                  child: Text('Erreur de chargement des souhaits.'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                print('Firestore Stream: No data or empty.'); // ADDED LOG
                return const Center(
                  child: Text('Votre liste de souhaits est vide.'),
                );
              }

              print(
                'Firestore Stream Data received. Total products: ${snapshot.data!.length}',
              ); // ADDED LOG
              for (var p in snapshot.data!) {
                print('Firestore Product ID: ${p.idProduit}'); // ADDED LOG
              }

              final produitsSouhaites =
                  (snapshot.data ?? [])
                      .where((p) => _idsSouhaits.contains(p.idProduit))
                      .toList();

              print(
                'Filtered Wishlist Products Count: ${produitsSouhaites.length}',
              ); // ADDED LOG
              for (var p in produitsSouhaites) {
                print(
                  'Filtered Wishlist Product ID: ${p.idProduit}',
                ); // ADDED LOG
              }
              if (produitsSouhaites.isEmpty) {
                return const Center(
                  child: Text('Votre liste de souhaits est vide.'),
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
                    itemCount: produitsSouhaites.length,
                    itemBuilder:
                        (context, index) =>
                            _carteEquipement(produitsSouhaites[index]),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: produitsSouhaites.length,
                    itemBuilder:
                        (context, index) =>
                            _carteEquipement(produitsSouhaites[index]),
                  );
            },
          ),
        ),
      ),
    );
  }
}
