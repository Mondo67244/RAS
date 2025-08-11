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
import 'package:provider/provider.dart';
import 'package:RAS/services/synchronisation/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Royal Advance Services',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF990000)),
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == 'utilisateur/produit/details') {
          final args = settings.arguments as Produit;
          return MaterialPageRoute(
            builder: (context) {
              return Details(produit: args);
            },
          );
        }
        
        // Gestion des autres routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const EcranDemarrage());
          case '/accueil':
            return MaterialPageRoute(builder: (context) => const Accueilu());
          case '/connexion':
            return MaterialPageRoute(builder: (context) => const Pageconnexion());
          case '/inscription':
            return MaterialPageRoute(builder: (context) => const PageInscription());
          case '/admin/accueil':
            return MaterialPageRoute(builder: (context) => const Accueila());
          case '/admin/ajouterequip':
            return MaterialPageRoute(builder: (context) => const AjouterEquipPage());
          case '/utilisateur/commandes':
            return MaterialPageRoute(builder: (context) => const Commandes());
          case '/utilisateur/factures':
            return MaterialPageRoute(builder: (context) => const Factures());
          case '/utilisateur/chat':
            return MaterialPageRoute(builder: (context) => const ChatPage());
          case '/utilisateur/profile':
            return MaterialPageRoute(builder: (context) => const ProfilePage());
          case '/utilisateur/parametres':
            return MaterialPageRoute(builder: (context) => const ParametresPage());
          case '/utilisateur/parametres/profil':
            return MaterialPageRoute(builder: (context) => const ParametresProfilPage());
          case '/utilisateur/parametres/discussions':
            return MaterialPageRoute(builder: (context) => const ParametresDiscussionsPage());
          case '/utilisateur/parametres/stats':
            return MaterialPageRoute(builder: (context) => const ParametresStatsPage());
          case '/utilisateur/recherche':
            return MaterialPageRoute(builder: (context) => const Resultats());
          case '/utilisateur/produits/details':
            // return MaterialPageRoute(builder: (context) => const Details(produit: args,));
          default:
            return MaterialPageRoute(builder: (context) => const EcranDemarrage());
        }
      },
    );
  }
}