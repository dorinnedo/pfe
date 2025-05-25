import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelectRoleView extends StatelessWidget {
  final User user;

  SelectRoleView({required this.user});

  void _setRole(BuildContext context, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': role,
    });

    // توجيه حسب الدور
    if (role == 'client') {
      Navigator.pushReplacementNamed(context, '/client');
    } else if (role == 'livreur') {
      Navigator.pushReplacementNamed(context, '/livreur');
    } else {
      Navigator.pushReplacementNamed(context, '/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose your role")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRoleButton(context, "Client", "client"),
          _buildRoleButton(context, "Livreur", "livreur"),
          _buildRoleButton(context, "Admin", "admin"),
        ],
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String label, String role) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () => _setRole(context, role),
        child: Text(label),
      ),
    );
  }
}
