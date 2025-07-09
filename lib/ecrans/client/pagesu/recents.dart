import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/services/lienbd.dart';

class Recents extends StatefulWidget {
  const Recents({super.key});

  @override
  State<Recents> createState() => _RecentsState();
}

class _RecentsState extends State<Recents> {
  late Future<List<Produit>> _produitsFuture;
  final FirestoreService _firestoreService = FirestoreService();

  // États individuels pour chaque produit, initialisés à partir de Firestore
  final Set<String> _souhaits = {};
  final Set<String> _paniers = {};

  @override
  void initState() {
    super.initState();
    _changeletatdesboutons();
  }

  Future<void> _changeletatdesboutons() async {
    _produitsFuture = _firestoreService.getProduits();
    try {
      // Pour récupérer les produits
      List<Produit> produits = await _produitsFuture;

      // Initialiser les champs en fonction des champs de la base de donnée
      setState(() {
        for (var produit in produits) {
          if (produit.jeVeut == true) {
            _souhaits.add(produit.idProduit);
          }
          if (produit.auPanier == true) {
            _paniers.add(produit.idProduit);
          }
        }
      });
    } catch (e) {
      print(
        'Erreur lors du chargement des produits et des états des boutons: $e',
      );
    }
  }

  // Fonction pour basculer l'état "jeVeut" et mettre à jour Firestore et l'état local
  Future<void> _toggleJeVeut(Produit produit) async {
    final bool nouvelEtat = !_souhaits.contains(produit.idProduit);
    try {
      await FirebaseFirestore.instance
          .collection('Produits')
          .doc(produit.idProduit)
          .update({'jeVeut': nouvelEtat, 'auPanier': false});
          if (nouvelEtat == true){
            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Column(
                            children: [
                              Text('Vous avez ajouté ${produit.nomProduit} à vos souhaits',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                              ),
                              ),
                            ],
                          ))
                        );
          } else if (nouvelEtat == false){
            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color.fromARGB(255, 175, 76, 76),
                            content: Column(
                            children: [
                              Text('Vous avez retiré ${produit.nomProduit} à vos souhaits',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                              ),
                              ),
                            ],
                          ))
                        );
          }
          
      setState(() {
        if (nouvelEtat) {
          _souhaits.add(produit.idProduit);
          _paniers.remove(produit.idProduit);
        } else {
          _souhaits.remove(produit.idProduit);
          ;
        }
      });
    } catch (e) {
      print(
        'Erreur lors de la mise à jour de jeVeut pour ${produit.idProduit}: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de mise à jour du souhait: $e')),
      );
    }
  }

  // Fonction pour basculer l'état "auPanier" et mettre à jour Firestore et l'état local
  Future<void> _toggleAuPanier(Produit produit) async {
    final bool nouvelEtat = !_paniers.contains(produit.idProduit);
    try {
      await FirebaseFirestore.instance
          .collection(
            'Produits',
          ) // Vérifiez que le nom de la collection est correct
          .doc(produit.idProduit)
          .update({'auPanier': nouvelEtat, 'jeVeut': false});

      setState(() {
        if (nouvelEtat) {
          _paniers.add(produit.idProduit);
          _souhaits.remove(produit.idProduit);
        } else {
          _paniers.remove(produit.idProduit);
        }
      });
    } catch (e) {
      print(
        'Erreur lors de la mise à jour de auPanier pour ${produit.idProduit}: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de mise à jour du panier: $e')),
      );
    }
  }

  //Scaffold permettant d'afficher les cartes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<List<Produit>>(
                future:
                    _produitsFuture, // Utilise le Future qui charge les produits
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 141, 13, 4),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(
                      child: Column(
                        children: [
                          SizedBox(height: 140),
                          Icon(
                            Icons.delivery_dining_outlined,
                            size: 200,
                            color: Colors.grey,
                          ),
                          Text(
                            'Aucun article trouvé',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final produits = snapshot.data!;
                  final produitsBureautique =
                      produits
                          .where((p) => p.categorie == 'Bureautique')
                          .toList();
                  final produitsPopulaires =
                      produits.where((p) {
                        final int vuesCount = int.tryParse(p.vues) ?? 0;
                        return vuesCount > 15;
                      }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _imageHeader('assets/images/05.jpg'),
                      const SizedBox(height: 10),
                      _sectionProduits(
                        'Articles Populaires',
                        produitsPopulaires,
                      ),
                      _imageHeader('assets/images/06.jpg'),
                      const SizedBox(height: 10),
                      _sectionProduits(
                        'Dans la catégorie Bureautique',
                        produitsBureautique,
                      ),
                      _imageHeader('assets/images/07.jpg'),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section d'images
  Widget _imageHeader(String path) {
    return Center(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
        ),
      ),
    );
  }

  // Section de produits
  Widget _sectionProduits(String titre, List<Produit> produits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            children: [
              Icon(FluentIcons.arrow_right_24_filled),
              const SizedBox(width: 5),
              Text(
                titre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 310,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: produits.length,
            itemBuilder: (context, index) {
              return _carteArticle(produits[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _carteArticle(Produit produit) {
    final bool isSouhait = _souhaits.contains(produit.idProduit);
    final bool isPanier = _paniers.contains(produit.idProduit);

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
        width: 260,
        child: Column(
          children: [
            const SizedBox(height: 3),
            Container(
              height: 180,
              width: 255,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/05.jpg'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 40,
                      child: Column(
                        children: [
                          Text(
                            produit.nomProduit,
                            maxLines: 3,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${produit.prix} CFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 141, 13, 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 5),
                    //Bouton souhait
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSouhait
                                ? Colors.white
                                : const Color.fromARGB(255, 141, 13, 4),
                        foregroundColor:
                            isSouhait
                                ? const Color.fromARGB(255, 141, 13, 4)
                                : Colors.white,
                      ),
                      onPressed: () async{
                        await _toggleJeVeut(produit);
                        
                      },
                      child: Row(
                        children: [
                          Icon(
                            isSouhait
                                ? FluentIcons.book_star_24_filled
                                : FluentIcons.book_star_24_regular,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isSouhait ? 'Souhaité' : 'Souhait',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    //Bouton Panier
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isPanier
                                ? const Color.fromARGB(255, 1, 7, 71)
                                : Colors.white,
                        foregroundColor:
                            isPanier
                                ? Colors.white
                                : const Color.fromARGB(255, 1, 7, 71),
                      ),
                      onPressed:
                          () => _toggleAuPanier(
                            produit,
                          ), // Appel à la nouvelle fonction
                      child: Row(
                        children: [
                          Icon(
                            isPanier
                                ? FluentIcons
                                    .shopping_bag_tag_24_filled // Icône pour "ajouté au panier"
                                : FluentIcons
                                    .shopping_bag_tag_24_regular, // Icône pour "non ajouté au panier"
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isPanier ? 'Ajouté' : 'Panier',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
