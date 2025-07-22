import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/services/base%20de%20donn%C3%A9es/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ras_app/services/ponts/pontSouhaitLocal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Souhaits extends StatefulWidget {
  const Souhaits({Key? key}) : super(key: key);

  @override
  State<Souhaits> createState() => SouhaitsState();
}

class SouhaitsState extends State<Souhaits> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Produit>> _obtenirProduits;
  String? _userId;

  // Liste des produits affichés (pour la recherche contextuelle)
  List<Produit> _produits = [];
  List<Produit> get produits => _produits;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('Initialisation de Souhaits, userId:  [4m_userId [0m');
    _initializeWishlist();
  }

  Future<void> _initializeWishlist() async {
    debugPrint('Initialisation de la liste de souhaits, userId:  [4m_userId [0m');
    if (_userId != null && _userId!.isNotEmpty) {
      await _syncLocalWishlistToFirestore();
      setState(() {
        _obtenirProduits = _firestoreService
            .listeSouhait(_userId!)
            .then((produits) {
              debugPrint('Produits depuis Firestore:  [4mproduits.length [0m');
              return produits;
            })
            .catchError((e) {
              debugPrint('Erreur dans listeSouhait:  [4me [0m');
              return <Produit>[];
            });
      });
    } else {
      setState(() {
        _obtenirProduits = _getLocalWishlistProducts();
      });
    }
  }

  // Récupère les produits souhaités locaux via LocalWishlistService
  Future<List<Produit>> _getLocalWishlistProducts() async {
    try {
      final ids = await LocalWishlistService.getProductIds();
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
            jeVeut: true,
            auPanier: false,
          );
        }));
      }
      return produits;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des produits souhaités locaux: $e');
      return [];
    }
  }

  // Synchronise la wishlist locale (IDs) vers Firestore si l'utilisateur se connecte
  Future<void> _syncLocalWishlistToFirestore() async {
    if (_userId == null || _userId!.isEmpty) {
      debugPrint('Synchronisation ignorée: userId null ou vide');
      return;
    }
    try {
      final ids = await LocalWishlistService.getProductIds();
      if (ids.isEmpty) return;
      List<Produit> produits = await _getLocalWishlistProducts();
      await _firestoreService.syncLocalWishlistToFirestore(
        _userId!,
        produits,
      );
      // Nettoie la liste locale après synchronisation
      await LocalWishlistService.clear();
      debugPrint('Synchronisation des souhaits locaux vers Firestore terminée');
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation des souhaits: $e');
    }
  }

  // Ajoute ou retire un produit des souhaits (local ou Firestore)
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
        final ids = await LocalWishlistService.getProductIds();
        final isAlreadyInWishlist = ids.contains(produit.idProduit);
        if (isAlreadyInWishlist) {
          await LocalWishlistService.removeProductId(produit.idProduit);
          debugPrint('Produit retiré des souhaits locaux');
          _messageReponse(
            '${produit.nomProduit} retiré de vos souhaits',
            isSuccess: true,
          );
        } else {
          await LocalWishlistService.addProductId(produit.idProduit);
          debugPrint('Produit ajouté aux souhaits locaux');
          _messageReponse(
            '${produit.nomProduit} ajouté à vos souhaits',
            isSuccess: true,
          );
        }
      }
      setState(() {
        _obtenirProduits = _userId != null && _userId!.isNotEmpty
            ? _firestoreService.listeSouhait(_userId!)
            : _getLocalWishlistProducts();
      });
    } catch (e) {
      debugPrint('Erreur lors de la suppression du souhait: $e');
      _messageReponse(
        'Erreur lors de la suppression du souhait.',
        isSuccess: false,
      );
    }
  }

  // Ajoute au panier (pour les non connectés, ne touche plus à la wishlist locale)
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
        // Ici, tu peux implémenter une logique similaire pour le panier local si besoin
        // (ex: LocalCartService), mais on ne touche plus à la wishlist locale
        debugPrint('Ajout au panier local à implémenter si besoin');
      }
      setState(() {
        _obtenirProduits =
            _userId != null && _userId!.isNotEmpty
                ? _firestoreService
                    .listeSouhait(_userId!)
                    .then((produits) {
                      debugPrint(
                        'Produits depuis Firestore après ajout au panier:  [4mproduits.length [0m',
                      );
                      return produits;
                    })
                    .catchError((e) {
                      debugPrint(
                        'Erreur dans listeSouhait après ajout au panier:  [4me [0m',
                      );
                      return <Produit>[];
                    })
                : _getLocalWishlistProducts()
                    .then((produits) {
                      debugPrint(
                        'Produits depuis LocalWishlistService après ajout au panier:  [4mproduits.length [0m',
                      );
                      return produits;
                    })
                    .catchError((e) {
                      debugPrint(
                        'Erreur dans _getLocalWishlist après ajout au panier:  [4me [0m',
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

  Widget _buildProductCard(Produit produit) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1298;

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
                    Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          const SizedBox(width: 5),
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
                _produits = [];
                return const Center(
                  child: Text('Aucun produit dans vos souhaits.'),
                );
              }
              final produitsSouhaites = snapshot.data!;
              _produits = produitsSouhaites;
              debugPrint('Produits affichés: ${produitsSouhaites.length}');
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
