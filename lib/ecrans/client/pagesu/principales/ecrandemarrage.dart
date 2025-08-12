import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EcranDemarrage extends StatefulWidget {
  const EcranDemarrage({super.key});

  @override
  State<EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends State<EcranDemarrage> {
  @override
  void initState() {
    super.initState();
    // Naviguer après un délai de 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      _navigateBasedOnRole();
    });
  }

  Future<void> _navigateBasedOnRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted) return; // Vérifie si le widget est toujours monté

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Utilisateurs')
            .doc(user.uid)
            .get();

        final role = userDoc.data()?['roleUtilisateur'] as String?;
        
        if (!mounted) return; // Vérifie à nouveau avant la navigation

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin/ajouterequip');
        } else if (role == 'user') {
          Navigator.pushReplacementNamed(context, '/accueil');
        } else {
          // Cas où le rôle n'est pas défini ou invalide
          Navigator.pushReplacementNamed(context, '/accueil');
        }
      } else {
        // Aucun utilisateur connecté
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/accueil');
      }
    } catch (e) {
      // Gestion des erreurs
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/accueil');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la vérification du rôle: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 163, 14, 3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 100,
              child: Image.asset('assets/images/kanjad.png'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Un instant...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}