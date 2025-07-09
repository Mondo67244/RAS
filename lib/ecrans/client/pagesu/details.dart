import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';

class Details extends StatelessWidget {
  const Details({super.key,required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              child: Image.asset(
                'assets/images/05.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Text(produit.nomProduit,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
            Text(produit.description,style: TextStyle(fontSize: 15),),
          ],
        ),
      ),
      appBar: AppBar(
        foregroundColor: style.blanc,
        title: Text('Détails de l\'article',style: TextStyle(color: Colors.white),),
        backgroundColor: style.rouge,
        
      ),
      
    );
  }
}