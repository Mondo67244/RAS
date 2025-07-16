import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Assurez-vous que ces imports pointent vers les bons fichiers dans votre projet
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/services/lienbd.dart';

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
    // Écouter les changements d'état de connexion
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) { // Vérifier si le widget est toujours dans l'arbre
        setState(() {
          _userId = user?.uid;
          _initializeWishlist();
        });
      }
    });
    // Initialisation initiale
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _initializeWishlist();
  }

  Future<void> _initializeWishlist() async {
    if (_userId != null) {
      // Si l'utilisateur est connecté, synchroniser le local puis charger depuis Firestore
      await _syncLocalWishlistToFirestore();
      setState(() {
        _obtenirProduits = _firestoreService.listeSouhait(_userId!);
      });
    } else {
      // Si non connecté, charger depuis le local
      setState(() {
        _obtenirProduits = _getLocalWishlist();
      });
    }
  }

  // --- Méthodes de gestion de la liste de souhaits locale (SharedPreferences) ---

  Future<List<Produit>> _getLocalWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString('local_wishlist');
      if (wishlistJson != null) {
        final List<dynamic> jsonList = jsonDecode(wishlistJson);
        return jsonList
            .whereType<Map<String, dynamic>>()
            .map((json) => Produit.fromJson(json))
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
      final jsonList = produits.map((produit) => produit.toJson()).toList();
      await prefs.setString('local_wishlist', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des souhaits locaux: $e');
    }
  }

  Future<void> _syncLocalWishlistToFirestore() async {
    if (_userId == null) return;
    try {
      final localWishlist = await _getLocalWishlist();
      if (localWishlist.isNotEmpty) {
        await _firestoreService.syncLocalWishlistToFirestore(_userId!, localWishlist);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('local_wishlist'); // Nettoyer la liste locale après synchronisation
        debugPrint('Synchronisation des souhaits vers Firestore réussie');
      }
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation des souhaits: $e');
    }
  }

  // --- Méthodes de gestion du panier (pour l'ajout depuis les souhaits) ---

  Future<List<Produit>> _getLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('local_cart');
      if (cartJson != null) {
        final List<dynamic> jsonList = jsonDecode(cartJson);
        return jsonList
            .whereType<Map<String, dynamic>>()
            .map((json) => Produit.fromJson(json))
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
      final jsonList = produits.map((produit) => produit.toJson()).toList();
      await prefs.setString('local_cart', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du panier local: $e');
    }
  }
  
  // --- Actions sur les produits ---

  Future<void> _addToCart(Produit produit) async {
    try {
      if (_userId != null) {
        // Logique pour l'utilisateur connecté
        await _firestoreService.addToCart(_userId!, produit);
        await _firestoreService.removeFromWishlist(_userId!, produit.idProduit);
      } else {
        // Logique pour l'utilisateur non connecté
        final localWishlist = await _getLocalWishlist();
        final localCart = await _getLocalCart();
        
        localWishlist.removeWhere((p) => p.idProduit == produit.idProduit);
        
        if (!localCart.any((p) => p.idProduit == produit.idProduit)) {
          localCart.add(produit.copyWith(auPanier: true, jeVeut: false));
        }
        
        await _saveLocalWishlist(localWishlist);
        await _saveLocalCart(localCart);
      }
      
      // Rafraîchir l'interface
      _initializeWishlist();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit ajouté au panier et retiré des souhaits')),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout au panier: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout au panier : $e')),
        );
      }
    }
  }

  Future<void> _removeFromWishlist(Produit produit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment retirer ce produit de vos souhaits ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (_userId != null) {
        await _firestoreService.removeFromWishlist(_userId!, produit.idProduit);
      } else {
        final localWishlist = await _getLocalWishlist();
        localWishlist.removeWhere((p) => p.idProduit == produit.idProduit);
        await _saveLocalWishlist(localWishlist);
      }
      
      // Rafraîchir l'interface
      _initializeWishlist();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit retiré des souhaits')),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du retrait des souhaits: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du retrait : $e')),
        );
      }
    }
  }
  
  // --- Construction de l'interface (Build) ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Utiliser un breakpoint plus grand pour la GridView pour une meilleure lisibilité
    final isWideScreen = screenWidth > 720;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: FutureBuilder<List<Produit>>(
            future: _obtenirProduits,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }
              if (snapshot.hasError) {
                debugPrint('Erreur FutureBuilder: ${snapshot.error}');
                return const Center(child: Text('Erreur de chargement des données.'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucun produit dans vos souhaits.'));
              }

              final produitsSouhaites = snapshot.data!;

              return isWideScreen
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        // Ratio ajusté pour un layout horizontal
                        childAspectRatio: 3.0, 
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: produitsSouhaites.length,
                      itemBuilder: (context, index) => _buildProductCard(produitsSouhaites[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: produitsSouhaites.length,
                      itemBuilder: (context, index) => _buildProductCard(produitsSouhaites[index]),
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Produit produit) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      clipBehavior: Clip.antiAlias, // Assure que l'InkWell ne dépasse pas les coins arrondis
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/details', arguments: produit),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          // LayoutBuilder permet d'adapter le contenu à la taille de la carte
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth;

              // Tailles dynamiques basées sur la largeur de la carte
              // clamp() assure que les tailles restent dans une fourchette raisonnable
              final imageSize = (cardWidth * 0.25).clamp(80.0, 140.0);
              final titleFontSize = (cardWidth * 0.045).clamp(14.0, 18.0);
              final descriptionFontSize = (cardWidth * 0.035).clamp(12.0, 15.0);
              final buttonFontSize = (cardWidth * 0.03).clamp(11.0, 14.0);
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageContainer(produit.img1, imageSize, imageSize),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produit.nomProduit,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          produit.descriptionCourte,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: descriptionFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                        // Spacer pousse les éléments suivants vers le bas de la colonne
                        const Spacer(),
                        _buildActionButtons(produit, buttonFontSize),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Produit produit, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Utilisation de Flexible pour éviter les 'overflows' si les boutons sont trop larges
        Flexible(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text('Retirer', style: TextStyle(fontSize: fontSize)),
            onPressed: () => _removeFromWishlist(produit),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              backgroundColor: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: Text('Au panier', style: TextStyle(fontSize: fontSize)),
            // Désactiver le bouton si le produit n'est pas en stock
            onPressed: produit.enStock ? () => _addToCart(produit) : null,
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContainer(String imageData, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _loadImage(imageData),
      ),
    );
  }

  Widget _loadImage(String imageData) {
    if (imageData.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
        ),
      );
    }

    if (imageData.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageData,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator.adaptive()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error_outline, color: Colors.grey, size: 40),
        ),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    }

    try {
      // Expression régulière plus tolérante pour le padding base64
      final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
      if (!base64Regex.hasMatch(imageData)) {
        throw const FormatException('Chaîne Base64 invalide');
      }

      // S'assurer que le padding est correct
      String paddedData = imageData;
      if (paddedData.length % 4 != 0) {
        paddedData += '=' * (4 - (paddedData.length % 4));
      }
      
      final Uint8List imageBytes = base64Decode(paddedData);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
        ),
      );
    } catch (e) {
      debugPrint('Erreur de décodage Base64: $e');
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
        ),
      );
    }
  }
}

// L'extension est utile pour créer des copies d'objets avec certaines valeurs modifiées.
// Aucune modification n'est nécessaire ici.
extension ProduitExtension on Produit {
  Produit copyWith({
    String? descriptionCourte,
    String? sousCategorie,
    bool? enPromo,
    bool? cash,
    bool? electronique,
    String? quantite,
    bool? livrable,
    Timestamp? createdAt,
    bool? enStock,
    String? img1,
    String? img2,
    String? img3,
    bool? auPanier,
    bool? jeVeut,
    String? idProduit,
    String? nomProduit,
    String? description,
    String? prix,
    String? vues,
    String? modele,
    String? marque,
    String? categorie,
    String? type,
  }) {
    return Produit(
      descriptionCourte: descriptionCourte ?? this.descriptionCourte,
      sousCategorie: sousCategorie ?? this.sousCategorie,
      enPromo: enPromo ?? this.enPromo,
      cash: cash ?? this.cash,
      electronique: electronique ?? this.electronique,
      quantite: quantite ?? this.quantite,
      livrable: livrable ?? this.livrable,
      createdAt: createdAt ?? this.createdAt,
      enStock: enStock ?? this.enStock,
      img1: img1 ?? this.img1,
      img2: img2 ?? this.img2,
      img3: img3 ?? this.img3,
      auPanier: auPanier ?? this.auPanier,
      jeVeut: jeVeut ?? this.jeVeut,
      idProduit: idProduit ?? this.idProduit,
      nomProduit: nomProduit ?? this.nomProduit,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      vues: vues ?? this.vues,
      modele: modele ?? this.modele,
      marque: marque ?? this.marque,
      categorie: categorie ?? this.categorie,
      type: type ?? this.type,
    );
  }
}