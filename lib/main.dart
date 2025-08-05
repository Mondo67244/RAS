import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/ecrans/admin/accueila.dart';
import 'package:RAS/ecrans/client/accueilu.dart';
import 'package:RAS/ecrans/admin/ajouterequip.dart';
import 'package:RAS/ecrans/client/pagesu/commandes.dart';
import 'package:RAS/ecrans/client/pagesu/details.dart';
import 'package:RAS/ecrans/client/pagesu/resultats.dart';
import 'package:RAS/ecrans/pageconnexion.dart';
import 'package:RAS/ecrans/pageinscription.dart';
import 'package:RAS/ecrans/client/pagesu/voirplus.dart';
import 'package:RAS/ecrans/client/pagesu/payment_page.dart';
import 'package:RAS/ecrans/ecrandemarrage.dart';
import 'package:RAS/ecrans/client/pagesu/chat.dart';
import 'package:RAS/ecrans/client/pagesu/profile.dart'; // Ajout de l'import du profil
import 'package:RAS/firebase_options.dart';
import 'package:RAS/services/synchronisation/synchronisation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/admin': (context) => const Accueila(),
        '/utilisateur': (context) => const Accueilu(),

        '/utilisateur/recherche' : (context) => const Resultats(),
        '/utilisateur/payment': (context) {
          final commande = ModalRoute.of(context)!.settings.arguments as Commande;
          return PaymentPage(commande: commande);
        },
        '/admin/nouveau produit': (context) => const AjouterEquipPage(),
        '/connexion': (context) => const Pageconnexion(),
        '/inscription': (context) => const PageInscription(),
        '/utilisateur/commandes': (context) => const Commandes(),
        '/utilisateur/produit/details': (context) {
          final produit = ModalRoute.of(context)!.settings.arguments as Produit;
          return Details(produit: produit);
        },
        '/utilisateur/chat': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return ChatPage(
            idProduit: args['idProduit'] as String?,
            nomProduit: args['nomProduit'] as String?,
          );
        },
        '/utilisateur/profile': (context) => const ProfilePage(), // Ajout de la route du profil
        '/all_products': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final title = args['title'] as String;
          final produits = args['produits'] as List<Produit>;
          return Voirplus(title: title, produits: produits);
        },
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Vérifier l'état de l'authentification
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Afficher un indicateur de chargement pendant la vérification
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si l'utilisateur est connecté, synchroniser les données
        if (snapshot.hasData) {
          // Synchroniser le panier et les souhaits
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final SynchronisationService syncService = SynchronisationService();
            syncService.synchroniserTout();
          });
          
          // Rediriger vers l'écran d'accueil utilisateur
          return const Accueilu();
        }

        // Si aucun utilisateur n'est connecté, afficher l'écran de démarrage
        return const EcranDemarrage();
      },
    );
  }
}