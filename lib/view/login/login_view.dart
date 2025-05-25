import 'package:flutter/material.dart';
import 'package:speedy2/common/color_extension.dart';
import 'package:speedy2/view/home/home.dart';
import 'package:speedy2/view/home/homeclient.dart';
import 'package:speedy2/view/home/homeadmin.dart';
import '../../common_widget/round_botton.dart';
import '../../common_widget/round_textfield.dart';
import 'package:speedy2/view/login/sign_up.dart';
import 'package:speedy2/view/login/welcome_view.dart';
import 'package:speedy2/view/login/reset.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                "assets/img/Pattern.png",
                width: media.width,
                height: media.height,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: media.height * 0.12),
                SizedBox(
                  height: media.height * 0.3,
                  child: FittedBox(
                    fit: BoxFit.none,
                    child: Image.asset(
                      "assets/img/Speedy-removebg-preview.png",
                      width: media.width,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Login To Your Account",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                RoundTextfield(
                  hintText: "Email",
                  controller: txtEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                RoundTextfield(
                  hintText: "Password",
                  controller: txtPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 15),
                Text("Or Continue With", style: TextStyle(color: TColor.primary)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton("Facebook", "assets/img/facebook_logo.png"),
                    const SizedBox(width: 10),
                    _buildSocialButton("Google", "assets/img/google_logo.png"),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Reset()));
                  },
                  child: Text("Forgot Your Password?", style: TextStyle(color: TColor.primary)),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: RoundBotton(
                    title: "Login",
                    onPressed: () async {
                      final email = txtEmail.text.trim();
                      final password = txtPassword.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please enter both email and password.")),
                        );
                        return;
                      }

                      try {
                        UserCredential userCredential = await FirebaseAuth.instance
                            .signInWithEmailAndPassword(email: email, password: password);

                        DocumentSnapshot userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userCredential.user!.uid)
                            .get();

                        if (userDoc.exists) {
                          String role = userDoc.get('role');

                          if (role == 'client') {
                            Navigator.pushReplacement(
                                context, MaterialPageRoute(builder: (_) => HomeClient()));
                          } else if (role == 'livreur') {
                            Navigator.pushReplacement(
                                context, MaterialPageRoute(builder: (_) => HomeLivreur()));
                          } else if (role == 'admin') {
                            Navigator.pushReplacement(
                                context, MaterialPageRoute(builder: (_) => Homeadmin()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Unknown role: $role")),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("User document not found.")),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Login failed: $e")),
                        );
                      }
                    },
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignUp()));
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Don't have an Account?",
                          style: TextStyle(
                              color: TColor.secondaryText, fontWeight: FontWeight.w500)),
                      Text(
                        " Sign Up",
                        style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w700),
                      )
                    ],
                  ),
                ),
                SizedBox(height: media.height * 0.1),
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: 30, color: TColor.primary),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WelcomeView()));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String text, String iconPath) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: TColor.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: () {},
      icon: Image.asset(iconPath, width: 20),
      label: Text(text, style: TextStyle(color: TColor.white)),
    );
  }
}
