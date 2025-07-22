import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/ecrans/client/pagesu/commandes.dart';
import 'package:ras_app/ecrans/client/pagesu/panier.dart';
import 'package:ras_app/ecrans/client/pagesu/promo.dart';
import 'package:ras_app/ecrans/client/pagesu/recents.dart';
import 'package:ras_app/ecrans/client/pagesu/resultats.dart';
import 'package:ras_app/ecrans/client/pagesu/souhaits.dart';

class Accueilu extends StatefulWidget {
  const Accueilu({super.key});

  @override
  State<Accueilu> createState() => _AccueiluState();
}

class _AccueiluState extends State<Accueilu> with TickerProviderStateMixin {
  TabController? _tabController;
  int _selectedIndex = 0;
  bool _isClick = false;

  final List<Widget> _pages = [
    Recents(),
    Promo(),
    Panier(),
    Souhaits(),
    const Commandes(),
  ];

  final List<Tab> _tabs = const [
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.home_more_20_filled),
          const SizedBox(width: 3),
          Text('Accueil'),
        ],
      ),
    ),
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.gift_card_24_filled),
          const SizedBox(width: 3),
          Text('Promotions'),
        ],
      ),
    ),
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.shopping_bag_tag_24_filled),
          const SizedBox(width: 3),
          Text('Mon Panier'),
        ],
      ),
    ),
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.class_20_filled),
          const SizedBox(width: 3),
          Text('Liste de Souhaits'),
        ],
      ),
    ),
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.receipt_bag_24_filled),
          const SizedBox(width: 3),
          Text('Commandes'),
        ],
      ),
    ),
  ];

  void _onTapNav(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController?.index = index;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 700;

    // Initialisation conditionnelle du TabController
    if (isLargeScreen && _tabController == null) {
      _tabController = TabController(length: _pages.length, vsync: this);
    }

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
          child:
              _isClick
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/kanjad.png',
                        key: const ValueKey('logo'),
                        width: 140,
                        height: 50,
                      ),
                      Transform.translate(
                        offset: const Offset(-20, 12),
                        child: const Text(
                          'Recherche',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
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
              });
            },
          ),
        ],
        centerTitle: true,
        bottom:
            isLargeScreen
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Container(
                    
                    color: Colors.white,
                    width: double.infinity,
                    child: Center(
                      child: SizedBox(
                        width: 755,
                        child: TabBar(
                          dividerHeight: 0,
                          controller: _tabController,
                          isScrollable: false,
                          
                          indicatorColor: styles.rouge,
                          labelColor: styles.rouge,
                          unselectedLabelColor: Colors.grey[600],
                          tabs: _tabs,
                        ),
                      ),
                    ),
                  ),
                )
                : null,
      ),

      drawer: const Drawer(),

      body:
          _isClick
              ? Resultats()
              : isLargeScreen
              ? TabBarView(controller: _tabController!, children: _pages)
              : IndexedStack(index: _selectedIndex, children: _pages),

      bottomNavigationBar:
          isLargeScreen
              ? null
              : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onTapNav,
                selectedItemColor: const Color.fromARGB(255, 163, 14, 3),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(FluentIcons.home_more_20_filled),
                    label: 'Accueil',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FluentIcons.gift_card_24_filled),
                    label: 'Promos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FluentIcons.shopping_bag_tag_24_filled),
                    label: 'Panier',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FluentIcons.class_20_filled),
                    label: 'Souhaits',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FluentIcons.receipt_bag_24_filled),
                    label: 'Passés',
                  ),
                ],
              ),
    );
  }
}
