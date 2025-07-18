import 'dart:convert';
import 'package:ras_app/widgets/product_section.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/services/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ras_app/basicdata/produit_extension.dart';

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
  final ScrollController _populairesScrollController = ScrollController();
  final ScrollController _bureautiqueScrollController = ScrollController();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _produitsFuture = _firestoreService.getProduits();
    _initializeData();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _userId = user?.uid;
        _initializeData();
      });
    });
  }

  @override
  void dispose() {
    _populairesScrollController.dispose();
    _bureautiqueScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      if (_userId != null && _userId!.isNotEmpty) {
        await _syncLocalWishlistToFirestore();
        await _syncLocalCartToFirestore();
        final souhaits = await _firestoreService.listeSouhait(_userId!);
        final panier = await _firestoreService.getCart(_userId!);
        setState(() {
          _souhaits.clear();
          _paniers.clear();
          for (var produit in souhaits) {
            _souhaits.add(produit.idProduit);
          }
          for (var produit in panier) {
            _paniers.add(produit.idProduit);
          }
          debugPrint('Souhaits chargés: ${_souhaits.length}, Panier chargé: ${_paniers.length}');
        });
      } else {
        final localWishlist = await _getLocalWishlist();
        final localCart = await _getLocalCart();
        setState(() {
          _souhaits.clear();
          _paniers.clear();
          for (var produit in localWishlist) {
            if (produit.jeVeut && produit.idProduit.isNotEmpty) {
              _souhaits.add(produit.idProduit);
            }
          }
          for (var produit in localCart) {
            if (produit.auPanier && produit.idProduit.isNotEmpty) {
              _paniers.add(produit.idProduit);
            }
          }
          debugPrint('Souhaits locaux: ${_souhaits.length}, Panier local: ${_paniers.length}');
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des données: $e');
      _messageReponse('Erreur de chargement des données.', isSuccess: false);
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
            .map((json) => Produit.fromJson(json as Map<String, dynamic>))
            .where((produit) => produit.idProduit.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des souhaits locaux: $e');
      return [];
    }
  }

  Future<void> _saveLocalWishlist(List<Produit> produits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = produits
          .where((produit) => produit.idProduit.isNotEmpty)
          .map((produit) => produit.toJson())
          .toList();
      await prefs.setString('local_wishlist', jsonEncode(jsonList));
      debugPrint('Synchronisation locale des souhaits réussie: ${jsonList.length} produits');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des souhaits locaux: $e');
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

  Future<void> _saveLocalCart(List<Produit> produits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = produits
          .where((produit) => produit.idProduit.isNotEmpty)
          .map((produit) => produit.toJson())
          .toList();
      await prefs.setString('local_cart', jsonEncode(jsonList));
      debugPrint('Synchronisation locale du panier réussie: ${jsonList.length} produits');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du panier local: $e');
    }
  }

  Future<void> _syncLocalWishlistToFirestore() async {
    if (_userId == null || _userId!.isEmpty) {
      debugPrint('Synchronisation des souhaits ignorée: userId null ou vide');
      return;
    }
    try {
      final localWishlist = await _getLocalWishlist();
      await _firestoreService.syncLocalWishlistToFirestore(_userId!, localWishlist);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_wishlist');
      debugPrint('Synchronisation des souhaits vers Firestore réussie');
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation des souhaits: $e');
      _messageReponse('Erreur lors de la synchronisation des souhaits.', isSuccess: false);
    }
  }

  Future<void> _syncLocalCartToFirestore() async {
    if (_userId == null || _userId!.isEmpty) {
      debugPrint('Synchronisation du panier ignorée: userId null ou vide');
      return;
    }
    try {
      final localCart = await _getLocalCart();
      await _firestoreService.syncLocalCartToFirestore(_userId!, localCart);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_cart');
      debugPrint('Synchronisation du panier vers Firestore réussie');
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation du panier: $e');
      _messageReponse('Erreur lors de la synchronisation du panier.', isSuccess: false);
    }
  }

  Future<void> _toggleJeVeut(Produit produit) async {
    if (produit.idProduit.isEmpty) {
      debugPrint('Erreur: produit.idProduit est vide');
      _messageReponse('Produit invalide.', isSuccess: false);
      return;
    }
    final bool nouvelEtat = !_souhaits.contains(produit.idProduit);
    try {
      if (_userId != null && _userId!.isNotEmpty) {
        if (nouvelEtat) {
          await _firestoreService.ajoutListeSouhait(_userId!, produit);
          await _firestoreService.removeFromCart(_userId!, produit.idProduit);
        } else {
          await _firestoreService.removeFromWishlist(_userId!, produit.idProduit);
        }
      } else {
        final localWishlist = await _getLocalWishlist();
        final localCart = await _getLocalCart();
        if (nouvelEtat) {
          if (!localWishlist.any((p) => p.idProduit == produit.idProduit)) {
            localWishlist.add(produit.copyWith(jeVeut: true, auPanier: false));
          }
          localCart.removeWhere((p) => p.idProduit == produit.idProduit);
        } else {
          localWishlist.removeWhere((p) => p.idProduit == produit.idProduit);
        }
        await _saveLocalWishlist(localWishlist);
        await _saveLocalCart(localCart);
      }
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
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de JeVeut: $e');
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
    if (produit.idProduit.isEmpty) {
      debugPrint('Erreur: produit.idProduit est vide');
      _messageReponse('Produit invalide.', isSuccess: false);
      return;
    }
    final bool nouvelEtat = !_paniers.contains(produit.idProduit);
    try {
      if (_userId != null && _userId!.isNotEmpty) {
        if (nouvelEtat) {
          await _firestoreService.addToCart(_userId!, produit);
        } else {
          await _firestoreService.removeFromCart(_userId!, produit.idProduit);
        }
      }
      else {
        final localCart = await _getLocalCart();
        final localWishlist = await _getLocalWishlist();
        if (nouvelEtat) {
          if (!localCart.any((p) => p.idProduit == produit.idProduit)) {
            localCart.add(produit.copyWith(auPanier: true, jeVeut: false));
            localWishlist.removeWhere((p) => p.idProduit == produit.idProduit);
          }
        } else {
          localCart.removeWhere((p) => p.idProduit == produit.idProduit);
        }
        await _saveLocalCart(localCart);
        await _saveLocalWishlist(localWishlist);
      }
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
        icon: nouvelEtat
            ? Icons.add_shopping_cart_outlined
            : Icons.remove_shopping_cart_outlined,
      );
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du panier: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Produit>>(
        future: _produitsFuture,
        builder: (context, snapshot) {
          debugPrint('État du FutureBuilder: ${snapshot.connectionState}, Données: ${snapshot.data?.length ?? 0}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: styles.rouge),
            );
          }
          if (snapshot.hasError) {
            debugPrint('Erreur FutureBuilder: ${snapshot.error}');
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: TextStyle(color: styles.erreur, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            debugPrint('Aucun produit dans snapshot.data');
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
              debugPrint('isWideScreen: $isWideScreen, screenWidth: ${constraints.maxWidth}');
              return _contenu(produits, isWideScreen: isWideScreen);
            },
          );
        },
      ),
    );
  }

  Widget _imagesEntetes(String path, {required bool isWide}) {
    return SizedBox(
      height: isWide ? 150 : 100,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isWide
            ? CachedNetworkImage(
                imageUrl: path,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(
                  Icons.error_outline,
                  color: Colors.grey.shade400,
                  size: 60,
                ),
                fadeInDuration: const Duration(milliseconds: 300),
              )
            : Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }

  Widget _contenu(List<Produit> produits, {required bool isWideScreen}) {
    final produitsBureautique =
        produits.where((p) => p.sousCategorie == 'Bureautique').toList();
    final produitsReseau = produits.where((p) => p.sousCategorie == 'Réseau').toList();
    final produitsMobiles =
        produits.where((p) => p.sousCategorie == 'Appareils Mobiles').toList();
    final produitDivers = produits.where((p) => p.sousCategorie == 'Divers').toList();
    final produitsPopulaires =
        produits.where((p) => (int.tryParse(p.vues) ?? 0) > 15).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/PG2.png', isWide: isWideScreen),
          ProductSection(
            title: 'Articles Populaires',
            produits: produitsPopulaires,
            isWideScreen: isWideScreen,
            souhaits: _souhaits,
            paniers: _paniers,
            onToggleSouhait: _toggleJeVeut,
            onTogglePanier: _toggleAuPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/BG.png', isWide: isWideScreen),
          const SizedBox(height: 24),
          ProductSection(
            title: 'Appareils pour la Bureautique',
            produits: produitsBureautique,
            isWideScreen: isWideScreen,
            souhaits: _souhaits,
            paniers: _paniers,
            onToggleSouhait: _toggleJeVeut,
            onTogglePanier: _toggleAuPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/RG.png', isWide: isWideScreen),
          const SizedBox(height: 24),
          ProductSection(
            title: 'Appareils Réseau',
            produits: produitsReseau,
            isWideScreen: isWideScreen,
            souhaits: _souhaits,
            paniers: _paniers,
            onToggleSouhait: _toggleJeVeut,
            onTogglePanier: _toggleAuPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/EG2.png', isWide: isWideScreen),
          ProductSection(
            title: 'Appareils Mobiles',
            produits: produitsMobiles,
            isWideScreen: isWideScreen,
            souhaits: _souhaits,
            paniers: _paniers,
            onToggleSouhait: _toggleJeVeut,
            onTogglePanier: _toggleAuPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/AG.png', isWide: isWideScreen),
          ProductSection(
            title: 'Produit Divers',
            produits: produitDivers,
            isWideScreen: isWideScreen,
            souhaits: _souhaits,
            paniers: _paniers,
            onToggleSouhait: _toggleJeVeut,
            onTogglePanier: _toggleAuPanier,
          ),
        ],
      ),
    );
  }
}
