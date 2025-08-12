import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'package:RAS/services/synchronisation/synchronisation_service.dart';

class PageInscription extends StatefulWidget {
  const PageInscription({super.key});

  @override
  _PageInscriptionState createState() => _PageInscriptionState();
}

class _PageInscriptionState extends State<PageInscription> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _numeroController = TextEditingController();
  final _villeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _numeroController.dispose();
    _villeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Créer l'utilisateur dans Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = userCredential.user;
      if (user != null) {
        // Créer l'objet Utilisateur pour Firestore
        final nouvelUtilisateur = Utilisateur(
          idUtilisateur: user.uid,
          nomUtilisateur: _nomController.text.trim(),
          prenomUtilisateur: _prenomController.text.trim(),
          emailUtilisateur: _emailController.text.trim(),
          numeroUtilisateur: _numeroController.text.trim(),
          villeUtilisateur: _villeController.text.trim(),
          roleUtilisateur: 'user',
        );

        // Ajouter l'utilisateur à la collection Firestore
        await FirestoreService().addUtilisateur(nouvelUtilisateur);

        // Synchroniser le panier et les souhaits après l'inscription
        final SynchronisationService syncService = SynchronisationService();
        await syncService.synchroniserTout();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Styles.vert,
              content: Text(
                'Inscription réussie ! Vous pouvez maintenant vous connecter.',
              ),
            ),
          );
          Navigator.pop(context); // Retour à la page de connexion
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Une erreur est survenue.';
      if (e.code == 'weak-password') {
        message = 'Le mot de passe est trop faible.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Un compte existe déjà pour cet e-mail.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Styles.erreur, content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Styles.erreur,
            content: Text('Erreur lors de l\'inscription : ${e.toString()}'),
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
    bool isWideScreen = MediaQuery.of(context).size.width > 500;
    return Scaffold(
      backgroundColor: Styles.rouge,
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
              offset: const Offset(-23, 12),
              child: const Text(
                'Inscription',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Styles.rouge,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints:
                isWideScreen ? const BoxConstraints(maxWidth: 400) : null,
            child: Form(
              key: _formKey,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Le premier pas vers',
                          style: TextStyle(
                            fontSize: 24,
                            color: Styles.blanc,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'un achat réussi !',
                          style: TextStyle(
                            fontSize: 24,
                            color: Styles.blanc,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          //Nom
                          TextFormField(
                            controller: _nomController,
                            decoration: _inputDecoration('Nom'),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre nom'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          //Prenom
                          TextFormField(
                            controller: _prenomController,
                            decoration: _inputDecoration('Prénom'),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre prénom'
                                        : null,
                          ),
                          const SizedBox(height: 16),

                          //Email
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator:
                                (value) =>
                                    value!.isEmpty || !value.contains('@')
                                        ? 'Veuillez entrer un email valide'
                                        : null,
                          ),
                          const SizedBox(height: 16),

                          //Mot de passe
                          TextFormField(
                            controller: _passwordController,
                            decoration: _inputDecoration('Mot de passe'),
                            obscureText: true,
                            validator:
                                (value) =>
                                    value!.length < 6
                                        ? 'Le mot de passe doit contenir au moins 6 caractères'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          //Numero de telephone
                          TextFormField(
                            controller: _numeroController,
                            decoration: _inputDecoration('Numéro de téléphone'),
                            keyboardType: TextInputType.phone,
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre numéro'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          //Ville
                          TextFormField(
                            controller: _villeController,
                            decoration: _inputDecoration('Ville'),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre ville'
                                        : null,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Styles.bleu,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                              : const Text(
                                "S'inscrire",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Styles.rouge, width: 2),
      ),
    );
  }
}
