import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speedy2/common/color_extension.dart';
import 'package:speedy2/view/login/otp.dart';
import '../../common_widget/round_botton.dart';
import '../../common_widget/round_textfield.dart';
import 'package:speedy2/view/login/login_view.dart';
import 'package:speedy2/view/login/welcome_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  final TextEditingController txtName = TextEditingController();
  final TextEditingController txtMobile = TextEditingController();
  final TextEditingController txtAddress = TextEditingController();
  final TextEditingController txtConfirmPassword = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // For Role Selection
  String _selectedRole = 'client';

  Future<void> _signUp() async {
    if (txtPassword.text != txtConfirmPassword.text) {
      // Show error if passwords don't match
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: txtEmail.text,
        password: txtPassword.text,
      );

      // Save user details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'name': txtName.text,
        'email': txtEmail.text,
        'mobile': txtMobile.text,
        'address': txtAddress.text,
        'role': _selectedRole, // Save the selected role
      });

      // Navigate to OTP page after successful registration
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Otp()),
      );
    } catch (e) {
      // Show error if something goes wrong
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

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
                  height: media.height * 0.15,
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
                  "Sign Up",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                RoundTextfield(
                  hintText: "Full Name",
                  controller: txtName,
                ),
                const SizedBox(height: 20),
                RoundTextfield(
                  hintText: "Email",
                  controller: txtEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                RoundTextfield(
                  hintText: "Mobile Number",
                  controller: txtMobile,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                RoundTextfield(
                  hintText: "Address",
                  controller: txtAddress,
                ),
                const SizedBox(height: 20),
                RoundTextfield(
                  hintText: "Password",
                  controller: txtPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                RoundTextfield(
                  hintText: "Confirm Password",
                  controller: txtConfirmPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                // Role selection dropdown
                DropdownButton<String>(
                  value: _selectedRole,
                  items: <String>['client', 'livreur', 'admin']
                      .map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: RoundBotton(
                    title: "Sign Up",
                    onPressed: _signUp,
                  ),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Already have an Account?",
                            style: TextStyle(
                                color: TColor.secondaryText,
                                fontWeight: FontWeight.w500)),
                        Text(
                          "Login",
                          style: TextStyle(
                              color: TColor.primary,
                              fontWeight: FontWeight.w700),
                        )
                      ],
                    )),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomeView()),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
