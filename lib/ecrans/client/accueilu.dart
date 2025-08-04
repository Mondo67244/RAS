import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/ecrans/client/pagesu/panier.dart';
import 'package:RAS/ecrans/client/pagesu/promo.dart';
import 'package:RAS/ecrans/client/pagesu/recents.dart';
import 'package:RAS/ecrans/client/pagesu/resultats.dart';
import 'package:RAS/ecrans/client/pagesu/souhaits.dart';

class Accueilu extends StatefulWidget {
  const Accueilu({super.key});

  @override
  State<Accueilu> createState() => _AccueiluState();
}

class _AccueiluState extends State<Accueilu> with TickerProviderStateMixin {
  TabController? _tabController;
  int _selectedIndex = 0;
  final bool _isClick = false;
  final List<Widget> _cachedPages = [];
  final Set<int> _loadedPages = <int>{};
  User? _currentUser;
  Map<String, dynamic>? _userData;

  // Create pages with AutomaticKeepAliveClientMixin to preserve state
  Widget _buildPage(Widget page, int index) {
    if (_loadedPages.contains(index)) {
      return _cachedPages[index];
    } else {
      _loadedPages.add(index);
      _cachedPages[index] = page;
      return page;
    }
  }

  List<Widget> get _pages {
    // Initialize cached pages list if empty
    if (_cachedPages.isEmpty) {
      _cachedPages.addAll(List.filled(4, Container())); // 4 pages: Recents, Promo, Panier, Souhaits
    }
    
    return [
      _buildPage(const Recents(), 0),
      _buildPage(const Promo(), 1),
      _buildPage(const Panier(), 2),
      _buildPage(const Souhaits(), 3),
    ];
  }

  final List<Tab> _tabs = const [
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.home_more_20_filled),
          SizedBox(width: 3),
          Text('Accueil'),
        ],
      ),
    ),
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.gift_card_24_filled),
          SizedBox(width: 3),
          Text('Promotions'),
        ],
      ),
    ),
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.shopping_bag_tag_24_filled),
          SizedBox(width: 3),
          Text('Panier'),
        ],
      ),
    ),
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.class_20_filled),
          SizedBox(width: 3),
          Text('Souhaits'),
        ],
      ),
    ),
    // Tab commandes retiré du PageView
    // Tab(
    //   child: Row(
    //     children: [
    //       Icon(FluentIcons.receipt_bag_24_filled),
    //       const SizedBox(width: 3),
    //       Text('Commandes'),
    //     ],
    //   ),
    // ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
      if (user != null) {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    final User? user = _currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Utilisateurs')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
          });
        }
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
      }
    }
  }

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
      _tabController = TabController(length: _tabs.length, vsync: this);
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        foregroundColor: Styles.blanc,
        backgroundColor: const Color.fromARGB(255, 163, 14, 3),
        title: Image.asset(
          'assets/images/kanjad.png',
          key: const ValueKey('logo'),
          width: 140,
          height: 50,
        ),

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
                          indicatorColor: Styles.rouge,
                          labelColor: Styles.rouge,
                          unselectedLabelColor: Colors.grey[600],
                          tabs: _tabs,
                        ),
                      ),
                    ),
                  ),
                )
                : null,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/utilisateur/commandes');
            },
            icon: const Icon(FluentIcons.receipt_bag_24_filled),
            tooltip: 'Mes Commandes',
          ),
          IconButton(
            onPressed: () {
              // Removed navigation to admin settings for regular users
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Styles.rouge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Styles.rouge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userData != null 
                        ? '${_userData!['prenomUtilisateur'] ?? ''} ${_userData!['nomUtilisateur'] ?? ''}'.trim()
                        : (_currentUser != null ? 'Utilisateur' : 'Invité'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentUser != null ? _currentUser!.email ?? 'Connecté' : 'Non connecté',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (_currentUser != null) ...[
              ListTile(
                leading: const Icon(FluentIcons.person_24_regular),
                title: const Text('Mon Profil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/utilisateur/profile');
                },
              ),
              ListTile(
                leading: const Icon(FluentIcons.chat_24_regular),
                title: const Text('Chat avec Admin'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/utilisateur/chat');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(FluentIcons.settings_24_regular),
                title: const Text('Paramètres'),
                onTap: () {
                  Navigator.pop(context);
                  // Removed navigation to admin settings for regular users
                },
              ),
              ListTile(
                leading: const Icon(FluentIcons.question_circle_24_regular),
                title: const Text('Aide'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/utilisateur/chat');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(FluentIcons.sign_out_24_regular),
                title: const Text('Déconnexion'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/connexion', (route) => false);
                  }
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(FluentIcons.arrow_enter_left_24_regular),
                title: const Text('Connexion'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/connexion', (route) => false);
                },
              ),
              ListTile(
                leading: const Icon(FluentIcons.person_add_24_regular),
                title: const Text('Inscription'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/inscription', (route) => false);
                },
              ),
            ],
          ],
        ),
      ),

      body:
          _isClick
              ? const Resultats()
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
                  // BottomNavigationBarItem commandes retiré
                  // BottomNavigationBarItem(
                  //   icon: Icon(FluentIcons.receipt_bag_24_filled),
                  //   label: 'Passés',
                  // ),
                ],
              ),
    );
  }
}