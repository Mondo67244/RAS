import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';

/// Widget pour afficher les résultats de la recherche de produits.
class Resultats extends StatefulWidget {
  /// Constructeur du widget [Resultats].
  const Resultats({super.key});

  @override
  State<Resultats> createState() => _ResultatsState();
}

/// État du widget [Resultats].
class _ResultatsState extends State<Resultats> {
  /// Clé pour le formulaire de recherche.
  final _formKey = GlobalKey<FormState>();

  /// Contrôleur pour le champ de recherche texte.
  final _searchController = TextEditingController();

  /// Contrôleur pour le champ de prix minimum.
  final _minPriceController = TextEditingController();

  /// Contrôleur pour le champ de prix maximum.
  final _maxPriceController = TextEditingController();

  /// Liste des catégories disponibles.
  final List<String> _categories = [
    'Informatique',
    'Électro Ménager',
    'Électronique',
  ];

  /// Liste des marques disponibles.
  final List<String> _brands = [
    '- Autre -',
    'Apple',
    'Dell',
    'HP',
    'Lenovo',
    'Samsung',
    'Sony',
    'LG',
  ];

  /// Map des sous-catégories par catégorie.
  final Map<String, List<String>> categoryTypes = {
    'Informatique': ['Bureautique', 'Réseau'],
    'Électro Ménager': ['Divers'],
    'Électronique': ['Appareils Mobiles', 'Accessoires'],
  };

  /// Map des types d'appareils par sous-catégorie.
  final Map<String, List<String>> typeAppareil = {
    'Bureautique': [
      'Imprimante',
      'Souris',
      'Clavier',
      'Ecran',
      'Ordinateur',
      'Scanner',
      'Haut parleur',
    ],
    'Réseau': ['Routeurs', 'Switch', 'Modem', 'Serveur'],
    'Appareils Mobiles': ['Téléphone', 'Tablette', 'Accessoire mobile'],
    'Divers': ['Téléviseur', 'Machine à laver', 'Cafetière', 'Fers à repasser'],
    'Accessoires': ['Montres connectées', 'Casques', 'Chaussures'],
  };

  /// Catégorie sélectionnée.
  String? _selectedCategory;

  /// Sous-catégorie sélectionnée.
  String? _selectedSousCat;

  /// Type d'appareil sélectionné.
  String? _selectedType;

  /// Marque sélectionnée.
  String? _selectedBrand;

  /// Indique si une recherche est en cours.
  bool _isLoading = false;

  /// Indique si une recherche a été effectuée.
  bool _hasSearched = false;

  /// Indique si le formulaire de recherche est visible.
  bool _isSearchFormVisible = true;

  /// Timer pour le debounce de la recherche.
  Timer? _debounce;

  /// Stream contenant les résultats de la recherche.
  Stream<List<Produit>>? _searchStream;

  /// Couleur primaire rouge utilisée dans l'interface.
  final Color primaryRed = const Color.fromARGB(255, 209, 0, 0);

  /// Couleur primaire bleue utilisée dans l'interface.
  final Color primaryBlue = const Color.fromARGB(255, 30, 2, 155);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _minPriceController.addListener(_onPriceChanged);
    _maxPriceController.addListener(_onPriceChanged);
  }

  @override
  /// Libère les ressources des contrôleurs et du timer.
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Déclenchée lorsque le texte de la barre de recherche change.
  /// Utilise un debounce pour éviter des recherches trop fréquentes.
  void _onSearchTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _performSearch);
  }

  /// Déclenchée lorsque les valeurs des champs de prix changent.
  /// Utilise un debounce pour éviter des recherches trop fréquentes.
  void _onPriceChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _performSearch);
  }

  /// Déclenchée lorsque les valeurs des dropdowns changent.
  /// Utilise un debounce avec un délai plus court.
  void _onDropdownChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _performSearch);
  }

  /// Construit le stream de recherche en fonction des critères actuels.
  ///
  /// Effectue les requêtes Firestore et filtre les résultats localement
  /// pour le texte et les prix.
  Stream<List<Produit>> _buildSearchStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'Produits',
    );

    // Application des filtres Firestore
    if (_selectedCategory != null) {
      query = query.where('categorie', isEqualTo: _selectedCategory);
    }
    if (_selectedSousCat != null) {
      query = query.where('sousCategorie', isEqualTo: _selectedSousCat);
    }
    if (_selectedType != null) {
      query = query.where('type', isEqualTo: _selectedType);
    }
    if (_selectedBrand != null && _selectedBrand != '- Autre -') {
      query = query.where('marque', isEqualTo: _selectedBrand);
    }

    // Traitement des snapshots et filtres locaux
    return query.snapshots().map((snapshot) {
      List<Produit> results =
          snapshot.docs.map((doc) => Produit.fromFirestore(doc, null)).toList();

      final searchText = _searchController.text.toLowerCase();
      final minPriceText = _minPriceController.text;
      final maxPriceText = _maxPriceController.text;

      // Filtre par texte (nom ou description)
      if (searchText.isNotEmpty) {
        results =
            results
                .where(
                  (p) =>
                      p.nomProduit.toLowerCase().contains(searchText) ||
                      p.description.toLowerCase().contains(searchText),
                )
                .toList();
      }

      // Filtre par prix minimum
      if (minPriceText.isNotEmpty) {
        final minPrice = double.tryParse(minPriceText);
        if (minPrice != null) {
          results =
              results.where((p) {
                final prixProduit = double.tryParse(p.prix.toString()) ?? 0.0;
                return prixProduit >= minPrice;
              }).toList();
        }
      }

      // Filtre par prix maximum
      if (maxPriceText.isNotEmpty) {
        final maxPrice = double.tryParse(maxPriceText);
        if (maxPrice != null) {
          results =
              results.where((p) {
                final prixProduit = double.tryParse(p.prix.toString()) ?? 0.0;
                return prixProduit <= maxPrice;
              }).toList();
        }
      }

      return results;
    });
  }

  /// Lance la recherche en mettant à jour l'état et le stream.
  Future<void> _performSearch() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchStream = _buildSearchStream();
    });
    // Petit délai pour permettre à l'UI de se mettre à jour
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
        centerTitle: true,
      ),
      floatingActionButton:
          !_isSearchFormVisible
              ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isSearchFormVisible = true;
                  });
                },
                backgroundColor: Styles.rouge,
                child: const Icon(Icons.search, color: Colors.white),
              )
              : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 650) {
            // Layout pour les écrans larges (web/desktop)
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(70.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 2, child: _buildSearchForm()),
                      const SizedBox(width: 50,),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 4, child: _buildResultsSection()),
                    ],
                  ),
                ),
              ),
            );
          } else {
            // Layout pour les écrans étroits (mobile)
            return Column(
              children: [
                _buildSearchForm(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(
                    color: primaryBlue.withAlpha((0.5 * 255).round()),
                    thickness: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildResultsSection()),
              ],
            );
          }
        },
      ),
    );
  }

  /// Construit le formulaire de recherche.
  Widget _buildSearchForm() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isSearchFormVisible ? 1.0 : 0.0,
        child:
            _isSearchFormVisible
                ? Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Wrap(
                          runSpacing: 16,
                          spacing: 16,
                          children: [
                            _buildDropdown(
                              _categories,
                              'Catégorie',
                              _selectedCategory,
                              (val) {
                                setState(() {
                                  _selectedCategory = val;
                                  _selectedSousCat = null;
                                  _selectedType = null;
                                  _onDropdownChanged();
                                });
                              },
                            ),
                            if (_selectedCategory != null)
                              _buildDropdown(
                                categoryTypes[_selectedCategory!]!,
                                'Sous-catégorie',
                                _selectedSousCat,
                                (val) {
                                  setState(() {
                                    _selectedSousCat = val;
                                    _selectedType = null;
                                    _onDropdownChanged();
                                  });
                                },
                              ),
                            if (_selectedSousCat != null)
                              _buildDropdown(
                                typeAppareil[_selectedSousCat!]!,
                                'Type d\'appareil',
                                _selectedType,
                                (val) {
                                  setState(() {
                                    _selectedType = val;
                                    _onDropdownChanged();
                                  });
                                },
                              ),
                            _buildDropdown(_brands, 'Marque', _selectedBrand, (
                              val,
                            ) {
                              setState(() {
                                _selectedBrand = val;
                                _onDropdownChanged();
                              });
                            }),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _minPriceController,
                                    decoration: _inputDecoration(
                                      'Prix Min',
                                      Icons.price_check,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _maxPriceController,
                                    decoration: _inputDecoration(
                                      'Prix Max',
                                      Icons.price_change_outlined,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _performSearch,
                                    icon:
                                        _isLoading
                                            ? Container()
                                            : const Icon(
                                              Icons.search,
                                              color: Colors.white,
                                            ),
                                    label:
                                        _isLoading
                                            ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              ),
                                            )
                                            : const Text('Rechercher'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Styles.rouge,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: Icon(
                                    Icons.visibility_off,
                                    color: Styles.bleu,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isSearchFormVisible =
                                          !_isSearchFormVisible;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                : const SizedBox.shrink(),
      ),
    );
  }

  /// Construit un widget DropdownButton2.
  ///
  /// [items] : Liste des éléments du dropdown.
  /// [hint] : Texte d'indice.
  /// [selectedValue] : Valeur actuellement sélectionnée.
  /// [onChanged] : Callback appelé lors d'un changement de sélection.
  Widget _buildDropdown(
    List<String> items,
    String hint,
    String? selectedValue,
    void Function(String?) onChanged,
  ) {
    return DropdownButton2<String>(
      isExpanded: true,
      value: selectedValue,
      hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: onChanged,
      buttonStyleData: ButtonStyleData(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
      ),
      dropdownStyleData: const DropdownStyleData(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  /// Construit la section d'affichage des résultats.
  Widget _buildResultsSection() {
    if (!_hasSearched) {
      return Center(
        child: Text(
          'Utilisez le formulaire ci-joint pour lancer une recherche.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return StreamBuilder<List<Produit>>(
      stream: _searchStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryRed));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(
            child: Text('Aucun résultat trouvé pour ces critères.'),
          );
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder:
              (context, index) => const Divider(indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final produit = results[index];
            return ListTile(
              leading:
                  produit.img1.isNotEmpty
                      ? _buildImage(produit.img1)
                      : const Icon(Icons.image_not_supported, size: 60),
              title: Text(
                produit.nomProduit,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${produit.categorie} > ${produit.sousCategorie}\n${produit.prix.toString()} CFA',
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/details',
                  arguments: produit,
                ).then((_) => _performSearch());
              },
            );
          },
        );
      },
    );
  }

  /// Construit un widget Image à partir de données encodées ou d'une URL.
  ///
  /// [imageData] : Peut être une URL ou une chaîne Base64.
  Widget _buildImage(String imageData) {
    try {
      if (imageData.startsWith('http')) {
        // Image depuis une URL
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imageData,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Gestion des erreurs de chargement réseau
              return const Icon(
                Icons.broken_image_outlined,
                color: Colors.red,
                size: 60,
              );
            },
          ),
        );
      } else {
        // Image depuis Base64
        final Uint8List imageBytes = base64Decode(imageData);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.memory(
            imageBytes,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        );
      }
    } catch (e) {
      // En cas d'erreur de décodage
      return const Icon(
        Icons.broken_image_outlined,
        color: Colors.red,
        size: 60,
      );
    }
  }

  /// Définit le style des champs de saisie (InputDecoration).
  ///
  /// [label] : Le texte du label.
  /// [icon] : L'icône à afficher.
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: primaryBlue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // Pas de bordure par défaut
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      filled: true, // Active le remplissage
      fillColor: Colors.grey[50], // Couleur de fond
    );
  }
}
