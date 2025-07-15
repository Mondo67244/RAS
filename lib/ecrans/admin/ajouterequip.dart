import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ras_app/basicdata/style.dart';

class AjouterEquipPage extends StatefulWidget {
  const AjouterEquipPage({super.key});

  @override
  _AjouterEquipPageState createState() => _AjouterEquipPageState();
}

class _AjouterEquipPageState extends State<AjouterEquipPage> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de texte
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _prixController = TextEditingController();
  final _quantiteController = TextEditingController();
  final List<File?> _imageFiles = [null, null, null];
  final ImagePicker _picker = ImagePicker();
  bool estChoisi = false;
  bool cash = false;
  bool electronique = false;
  bool enPromo = false;

  // Données pour les menus déroulants
  final List<String> _categories = [
    'Informatique',
    'Électro Ménager',
    'Électronique',
  ];
  String? _selectedCategory;
  String? _selectedType;

  // Structure des types par catégorie
  final Map<String, List<String>> categoryTypes = {
    'Informatique': ['Bureautique', 'Réseau', 'Accessoire fixe'],
    'Électro Ménager': ['Divers'],
    'Électronique': ['Appareil Mobile', 'Accessoire mobile'],
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _prixController.dispose();
    _quantiteController.dispose();
    super.dispose();
  }

  // Fonction pour sélectionner une image
  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFiles[index] = File(pickedFile.path);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Center(
              child: Text(
                'Image ${index + 1} importée avec succès',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }
    }
  }

  // Fonction pour soumettre le formulaire
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires.'),
        ),
      );
      return;
    }

    if (_imageFiles.any((file) => file == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner 3 images pour le produit.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> base64Images = [];
      for (final file in _imageFiles) {
        final Uint8List imageBytes = await file!.readAsBytes();
        base64Images.add(base64Encode(imageBytes));
      }

      await FirebaseFirestore.instance.collection('Produits').add({
        'nomProduit': _nomController.text.trim(),
        'description': _descriptionController.text.trim(),
        'marque': _marqueController.text.trim(),
        'modele': _modeleController.text.trim(),
        'prix': _prixController.text.trim(),
        'categorie': _selectedCategory,
        'type': _selectedType,
        'img1': base64Images[0],
        'img2': base64Images[1],
        'img3': base64Images[2],
        'vues': 0,
        'quantite': _quantiteController.text.trim(),
        'livrable': estChoisi,
        'cash': cash,
        'electronique': electronique,
        'enPromo': enPromo,
        'jeVeut': false,
        'auPanier': false,
        'enStock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Produit ajouté avec succès',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Erreur lors de l\'ajout : ${e.toString()}',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un nouveau produit'),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: styles.rouge,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _nomdestitres('Images du produit (3 obligatoires)'),
                  const SizedBox(height: 16),
                  _prendreImage(),
                  const SizedBox(height: 24),
                  _nomdestitres('Détails du produit'),
                  const SizedBox(height: 16),
                  _zonesTextes(),
                  const SizedBox(height: 32),
                  _boutonAjouter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nomdestitres(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _prendreImage() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _pickImage(index),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: styles.rouge, width: 1.5),
                  image:
                      _imageFiles[index] != null
                          ? DecorationImage(
                            image: FileImage(_imageFiles[index]!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    _imageFiles[index] == null
                        ? Center(
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: styles.rouge,
                          ),
                        )
                        : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _zonesTextes() {
    return Column(
      children: [
        //Nom du produit
        TextFormField(
          maxLength: 32,
          controller: _nomController,
          decoration: _titresChamps('Nom du produit'),
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer le nom du produit'
                      : null,
        ),
        const SizedBox(height: 16),
        //Quantité
        TextFormField(
          controller: _quantiteController,
          decoration: _titresChamps('Quantité disponible'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer une quantité';
            }
            if (int.tryParse(value) == null) {
              return 'Veuillez entrer une quantité valide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        //Marque
        TextFormField(
          controller: _marqueController,
          decoration: _titresChamps('Marque'),
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer la marque'
                      : null,
        ),
        const SizedBox(height: 16),
        //Modele
        TextFormField(
          maxLength: 13,
          controller: _modeleController,
          decoration: _titresChamps('Modèle'),
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer le modèle'
                      : null,
        ),
        const SizedBox(height: 16),
        //Prix
        TextFormField(
          controller: _prixController,
          decoration: _titresChamps('Prix (en CFA)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un prix';
            }
            if (double.tryParse(value) == null) {
              return 'Veuillez entrer un prix valide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        //List des catégories
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: _titresChamps('Catégorie'),
          items:
              _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedCategory = newValue;
              _selectedType = null;
            });
          },
          validator:
              (value) =>
                  value == null ? 'Veuillez choisir une catégorie' : null,
        ),
        if (_selectedCategory != null) ...[
          const SizedBox(height: 16),

          //Liste des types
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: _titresChamps('Type'),
            items:
                categoryTypes[_selectedCategory!]!.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
            onChanged: (newValue) => setState(() => _selectedType = newValue),
            validator:
                (value) => value == null ? 'Veuillez choisir un type' : null,
          ),
        ],
        const SizedBox(height: 16),
        //Titre statut
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Statut du produit :',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        //Boutons du statut du produit
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Text('Est livrable ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: estChoisi,
                  activeColor: styles.rouge,
                  onChanged: (value) {
                    setState(() {
                      estChoisi = !estChoisi;
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                Text('En Promo ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: enPromo,
                  activeColor: styles.rouge,
                  onChanged: (value) {
                    setState(() {
                      enPromo = !enPromo;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        //Champs de description
        TextFormField(
          controller: _descriptionController,
          decoration: _titresChamps('Description'),
          maxLines: 4,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer une description'
                      : null,
        ),

        //Bouton de choix de livraison
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Méthodes de paiement :',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        //Boutons de choix de paiement
        Wrap(
          children: [
            Row(
              children: [
                Text('MTN | Orange Money ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: electronique,
                  activeColor: styles.rouge,
                  onChanged: (value) {
                    setState(() {
                      electronique = !electronique;
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                Text('Pendant la livraison ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: cash,
                  activeColor: styles.rouge,
                  onChanged: (value) {
                    setState(() {
                      cash = !cash;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  //Boutons
  Widget _boutonAjouter() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: styles.rouge,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isLoading
                ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                : Text(
                  'Ajouter le produit',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  //Widget pour les titres des champs
  InputDecoration _titresChamps(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: styles.rouge!, width: 2),
      ),
    );
  }
}
