import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/ecrans/client/pagesu/commandes.dart';
import 'package:ras_app/ecrans/client/pagesu/panier.dart';
import 'package:ras_app/ecrans/client/pagesu/promo.dart';
import 'package:ras_app/ecrans/client/pagesu/recents.dart';
import 'package:ras_app/ecrans/client/pagesu/resultats.dart';
import 'package:ras_app/ecrans/client/pagesu/souhaits.dart';
import 'package:ras_app/basicdata/produit.dart';

class Accueilu extends StatefulWidget {
  const Accueilu({super.key});

  @override
  State<Accueilu> createState() => _AccueiluState();
}

class _AccueiluState extends State<Accueilu> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isClick = false;

  // Clés globales
  final GlobalKey<RecentsState> _recentsKey = GlobalKey<RecentsState>();
  final GlobalKey<PromoState> _promoKey = GlobalKey<PromoState>();
  final GlobalKey<PanierState> _panierKey = GlobalKey<PanierState>();
  final GlobalKey<SouhaitsState> _souhaitsKey = GlobalKey<SouhaitsState>();

  // Variables d'état pour la recherche et les filtres
  String _searchText = '';
  String? _selectedCategory;
  RangeValues? _selectedPriceRange;
  bool _sortByPriceAsc = true;
  int _activeTabIndex = 0;
  List<Produit> _currentProducts = [];
  List<Produit> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleTabSelection();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _activeTabIndex = _tabController.index;
      _currentProducts = _getProductsForActiveTab();
      _applySearchAndFilters();
    });
  }

  List<Produit> _getProductsForActiveTab() {
    switch (_activeTabIndex) {
      case 0:
        return _recentsKey.currentState?.produits ?? [];
      case 1:
        return _promoKey.currentState?.produits ?? [];
      case 2:
        return _panierKey.currentState?.produits ?? [];
      case 3:
        return _souhaitsKey.currentState?.produits ?? [];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin/nouveau produit');
        },
        backgroundColor: const Color.fromARGB(255, 163, 14, 3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        foregroundColor: styles.blanc,
        backgroundColor: const Color.fromARGB(255, 163, 14, 3),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _isClick
              ? _barreRecherche(key: const ValueKey('searchBar'))
              : Image.asset(
                  'assets/images/kanjad.png',
                  key: const ValueKey('logo'),
                  width: 140,
                  height: 50,
                ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isClick ? Icons.close : Icons.search),
            tooltip: _isClick ? 'Fermer la recherche' : 'Rechercher',
            onPressed: () {
              setState(() {
                _isClick = !_isClick;
                // **CORRECTION : Si on ferme la recherche, on réinitialise TOUS les filtres**
                if (!_isClick) {
                  _searchText = '';
                  _selectedCategory = null; // Réinitialise la catégorie
                  _applySearchAndFilters();
                }
              });
            },
          ),
          
          // **CORRECTION : Le filtre de catégorie a été déplacé dans _barreRecherche**
          
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.white,
            child: TabBar(
              indicatorAnimation: TabIndicatorAnimation.elastic,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: true,
              indicatorColor: const Color.fromARGB(255, 141, 13, 4),
              controller: _tabController,
              labelColor: const Color.fromARGB(255, 163, 14, 3),
              tabs: const [
                Tab(child: Text('Accueil', style: TextStyle(fontWeight: FontWeight.bold))),
                Tab(child: Row(children: [Icon(FluentIcons.gift_card_24_filled), SizedBox(width: 5), Text('Promotions', style: TextStyle(fontWeight: FontWeight.bold))])),
                Tab(child: Row(children: [Icon(FluentIcons.shopping_bag_tag_24_filled), SizedBox(width: 5), Text('Mon Panier', style: TextStyle(fontWeight: FontWeight.bold))])),
                Tab(child: Row(children: [Icon(FluentIcons.book_star_24_filled), SizedBox(width: 5), Text('Mes Souhaits', style: TextStyle(fontWeight: FontWeight.bold))])),
                Tab(child: Row(children: [Icon(FluentIcons.receipt_bag_24_filled), SizedBox(width: 5), Text('Mes Commandes', style: TextStyle(fontWeight: FontWeight.bold))])),
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),
      drawer: const Drawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isClick ? Resultats() : Recents(key: _recentsKey),
          _isClick ? Resultats() : Promo(key: _promoKey),
          _isClick ? Resultats() : Panier(key: _panierKey),
          _isClick ? Resultats() : Souhaits(key: _souhaitsKey),
          _isClick ? Resultats() : const Commandes(),
        ],
      ),
    );
  }

  // Barre de recherche
  Widget _barreRecherche({required Key key}) {
    Color iconColor = const Color.fromARGB(255, 141, 13, 4);

    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: (value) {
          _searchText = value;
          _applySearchAndFilters();
        },
        autofocus: true,
        key: key,
        cursorColor: iconColor,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.white),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 0.5, color: Colors.white),
            borderRadius: BorderRadius.circular(25),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
          prefixIcon: Icon(Icons.search, color: iconColor),

          // **CORRECTION : Le DropdownButton est maintenant ici**
          suffixIcon: DropdownButton<String>(
            value: _selectedCategory,
            
            // Enlève la ligne de soulignement par défaut
            underline: Container(), 
            // Pour cacher l'icône de flèche par défaut du dropdown qui est redondante
            icon: const SizedBox.shrink(),
            dropdownColor: Colors.white,
            items: _currentProducts
                .map((p) => p.categorie)
                .toSet() // Uniques
                .map((cat) => DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat ?? '', style: const TextStyle(color: Colors.black)),
                    ))
                .toList(),
            onChanged: (value) {
              // On utilise un setState spécifique ici pour ne reconstruire que ce widget si possible
              // et non toute la page.
              setState(() {
                _selectedCategory = value;
                _applySearchAndFilters();
              });
            },
          ),
        ),
        style: const TextStyle(fontSize: 16),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  // Méthode de filtrage combinée
  void _applySearchAndFilters() {
    List<Produit> filtered = List.from(_currentProducts);

    // 1. Filtrer par texte de recherche
    if (_searchText.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.nomProduit.toLowerCase().contains(_searchText.toLowerCase()) ||
        p.description.toLowerCase().contains(_searchText.toLowerCase())
      ).toList();
    }

    // 2. Filtrer par catégorie
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.categorie == _selectedCategory).toList();
    }

    // 3. Filtrer par tranche de prix (logique conservée si besoin futur)
    if (_selectedPriceRange != null) {
      filtered = filtered.where((p) {
        final prix = double.tryParse(p.prix) ?? 0;
        return prix >= _selectedPriceRange!.start && prix <= _selectedPriceRange!.end;
      }).toList();
    }

    // 4. Trier la liste filtrée (logique conservée si besoin futur)
    filtered.sort((a, b) {
      final prixA = double.tryParse(a.prix) ?? 0;
      final prixB = double.tryParse(b.prix) ?? 0;
      return _sortByPriceAsc ? prixA.compareTo(prixB) : prixB.compareTo(prixA);
    });

    setState(() {
      _searchResults = filtered;
    });
  }
}