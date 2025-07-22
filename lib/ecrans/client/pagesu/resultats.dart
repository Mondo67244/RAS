import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';

class Resultats extends StatefulWidget {
  const Resultats({super.key});

  @override
  State<Resultats> createState() => _ResultatsState();
}

class _ResultatsState extends State<Resultats> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  final List<String> _categories = ['Informatique', 'Électro Ménager', 'Électronique'];
  final List<String> _brands = ['- Autre -', 'Apple', 'Dell', 'HP', 'Lenovo', 'Samsung', 'Sony', 'LG'];
  final Map<String, List<String>> categoryTypes = {
    'Informatique': ['Bureautique', 'Réseau'],
    'Électro Ménager': ['Divers'],
    'Électronique': ['Appareils Mobiles', 'Accessoires'],
  };
  final Map<String, List<String>> typeAppareil = {
    'Bureautique': ['Imprimante', 'Souris', 'Clavier', 'Ecran', 'Ordinateur', 'Scanner', 'Haut parleur'],
    'Réseau': ['Routeurs', 'Switch', 'Modem', 'Serveur'],
    'Appareils Mobiles': ['Téléphone', 'Tablette', 'Accessoire mobile'],
    'Divers': ['Téléviseur', 'Machine à laver', 'Cafetière', 'Fers à repasser'],
    'Accessoires': ['Montres connectées', 'Casques', 'Chaussures'],
  };

  String? _selectedCategory;
  String? _selectedSousCat;
  String? _selectedType;
  String? _selectedBrand;

  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;

  Stream<List<Produit>>? _searchStream;

  final Color primaryRed = const Color.fromARGB(255, 209, 0, 0);
  final Color primaryBlue = const Color.fromARGB(255, 30, 2, 155);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _minPriceController.addListener(_onPriceChanged);
    _maxPriceController.addListener(_onPriceChanged);
  }

  @override
  //Pour disposer les champs 
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

//Quand le texte de la barre de recherche change
  void _onSearchTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _performSearch);
  }

//Quand le prix change
  void _onPriceChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _performSearch);
  }

//Lorsque la valeur des dropdownchange
  void _onDropdownChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _performSearch);
  }

//StreamBuilder pour récupérer les données de Firestore
  Stream<List<Produit>> _buildSearchStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('Produits');

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

    return query.snapshots().map((snapshot) {
      List<Produit> results = snapshot.docs.map((doc) => Produit.fromFirestore(doc)).toList();

      final searchText = _searchController.text.toLowerCase();
      final minPrice = double.tryParse(_minPriceController.text);
      final maxPrice = double.tryParse(_maxPriceController.text);

      if (searchText.isNotEmpty) {
        results = results.where((p) =>
            p.nomProduit.toLowerCase().contains(searchText) ||
            p.description.toLowerCase().contains(searchText)).toList();
      }

      if (minPrice != null) {
        results = results.where((p) => (double.tryParse(p.prix) ?? 0.0) >= minPrice).toList();
      }

      if (maxPrice != null) {
        results = results.where((p) => (double.tryParse(p.prix) ?? 0.0) <= maxPrice).toList();
      }

      return results;
    });
  }

//Méthode pour lancer les recherches
  Future<void> _performSearch() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchStream = _buildSearchStream();
    });

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
      body: Column(
        children: [
          _buildSearchForm(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: primaryBlue.withOpacity(0.5), thickness: 1),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildResultsSection()),
        ],
      ),
    );
  }

//le formulaire de recherche
  Widget _buildSearchForm() {
    return Form(
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
                _buildDropdown(_categories, 'Catégorie', _selectedCategory, (val) {
                  setState(() {
                    _selectedCategory = val;
                    _selectedSousCat = null;
                    _selectedType = null;
                    _onDropdownChanged();
                  });
                }),

                if (_selectedCategory != null)
                  _buildDropdown(categoryTypes[_selectedCategory!]!, 'Sous-catégorie', _selectedSousCat, (val) {
                    setState(() {
                      _selectedSousCat = val;
                      _selectedType = null;
                      _onDropdownChanged();
                    });
                  }),

                if (_selectedSousCat != null)
                  _buildDropdown(typeAppareil[_selectedSousCat!]!, 'Type d\'appareil', _selectedType, (val) {
                    setState(() {
                      _selectedType = val;
                      _onDropdownChanged();
                    });
                  }),

                _buildDropdown(_brands, 'Marque', _selectedBrand, (val) {
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
                        decoration: _inputDecoration('Prix Min', Icons.price_check),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxPriceController,
                        decoration: _inputDecoration('Prix Max', Icons.price_change_outlined),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _performSearch,
                    icon: _isLoading ? Container() : const Icon(Icons.search, color: Colors.white),
                    label: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Rechercher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

//Les listes déroulantes
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
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      buttonStyleData: ButtonStyleData(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
      ),
      dropdownStyleData: DropdownStyleData(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

//L'endroit dans lequel on affiche les résultats
  Widget _buildResultsSection() {
    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Utilisez le formulaire ci-dessus pour lancer une recherche.',
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
          return const Center(child: Text('Aucun résultat trouvé pour ces critères.'));
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final produit = results[index];
            return ListTile(
              leading: produit.img1.isNotEmpty
                  ? _buildImage(produit.img1)
                  : const Icon(Icons.image_not_supported, size: 60),
              title: Text(produit.nomProduit, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${produit.categorie} > ${produit.sousCategorie}\n${produit.prix} CFA'),
              isThreeLine: true,
              onTap: () {
                Navigator.pushNamed(context, '/details', arguments: produit);
              },
            );
          },
        );
      },
    );
  }

//Méthode pour récupérer les images et les décoder
  Widget _buildImage(String imageData) {
    try {
      if (imageData.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(imageData, width: 60, height: 60, fit: BoxFit.cover),
        );
      }
      final Uint8List imageBytes = base64Decode(imageData);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.memory(imageBytes, width: 60, height: 60, fit: BoxFit.cover),
      );
    } catch (e) {
      return const Icon(Icons.broken_image_outlined, color: Colors.red, size: 60);
    }
  }

// Le style des zones de textes
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: primaryBlue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
    );
  }
}
