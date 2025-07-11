import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert'; // Pour encoder en base64
import 'dart:typed_data'; // Pour Uint8List
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

  final List<File?> _imageFiles = [null, null, null];
  final ImagePicker _picker = ImagePicker();

  // Données pour les menus déroulants
  final List<String> _categories = [
    'Équipements informatiques',
    'Électro Ménager',
  ];
  String? _selectedCategory;

  final List<String> _types = [
    'Ordinateurs',
    'Bureautique',
    'Appareils Mobiles',
    'Accessoires',
    'Réseau',
    'Divers',
  ];
  String? _selectedType;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    _selectedType = _types.first;
  }

  @override
  void dispose() {
    // Libérer les ressources des contrôleurs
    _nomController.dispose();
    _descriptionController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _prixController.dispose();
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
            content: Center(child: Text('Image ${index + 1} importée avec succès',style: TextStyle(fontWeight: FontWeight.bold),))),
        );
      }
    }
  }

  // Fonction pour soumettre le formulaire
  Future<void> _submitForm() async {
    // 1. Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires.')),
      );
      return;
    }

    // 2. Vérifier que les 3 images ont été sélectionnées
    if (_imageFiles.any((file) => file == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner 3 images pour le produit.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Encoder les images en Base64
      final List<String> base64Images = [];
      for (final file in _imageFiles) {
        final Uint8List imageBytes = await file!.readAsBytes();
        base64Images.add(base64Encode(imageBytes));
      }

      // 4. Sauvegarder les données dans Firestore
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
        'vues': 0 , 
        'jeVeut': false,
        'auPanier': false,
        'enStock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Produit ajouté avec succès', style: TextStyle(color: style.blanc)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Erreur lors de l\'ajout : ${e.toString()}', style: TextStyle(color: style.blanc)),
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
        titleTextStyle: TextStyle(color: style.blanc, fontSize: 20, fontWeight: FontWeight.bold),
        backgroundColor: style.rouge,
        iconTheme: IconThemeData(color: style.blanc),
        centerTitle: true,
      ),
      body: Form(
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
    );
  }

  // Widget pour le titre d'une section
  Widget _nomdestitres(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
    );
  }

  // Widget pour la sélection des images
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
                  border: Border.all(color: style.rouge, width: 1.5),
                  image: _imageFiles[index] != null
                      ? DecorationImage(
                          image: FileImage(_imageFiles[index]!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFiles[index] == null
                    ? Center(
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: style.rouge,
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

  // Widget contenant tous les champs du formulaire
  Widget _zonesTextes() {
    return Column(
      children: [
        TextFormField(
          controller: _nomController,
          decoration: _buildInputDecoration('Nom du produit'),
          validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le nom du produit' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _marqueController,
          decoration: _buildInputDecoration('Marque'),
          validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer la marque' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _modeleController,
          decoration: _buildInputDecoration('Modèle'),
          validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le modèle' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _prixController,
          decoration: _buildInputDecoration('Prix (en CFA)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Veuillez entrer un prix';
            if (double.tryParse(value) == null) return 'Veuillez entrer un prix valide';
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: _buildInputDecoration('Catégorie'),
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (newValue) => setState(() => _selectedCategory = newValue),
          validator: (value) => value == null ? 'Veuillez choisir une catégorie' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: _buildInputDecoration('Type'),
          items: _types.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (newValue) => setState(() => _selectedType = newValue),
          validator: (value) => value == null ? 'Veuillez choisir un type' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: _buildInputDecoration('Description'),
          maxLines: 4,
          validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une description' : null,
        ),
      ],
    );
  }

  // Widget pour le bouton de soumission
  Widget _boutonAjouter() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: style.rouge,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: style.blanc, strokeWidth: 3),
              )
            : Text(
                'Ajouter le produit',
                style: TextStyle(fontSize: 18, color: style.blanc, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // Fonction d'aide pour créer une décoration d'input standardisée
  InputDecoration _buildInputDecoration(String label) {
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
        borderSide: BorderSide(color: style.rouge!, width: 2),
      ),
    );
  }
}