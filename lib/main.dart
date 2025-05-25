import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speedy2/view/home/home.dart';
import 'package:speedy2/view/home/homeadmin.dart';
import 'package:speedy2/view/on_boarding/startup_view.dart';
import 'package:speedy2/view/home/homeclient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _handleLocationPermission(); // <-- طلب الإذن قبل تشغيل التطبيق
  runApp(const MyApp());
}

// ⛳️ تحقق من إذن الموقع وافتح الإعدادات إذا لزم
Future<void> _handleLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings(); // يفتح إعدادات الموقع
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    // يمكن عرض AlertDialog لاحقًا داخل الصفحة إذا حبيت
    debugPrint("Location permission is permanently denied.");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc['role']; // Get the role from Firestore
      }
    }
    return ''; // Return empty if user is not found or role is not set
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Metropolis",
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<String>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const StartupView(); // شاشة التحميل
          }

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            String role = snapshot.data!;
            if (role == 'client') {
              return HomeClient();
            } else if (role == 'livreur') {
              return HomeLivreur();
            } else if (role == 'admin') {
              return Homeadmin();
            }
          }

          return const StartupView(); // إذا ما فيه دور
        },
      ),
    );
  }
}
