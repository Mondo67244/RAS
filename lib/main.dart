import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/ecrans/admin/accueila.dart';
import 'package:RAS/ecrans/client/pagesu/principales/accueilu.dart';
import 'package:RAS/ecrans/admin/ajouterequip.dart';
import 'package:RAS/ecrans/client/pagesu/articles/commandes.dart';
import 'package:RAS/ecrans/client/pagesu/reglement/factures.dart';
import 'package:RAS/ecrans/client/pagesu/articles/details.dart';
import 'package:RAS/ecrans/client/pagesu/articles/resultats.dart';
import 'package:RAS/ecrans/client/pagesu/principales/pageconnexion.dart';
import 'package:RAS/ecrans/client/pagesu/principales/pageinscription.dart';
import 'package:RAS/ecrans/client/pagesu/articles/voirplus.dart';
import 'package:RAS/ecrans/client/pagesu/reglement/paiement.dart';
import 'package:RAS/ecrans/client/pagesu/principales/ecrandemarrage.dart';
import 'package:RAS/ecrans/client/pagesu/reglement/chat.dart';
import 'package:RAS/ecrans/client/pagesu/principales/profil_simple.dart'; // Ajout de l'import du profil
import 'package:RAS/firebase_options.dart';
import 'package:RAS/services/synchronisation/synchronisation_service.dart';
import 'package:RAS/ecrans/client/pagesu/parametres/parametres.dart';
import 'package:RAS/ecrans/client/pagesu/parametres/parametres_profil.dart';
import 'package:RAS/ecrans/client/pagesu/parametres/parametres_discussions.dart';
import 'package:RAS/ecrans/client/pagesu/parametres/parametres_stats.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/admin': (context) => const Accueila(),
        '/utilisateur': (context) => const Accueilu(),
        '/utilisateur/recherche': (context) => const Resultats(),
        '/utilisateur/parametres': (context) => const ParametresPage(),
        '/utilisateur/parametres/profil':
            (context) => const ParametresProfilPage(),
        '/utilisateur/parametres/discussions':
            (context) => const ParametresDiscussionsPage(),
        '/utilisateur/parametres/statistiques':
            (context) => const ParametresStatsPage(),
        '/utilisateur/payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Commande) {
            return const Scaffold(
              body: Center(child: Text('Commande invalide')),
            );
          }
          return paiement(commande: args);
        },
        '/admin/nouveau produit': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const Pageconnexion();
          return const AjouterEquipPage();
        },
        '/connexion': (context) => const Pageconnexion(),
        '/inscription': (context) => const PageInscription(),
        '/utilisateur/commandes': (context) => const Commandes(),
        '/utilisateur/factures': (context) => const Factures(),
        '/utilisateur/produit/details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Produit) {
            return const Scaffold(
              body: Center(child: Text('Produit invalide')),
            );
          }
          return Details(produit: args);
        },
        '/utilisateur/chat': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const Pageconnexion();
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return ChatPage(
            idProduit: args['idProduit'] as String?,
            nomProduit: args['nomProduit'] as String?,
          );
        },
        '/utilisateur/profile':
            (context) => const ProfilePage(), // Ajout de la route du profil
        '/all_products': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text('Paramètres invalides')),
            );
          }
          final title = args['title'];
          final produits = args['produits'];
          if (title is! String || produits is! List<Produit>) {
            return const Scaffold(
              body: Center(child: Text('Paramètres invalides')),
            );
          }
          return Voirplus(title: title, produits: produits);
        },
      },
      onUnknownRoute:
          (_) => MaterialPageRoute(
            builder:
                (_) => const Scaffold(
                  body: Center(child: Text('Page introuvable')),
                ),
          ),
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
              child: 
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Vérification de l\'authentification...'),
                SizedBox(height: 20,),
                CircularProgressIndicator(),
              ],
            )),
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
