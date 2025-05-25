import 'package:flutter/material.dart';
 
 class Homeadmin extends StatelessWidget {
   const Homeadmin({Key? key}) : super(key: key);
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('livreurPage'),
       ),
       body: const Center(
         child: Text('livreur page'),
       ),
     );
   }
 }