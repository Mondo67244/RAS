import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/ecrans/client/accueilU.dart';

class EcranDemarrage extends StatefulWidget {
  const EcranDemarrage({super.key});

  @override
  State<EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends State<EcranDemarrage> {

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3)
    ,
    (){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Accueilu()));
    }
    );
    _getInitialRoute();
  }

  

  Future<String> _getInitialRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('Utilisateur')
              .doc(user.uid)
              .get();
      final role = userDoc.data()?['role'];
      if (role == 'admin') return '/admin';
      if (role == 'utilisateur') return '/user';
    }
    return '/user';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 163, 14, 3),
      body: Center(
          child: Column(
            children: [
              const SizedBox(height: 350,),
              Container(
                width: 180,
                height: 100,
                child: Image.asset('assets/images/kanjad.png'),
              ),
              Text('Un instant...',style: TextStyle(color: Colors.white),),
              const SizedBox(height: 10,),
              CircularProgressIndicator(color: Colors.white,),
            ],
          ),
        ),
      
    );
  }
}
