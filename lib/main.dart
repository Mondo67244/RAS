import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ras_app/ecrans/admin/accueila.dart';
import 'package:ras_app/ecrans/client/accueilu.dart';
import 'package:ras_app/ecrans/ecranDemarrage.dart';
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
      title: 'RAS App',
      initialRoute: '/',
      routes: {
        '/': (context) => const EcranDemarrage(),
        '/admin': (context) => const Accueila(),
        '/user': (context) => const Accueilu(),
      },
    );
  }
}
