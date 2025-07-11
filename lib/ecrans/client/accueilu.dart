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
  late TabController _tabController;
  late bool _isClick;

  @override
  void initState() {
    super.initState();
    _isClick = false;
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin/nouveau produit');
        },
      ),
      appBar: AppBar(
        foregroundColor: styles.blanc,
        backgroundColor: const Color.fromARGB(255, 163, 14, 3),
        title: SizedBox(
          width: 400,
          child:
              //Oscillation entre la barre de recherche et le logo
              _isClick
                  ? Transform.translate(
                    offset: Offset(0, 6),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 700),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(1, 0),
                              end: Offset(0, 0),
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _barreRecherche(key: ValueKey(1)),
                    ),
                  )
                  : Image.asset(
                    'assets/images/kanjad.png',
                    width: 140,
                    key: ValueKey(2),
                    height: 50,
                  ),
        ),
        actions: [
          //Affiche les autres boutons si le bouton recherche est cliqué
          _isClick
              ? _prixCat()
              : Transform.translate(
                offset: Offset(-10, 0),
                child: Transform.translate(
                  offset: Offset(0, 8),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isClick = !_isClick;
                      });
                    },
                    icon: Icon(_isClick ? Icons.close : Icons.search),
                  ),
                ),
              ),
        ],
        //Permet de rendre le bottom de l'appBar blanc au lieu de la couleur de l'appBar
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.white,
            child: TabBar(
              indicatorAnimation: TabIndicatorAnimation.elastic,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: true,
              indicatorColor: Color.fromARGB(255, 141, 13, 4),
              controller: _tabController,
              labelColor: const Color.fromARGB(255, 163, 14, 3),
              //Les différentes pages
              tabs: const [
                Tab(
                  child: Row(
                    children: [
                      Text(
                        'Accueil',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Tab(
                  //Promotion
                  child: Row(
                    children: [
                      Icon(FluentIcons.gift_card_24_filled),
                      SizedBox(width: 3),
                      Text(
                        'Promotions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Tab(
                  //Mon panier
                  child: Row(
                    children: [
                      Icon(FluentIcons.shopping_bag_tag_24_filled),
                      SizedBox(width: 3),
                      Text(
                        'Mon Panier',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Tab(
                  //Mes souhaits
                  child: Row(
                    children: [
                      Icon(FluentIcons.book_star_24_filled),
                      SizedBox(width: 3),
                      Text(
                        'Mes Souhaits',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Tab(
                  //Mes commandes
                  child: Row(
                    children: [
                      Icon(FluentIcons.receipt_bag_24_filled),
                      SizedBox(width: 3),
                      Text(
                        'Mes Commandes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
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
          _isClick ? Resultats() : Recents(),
          _isClick ? Resultats() : Promo(),
          _isClick ? Resultats() : Panier(),
          _isClick ? Resultats() : Souhaits(),
          _isClick ? Resultats() : Commandes(),
        ],
      ),
    );
  }

  //Icones du prix et de la catégorie du produit
  Widget _prixCat() {
    return Row(
      children: [
        Transform.translate(
          offset: Offset(10, 8),
          child: IconButton(
            onPressed: () {},
            icon: Icon(Icons.price_change_outlined, color: Colors.white),
          ),
        ),
        Transform.translate(
          offset: Offset(0, 8),
          child: IconButton(
            onPressed: () {},
            icon: Icon(Icons.category_outlined, color: Colors.white),
          ),
        ),
        Transform.translate(
          offset: Offset(-10, 0),
          child: Transform.translate(
            offset: Offset(0, 8),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isClick = !_isClick;
                });
              },
              icon: Icon(
                _isClick ? Icons.close : Icons.search,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Barre de recherche
  Widget _barreRecherche({required Key key}) {
    return SizedBox(
      width: 400,
      height: 50,
      child: TextField(
        maxLines: 1,
        key: key,
        cursorColor: Color.fromARGB(255, 141, 13, 4),
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          filled: true,

          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white),
          ),
          prefixIcon: Icon(Icons.search),
          prefixIconColor: Color.fromARGB(255, 141, 13, 4),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 0.5, color: Colors.white),
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: const TextStyle(fontSize: 16),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
