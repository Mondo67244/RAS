import 'package:ras_app/widgets/SectionProduit.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/services/base%20de%20donn%C3%A9es/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ras_app/services/panier/panier_local.dart';

class Promo extends StatefulWidget {
  const Promo({Key? key}) : super(key: key);

  @override
  State<Promo> createState() => PromoState();
}

class PromoState extends State<Promo> {
  late Stream<List<Produit>> _produitsStream;
  final FirestoreService _firestoreService = FirestoreService();
  final PanierLocal _panierLocal = PanierLocal();
  List<String> _idsPanier = [];
  final Set<String> _souhaits = {};
  final Set<String> _paniers = {};
  final ScrollController _populairesScrollController = ScrollController();
  final ScrollController _bureautiqueScrollController = ScrollController();

  List<Produit> _produits = [];
  List<Produit> get produits => _produits;

  @override
  void initState() {
    super.initState();
    _produitsStream = _firestoreService.getProduitsStream();
    _initPanierLocal();
  }

  Future<void> _initPanierLocal() async {
    await _panierLocal.init();
    final ids = await _panierLocal.getPanier();
    setState(() {
      _idsPanier = ids;
    });
  }

  @override
  void dispose() {
    _populairesScrollController.dispose();
    _bureautiqueScrollController.dispose();
    super.dispose();
  }

  void _updateSets(List<Produit> produits) {
    _souhaits.clear();
    _paniers.clear();
    for (var produit in produits) {
      if (produit.jeVeut) _souhaits.add(produit.idProduit);
      if (produit.auPanier) _paniers.add(produit.idProduit);
    }
  }

  

  Future<void> _toggleAuPanier(Produit produit) async {
    if (_idsPanier.contains(produit.idProduit)) {
      await _panierLocal.retirerDuPanier(produit.idProduit);
      setState(() {
        _idsPanier.remove(produit.idProduit);
      });
      _messageReponse('${produit.nomProduit} retiré du panier', isSuccess: false, icon: Icons.remove_shopping_cart_outlined);
    } else {
      await _panierLocal.ajouterAuPanier(produit.idProduit);
      setState(() {
        _idsPanier.add(produit.idProduit);
      });
      _messageReponse('${produit.nomProduit} ajouté au panier', isSuccess: true, icon: Icons.add_shopping_cart_outlined);
    }
  }

  void _messageReponse(String message, {bool isSuccess = true, IconData? icon}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Produit>>(
        stream: _produitsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Styles.rouge),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: TextStyle(color: Styles.erreur, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
          _updateSets(produits);
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
            onTogglePanier: _toggleAuPanier,
            onTap: (Produit ) {  },
            idsPanier: _idsPanier,
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
            onTogglePanier: _toggleAuPanier,
            onTap: (Produit ) {  },
            idsPanier: _idsPanier,
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
            onTogglePanier: _toggleAuPanier,
            onTap: (Produit ) {  },
            idsPanier: _idsPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? Text('')
              : _imagesEntetes('assets/images/EG2.png', isWide: isWideScreen),
          ProductSection(
            title: 'Appareils Mobiles',
            produits: produitsMobiles,
            isWideScreen: isWideScreen,
            onTogglePanier: _toggleAuPanier,
            onTap: (Produit ) {  },
            idsPanier: _idsPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? Text('')
              : _imagesEntetes('assets/images/AG.png', isWide: isWideScreen),
          ProductSection(
            title: 'Produit Divers',
            produits: produitDivers,
            isWideScreen: isWideScreen,
            onTogglePanier: _toggleAuPanier,
            onTap: (Produit ) {  },
            idsPanier: _idsPanier,
          ),
        ],
      ),
    );
  }
}