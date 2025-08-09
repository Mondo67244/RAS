import 'package:RAS/widgets/SectionProduit.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:RAS/services/panier/panier_local.dart';

class Promo extends StatefulWidget {
  const Promo({super.key});

  @override
  State<Promo> createState() => PromoState();
}

class PromoState extends State<Promo> with AutomaticKeepAliveClientMixin<Promo> {
  late Stream<List<Produit>> _produitsStream;
  final FirestoreService _firestoreService = FirestoreService();
  final PanierLocal _panierLocal = PanierLocal();
  List<String> _idsPanier = [];
  List<Produit> _produits = [];
  List<Produit> get produits => _produits;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _produitsStream = _firestoreService.getProduitsStream();
    _initPanierLocal();
  }

  Future<void> _initPanierLocal() async {
    await _panierLocal.init();
    final ids = await _panierLocal.getPanier();
    if (mounted) {
      setState(() {
        _idsPanier = ids;
      });
    }
  }

  Future<void> _toggleAuPanier(Produit produit) async {
    try {
      if (_idsPanier.contains(produit.idProduit)) {
        await _panierLocal.retirerDuPanier(produit.idProduit);
        if (mounted) {
          setState(() {
            _idsPanier.remove(produit.idProduit);
          });
        }
      } else {
        await _panierLocal.ajouterAuPanier(produit.idProduit);
        if (mounted) {
          setState(() {
            _idsPanier.add(produit.idProduit);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isWideScreen = MediaQuery.of(context).size.width > 700;
    
    return Scaffold(
      backgroundColor: Colors.white,
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
          
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideScreen = constraints.maxWidth > 600;
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 950),
                  child: _contenu(produits, isWideScreen: isWideScreen)),
              );
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
            title: 'Les Articles Populaires',
            produits: produitsPopulaires,
            isWideScreen: isWideScreen,
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(context, '/utilisateur/produit/details', arguments: produit);
            },
            idsPanier: _idsPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? Text('')
              : _imagesEntetes('assets/images/BG.png', isWide: isWideScreen),
          const SizedBox(height: 24),
          ProductSection(
            title: 'Appareils de Bureautique',
            produits: produitsBureautique,
            isWideScreen: isWideScreen,
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(context, '/utilisateur/produit/details', arguments: produit);
            },
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
            onTap: (produit) {
              Navigator.pushNamed(context, '/utilisateur/produit/details', arguments: produit);
            },
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
            onTap: (produit) {
              Navigator.pushNamed(context, '/utilisateur/produit/details', arguments: produit);
            },
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
            onTap: (produit) {
              Navigator.pushNamed(context, '/utilisateur/produit/details', arguments: produit);
            },
            idsPanier: _idsPanier,
          ),
        ],
      ),
    );
  }
}