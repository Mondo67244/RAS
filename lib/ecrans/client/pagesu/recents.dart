import 'package:ras_app/widgets/SectionProduit.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/services/base%20de%20donn%C3%A9es/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ras_app/services/ponts/pontSouhaitLocal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ras_app/services/ponts/pontPanierLocal.dart';

class Recents extends StatefulWidget {
  const Recents({Key? key}) : super(key: key);

  @override
  State<Recents> createState() => RecentsState();
}

class RecentsState extends State<Recents> {
  late Future<List<Produit>> _produitsFuture;
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _souhaits = {};
  final Set<String> _paniers = {};
  final ScrollController _populairesScrollController = ScrollController();
  final ScrollController _bureautiqueScrollController = ScrollController();
  String? _userId;

  // Liste des produits affichés (pour la recherche contextuelle)
  List<Produit> _produits = [];
  List<Produit> get produits => _produits;

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

  /// Initialise les données de souhaits et panier, localement ou via Firestore
  Future<void> _initializeData() async {
    try {
      if (_userId != null && _userId!.isNotEmpty) {
        // Utilisateur connecté : synchronisation avec Firestore
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
        // Utilisateur non connecté : récupération des souhaits et panier locaux
        final wishlistIds = await LocalWishlistService.getProductIds();
        final cartIds = await LocalCartService.getProductIds();
        final produits = await _getLocalWishlistProducts(wishlistIds);
        setState(() {
          _souhaits.clear();
          _paniers.clear();
          for (var produit in produits) {
            _souhaits.add(produit.idProduit);
          }
          for (var id in cartIds) {
            _paniers.add(id);
          }
          debugPrint('Souhaits locaux: ${_souhaits.length}, Panier local: ${_paniers.length}');
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des données: $e');
      _messageReponse('Erreur de chargement des données.', isSuccess: false);
    }
  }

  /// Récupère les produits de la liste de souhaits locale depuis Firestore
  Future<List<Produit>> _getLocalWishlistProducts(List<String> ids) async {
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
  }

  /// Synchronise la liste de souhaits locale avec Firestore
  Future<void> _syncLocalWishlistToFirestore() async {
    if (_userId == null || _userId!.isEmpty) {
      debugPrint('Synchronisation des souhaits ignorée: userId null ou vide');
      return;
    }
    try {
      final localWishlist = await LocalWishlistService.getProductIds();
      await _firestoreService.syncLocalWishlistToFirestore(_userId!, localWishlist.cast<Produit>());
      await LocalWishlistService.clear();
      debugPrint('Synchronisation des souhaits vers Firestore réussie');
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation des souhaits: $e');
      _messageReponse('Erreur lors de la synchronisation des souhaits.', isSuccess: false);
    }
  }

  /// Synchronise le panier local avec Firestore
  Future<void> _syncLocalCartToFirestore() async {
    if (_userId == null || _userId!.isEmpty) {
      debugPrint('Synchronisation du panier ignorée: userId null ou vide');
      return;
    }
    try {
      final localCart = await LocalCartService.getProductIds();
      await _firestoreService.syncLocalCartToFirestore(_userId!, localCart.cast<Produit>());
      await LocalCartService.clear();
      debugPrint('Synchronisation du panier vers Firestore réussie');
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation du panier: $e');
      _messageReponse('Erreur lors de la synchronisation du panier.', isSuccess: false);
    }
  }

  /// Bascule l'état d'un produit dans la liste de souhaits (ajoute/retire)
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
          // Ajout à la liste de souhaits et retrait du panier
          await _firestoreService.ajoutListeSouhait(_userId!, produit);
          await _firestoreService.removeFromCart(_userId!, produit.idProduit);
        } else {
          // Retrait de la liste de souhaits
          await _firestoreService.removeFromWishlist(_userId!, produit.idProduit);
        }
      } else {
        // Gestion locale
        if (nouvelEtat) {
          await LocalWishlistService.addProductId(produit.idProduit);
          await LocalCartService.removeProductId(produit.idProduit);
        } else {
          await LocalWishlistService.removeProductId(produit.idProduit);
        }
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

  /// Bascule l'état d'un produit dans le panier (ajoute/retire)
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
          // Ajout au panier et retrait de la liste de souhaits
          await _firestoreService.addToCart(_userId!, produit);
          await _firestoreService.removeFromWishlist(_userId!, produit.idProduit);
        } else {
          // Retrait du panier
          await _firestoreService.removeFromCart(_userId!, produit.idProduit);
        }
      } else {
        // Gestion locale
        if (nouvelEtat) {
          await LocalCartService.addProductId(produit.idProduit);
          await LocalWishlistService.removeProductId(produit.idProduit); // Retire de la liste de souhaits
        } else {
          await LocalCartService.removeProductId(produit.idProduit);
        }
      }
      setState(() {
        if (nouvelEtat) {
          _paniers.add(produit.idProduit);
          _souhaits.remove(produit.idProduit); // Retire de la liste de souhaits localement
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

  /// Affiche un message de confirmation ou d'erreur
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
      backgroundColor: Colors.white,
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
            _produits = [];
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
          _produits = produits;
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideScreen = constraints.maxWidth > 600;
              debugPrint('isWideScreen: $isWideScreen, screenWidth: ${constraints.maxWidth}');
              return Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 900),
                  child: _contenu(produits, isWideScreen: isWideScreen)),
              );
            },
          );
        },
      ),
    );
  }

  /// Construit l'en-tête avec des images (locales ou réseau)
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

  /// Construit le contenu principal avec les  sections de produits
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
            title: 'Les Articles Populaires',
            produits: produitsPopulaires,
            isWideScreen: isWideScreen,
            souhaits: _souhaits,
            paniers: _paniers,
            onToggleSouhait: _toggleJeVeut,
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(context, '/details', arguments: produit).then((_) => _initializeData());
            },
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/BG.png', isWide: isWideScreen),
          const SizedBox(height: 24),
          ProductSection(
            title: 'Appareils de Bureautique',
            produits: produitsBureautique,
            isWideScreen: isWideScreen,
            souhaits: _souhaits,
            paniers: _paniers,
            onToggleSouhait: _toggleJeVeut,
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(context, '/details', arguments: produit).then((_) => _initializeData());
            },
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
            onTap: (produit) {
              Navigator.pushNamed(context, '/details', arguments: produit).then((_) => _initializeData());
            },
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
            onTap: (produit) {
              Navigator.pushNamed(context, '/details', arguments: produit).then((_) => _initializeData());
            },
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
            onTap: (produit) {
              Navigator.pushNamed(context, '/details', arguments: produit).then((_) => _initializeData());
            },
          ),
        ],
      ),
    );
  }

}