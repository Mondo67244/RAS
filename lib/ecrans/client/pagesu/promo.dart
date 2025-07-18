import 'dart:convert';
import 'package:ras_app/widgets/product_section.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/services/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Promo extends StatefulWidget {
  const Promo({super.key});

  @override
  State<Promo> createState() => _PromoState();
}

class _PromoState extends State<Promo> {
  late Future<List<Produit>> _produitsFuture;
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _souhaits = {};
  final Set<String> _paniers = {};
  final ScrollController _populairesScrollController = ScrollController();
  final ScrollController _bureautiqueScrollController = ScrollController();
  

  @override
  void initState() {
    super.initState();
    _produitsFuture = _firestoreService.getProduits();
    _chargerDonneesInitiales();
  }

@override
  void dispose() {
    _populairesScrollController.dispose();
    _bureautiqueScrollController.dispose();
    super.dispose();
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

  Widget _imagesEntetes(String path, {required bool isWide}) {
    return SizedBox(
      height: isWide ? 150 : 100,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child:
            isWide
                ? CachedNetworkImage(
                  imageUrl: path,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) => Icon(
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
        produits.where((p) => p.sousCategorie == 'Bureautique' && p.enPromo == true).toList();
    final produitsReseau =
        produits.where((p) => p.sousCategorie == 'Réseau' && p.enPromo == true).toList();
    final produitsMobiles =
        produits.where((p) => p.sousCategorie == 'Appareils Mobiles' && p.enPromo == true).toList();
    final produitDivers = produits.where((p) => p.sousCategorie == 'Divers' && p.enPromo == true).toList();
    final produitsPopulaires =
        produits.where((p) => (int.tryParse(p.vues) ?? 0) > 15 && p.enPromo == true).toList();


    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isWideScreen
              ? Text('')
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
              ? Text('')
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
              ? Text('')
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
              ? Text('')
              : _imagesEntetes('assets/images/EG2.png', isWide: isWideScreen),
          //Section appareils mobiles
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
              ? Text('')
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