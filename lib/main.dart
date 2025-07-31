import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/ecrans/admin/accueila.dart';
import 'package:ras_app/ecrans/client/accueilu.dart';
import 'package:ras_app/ecrans/admin/ajouterequip.dart';
import 'package:ras_app/ecrans/client/pagesu/details.dart';
import 'package:ras_app/ecrans/client/pagesu/resultats.dart';
import 'package:ras_app/ecrans/client/pagesu/voirplus.dart';
import 'package:ras_app/ecrans/ecrandemarrage.dart';
import 'package:ras_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

@override
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
      initialRoute: '/admin/nouveau produit',
      routes: {
        '/': (context) => const EcranDemarrage(),
        '/admin': (context) => const Accueila(),
        '/utilisateur': (context) => const Accueilu(),
        '/utilisateur/recherche' : (context) => const Resultats(),
        '/admin/nouveau produit': (context) => const AjouterEquipPage(),
        '/details': (context) {
          final produit = ModalRoute.of(context)!.settings.arguments as Produit;
          return Details(produit: produit);
        },
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
