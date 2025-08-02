import 'package:RAS/widgets/SectionProduit.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/services/base%20de%20donn%C3%A9es/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:RAS/services/panier/panier_local.dart';


class Recents extends StatefulWidget {
  const Recents({Key? key}) : super(key: key);

  @override
  State<Recents> createState() => RecentsState();
}

class RecentsState extends State<Recents> {
  late Stream<List<Produit>> _produitsStream;
  final FirestoreService _firestoreService = FirestoreService();
  final PanierLocal _panierLocal = PanierLocal();
  List<String> _idsPanier = [];
  final ScrollController _populairesScrollController = ScrollController();
  final ScrollController _bureautiqueScrollController = ScrollController();

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

  Future<void> _refreshData() async {
    setState(() {
      _produitsStream = _firestoreService.getProduitsStream();
      _initPanierLocal();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Styles.bleu,
          content: Text('Page actualisée !'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final Offset offset = renderBox.localToGlobal(Offset.zero);
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(offset.dx, offset.dy - 120, offset.dx + renderBox.size.width, offset.dy),
                items: [
                  PopupMenuItem(
                    value: 'rechercher',
                    child: Row(
                      children: const [
                        Icon(Icons.search),
                        SizedBox(width: 10),
                        Text('Rechercher'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'actualiser',
                    child: Row(
                      children: const [
                        Icon(Icons.refresh),
                        SizedBox(width: 10),
                        Text('Actualiser'),
                      ],
                    ),
                  ),
                ],
              ).then((value) {
                if (value == 'rechercher') {
                  Navigator.pushNamed(context, '/utilisateur/recherche');
                } else if (value == 'actualiser') {
                  _refreshData();
                }
              });
            },
            backgroundColor: const Color.fromARGB(255, 163, 14, 3),
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Options',
          );
        },
      ),
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
    final produitsAccessoires =
        produits.where((p) => p.sousCategorie == 'Accessoires').toList();

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
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(context, '/utilisateur/produit/details', arguments: produit);
            },
            idsPanier: _idsPanier,
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
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(context, '/utilisateur/produit/details', arguments: produit);
            },
            idsPanier: _idsPanier,
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
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(context, '/utilisateur/produit/details', arguments: produit);
            },
            idsPanier: _idsPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
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
              ? const Text('')
              : _imagesEntetes('assets/images/AG.png', isWide: isWideScreen),
          ProductSection(
            title: 'Accessoires',
            produits: produitsAccessoires,
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