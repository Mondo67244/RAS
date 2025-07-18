import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/ecrans/client/pagesu/recents.dart';
import 'package:ras_app/services/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Souhaits extends StatefulWidget {
  const Souhaits({super.key});

  @override
  State<Souhaits> createState() => _SouhaitsState();
}

class _SouhaitsState extends State<Souhaits> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Produit>> _obtenirProduits;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('Initialisation de Souhaits, userId: $_userId');
    _initializeWishlist();
  }

  Future<void> _initializeWishlist() async {
    debugPrint('Initialisation de la liste de souhaits, userId: $_userId');
    if (_userId != null && _userId!.isNotEmpty) {
      await _syncLocalWishlistToFirestore();
      setState(() {
        _obtenirProduits = _firestoreService
            .listeSouhait(_userId!)
            .then((produits) {
              debugPrint('Produits depuis Firestore: ${produits.length}');
              return produits;
            })
            .catchError((e) {
              debugPrint('Erreur dans listeSouhait: $e');
              return <Produit>[];
            });
      });
    } else {
      setState(() {
        _obtenirProduits = _getLocalWishlist()
            .then((produits) {
              debugPrint(
                'Produits depuis SharedPreferences: ${produits.length}',
              );
              return produits;
            })
            .catchError((e) {
              debugPrint('Erreur dans _getLocalWishlist: $e');
              return <Produit>[];
            });
      });
    }
  }

  Future<List<Produit>> _getLocalWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString('local_wishlist');
      debugPrint('Contenu de local_wishlist: $wishlistJson');
      if (wishlistJson != null) {
        final List<dynamic> jsonList = jsonDecode(wishlistJson);
        return jsonList
            .where((item) => item is Map<String, dynamic>)
            .map((json) {
              try {
                final produit = Produit.fromJson(json as Map<String, dynamic>);
                debugPrint(
                  'Produit parsé: ${produit.nomProduit}, id: ${produit.idProduit}',
                );
                return produit;
              } catch (e) {
                debugPrint('Erreur lors du parsing du produit: $e');
                return null;
              }
            })
            .where((produit) => produit != null && produit.idProduit.isNotEmpty)
            .cast<Produit>()
            .toList();
      }
      debugPrint('Aucun produit dans local_wishlist');
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des souhaits locaux: $e');
      return [];
    }
  }

  Future<void> _syncLocalWishlistToFirestore() async {
    if (_userId == null || _userId!.isEmpty) {
      debugPrint('Synchronisation ignorée: userId null ou vide');
      return;
    }
    try {
      final localWishlist = await _getLocalWishlist();
      await _firestoreService.syncLocalWishlistToFirestore(
        _userId!,
        localWishlist,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_wishlist');
      debugPrint('Synchronisation des souhaits locaux vers Firestore terminée');
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation des souhaits: $e');
    }
  }

  Future<void> _toggleJeVeut(Produit produit) async {
    if (produit.idProduit.isEmpty) {
      debugPrint('Erreur: produit.idProduit est vide');
      _messageReponse('Produit invalide.', isSuccess: false);
      return;
    }
    try {
      if (_userId != null && _userId!.isNotEmpty) {
        await _firestoreService.removeFromWishlist(_userId!, produit.idProduit);
      } else {
        final localWishlist = await _getLocalWishlist();
        localWishlist.removeWhere((p) => p.idProduit == produit.idProduit);
        final prefs = await SharedPreferences.getInstance();
        final jsonList =
            localWishlist
                .where((p) => p.idProduit.isNotEmpty)
                .map((p) => p.toJson())
                .toList();
        await prefs.setString('local_wishlist', jsonEncode(jsonList));
        debugPrint('Produit retiré des souhaits locaux');
      }
      setState(() {
        _obtenirProduits =
            _userId != null && _userId!.isNotEmpty
                ? _firestoreService
                    .listeSouhait(_userId!)
                    .then((produits) {
                      debugPrint(
                        'Produits depuis Firestore après suppression: ${produits.length}',
                      );
                      return produits;
                    })
                    .catchError((e) {
                      debugPrint(
                        'Erreur dans listeSouhait après suppression: $e',
                      );
                      return <Produit>[];
                    })
                : _getLocalWishlist()
                    .then((produits) {
                      debugPrint(
                        'Produits depuis SharedPreferences après suppression: ${produits.length}',
                      );
                      return produits;
                    })
                    .catchError((e) {
                      debugPrint(
                        'Erreur dans _getLocalWishlist après suppression: $e',
                      );
                      return <Produit>[];
                    });
      });
      _messageReponse(
        '${produit.nomProduit} retiré de vos souhaits',
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('Erreur lors de la suppression du souhait: $e');
      _messageReponse(
        'Erreur lors de la suppression du souhait.',
        isSuccess: false,
      );
    }
  }

  Future<void> _addToCart(Produit produit) async {
    if (produit.idProduit.isEmpty) {
      debugPrint('Erreur: produit.idProduit est vide');
      _messageReponse('Produit invalide.', isSuccess: false);
      return;
    }
    try {
      if (_userId != null && _userId!.isNotEmpty) {
        await _firestoreService.addToCart(_userId!, produit);
        await _firestoreService.removeFromWishlist(_userId!, produit.idProduit);
      } else {
        final localCart = await _getLocalCart();
        final localWishlist = await _getLocalWishlist();
        if (!localCart.any((p) => p.idProduit == produit.idProduit)) {
          localCart.add(produit.copyWith(auPanier: true, jeVeut: false));
          localWishlist.removeWhere((p) => p.idProduit == produit.idProduit);
        }
        final prefs = await SharedPreferences.getInstance();
        final cartJsonList =
            localCart
                .where((p) => p.idProduit.isNotEmpty)
                .map((p) => p.toJson())
                .toList();
        final wishlistJsonList =
            localWishlist
                .where((p) => p.idProduit.isNotEmpty)
                .map((p) => p.toJson())
                .toList();
        await prefs.setString('local_cart', jsonEncode(cartJsonList));
        await prefs.setString('local_wishlist', jsonEncode(wishlistJsonList));
        debugPrint(
          'Produit ajouté au panier local et retiré des souhaits locaux',
        );
      }
      setState(() {
        _obtenirProduits =
            _userId != null && _userId!.isNotEmpty
                ? _firestoreService
                    .listeSouhait(_userId!)
                    .then((produits) {
                      debugPrint(
                        'Produits depuis Firestore après ajout au panier: ${produits.length}',
                      );
                      return produits;
                    })
                    .catchError((e) {
                      debugPrint(
                        'Erreur dans listeSouhait après ajout au panier: $e',
                      );
                      return <Produit>[];
                    })
                : _getLocalWishlist()
                    .then((produits) {
                      debugPrint(
                        'Produits depuis SharedPreferences après ajout au panier: ${produits.length}',
                      );
                      return produits;
                    })
                    .catchError((e) {
                      debugPrint(
                        'Erreur dans _getLocalWishlist après ajout au panier: $e',
                      );
                      return <Produit>[];
                    });
      });
      _messageReponse(
        '${produit.nomProduit} ajouté au panier',
        isSuccess: true,
        icon: Icons.add_shopping_cart_outlined,
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout au panier: $e');
      _messageReponse('Erreur lors de l\'ajout au panier.', isSuccess: false);
    }
  }

  Future<List<Produit>> _getLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('local_cart');
      debugPrint('Contenu de local_cart: $cartJson');
      if (cartJson != null) {
        final List<dynamic> jsonList = jsonDecode(cartJson);
        return jsonList
            .where((item) => item is Map<String, dynamic>)
            .map((json) => Produit.fromJson(json as Map<String, dynamic>))
            .where((produit) => produit.idProduit.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération du panier local: $e');
      return [];
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
      debugPrint('Erreur de décodage Base64: $e');
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 50),
        ),
      );
    }
  }

  Widget _buildActionButtons(Produit produit, double fontSize) {
    return SizedBox(
      width: 170,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
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
              onPressed: produit.enStock ? () => _toggleJeVeut(produit) : null,
              icon: const Icon(FluentIcons.delete_24_regular, size: 16),
              label: Text(
                'Supprimer',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    produit.enStock ? styles.bleu : Colors.grey.shade400,
                foregroundColor: Colors.white,
                elevation: 1,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: produit.enStock ? () => _addToCart(produit) : null,
              icon: const Icon(
                FluentIcons.shopping_bag_tag_24_regular,
                size: 16,
              ),
              label: Text(
                'Panier',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
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
                      SizedBox(
                        // width: 200,
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
                height: 128,
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
                      // width: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_buildActionButtons(produit, 10.0)],
                      ),
                    ),
                    Spacer()
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Produit produit) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1298;

    // final bool isWideScreen =
    if (produit.idProduit.isEmpty) {
      debugPrint('Produit ignoré dans _buildProductCard: idProduit vide');
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Utiliser un breakpoint plus grand pour la GridView pour une meilleure lisibilité
    final isWideScreen = screenWidth > 1298;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: isWideScreen ? BoxConstraints(maxWidth: 1200) : BoxConstraints(maxWidth: 400),
          child: FutureBuilder<List<Produit>>(
            future: _obtenirProduits,
            builder: (context, snapshot) {
              debugPrint(
                'État du FutureBuilder: ${snapshot.connectionState}, Données: ${snapshot.data?.length ?? 0}',
              );
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              if (snapshot.hasError) {
                debugPrint('Erreur FutureBuilder: ${snapshot.error}');
                return const Center(
                  child: Text('Erreur de chargement des données.'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                debugPrint('Aucun produit dans snapshot.data');
                return const Center(
                  child: Text('Aucun produit dans vos souhaits.'),
                );
              }
              final produitsSouhaites = snapshot.data!;
              debugPrint('Produits affichés: ${produitsSouhaites.length}');
              return isWideScreen
                  ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          // Ratio ajusté pour un layout horizontal
                          childAspectRatio: 1.9,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: produitsSouhaites.length,
                    itemBuilder:
                        (context, index) =>
                            _buildProductCard(produitsSouhaites[index]),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: produitsSouhaites.length,
                    itemBuilder:
                        (context, index) =>
                            _buildProductCard(produitsSouhaites[index]),
                  );
            },
          ),
        ),
      ),
    );
  }
  
}
