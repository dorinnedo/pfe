import 'package:flutter/material.dart';
import 'package:speedy2/common/color_extension.dart';
import 'package:speedy2/view/login/new_password.dart';
import '../../common_widget/round_botton.dart';
import '../../common_widget/round_textfield.dart';
import 'package:speedy2/view/login/login_view.dart';
import 'package:speedy2/view/login/welcome_view.dart';

class Reset extends StatelessWidget {
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  final TextEditingController txtName = TextEditingController();
  final TextEditingController txtmobile = TextEditingController();
  final TextEditingController txtaddress = TextEditingController();
  final TextEditingController txtconfirmPassword = TextEditingController();

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
                fit: BoxFit.cover, // Modification pour bien remplir l'écran
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: media.height * 0.12), // Espace du haut

                // Logo + Background

                const SizedBox(height: 20),
                const Text(
                  "Reset Password",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const Text(
                  "Please enter your phone number to \nreceive a link to create anew password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                const SizedBox(height: 20),

                const SizedBox(height: 20),
                RoundTextfield(
                  hintText: "Mobile Number",
                  controller: txtmobile,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // Bouton Login
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: RoundBotton(
                    title: "Send",
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NewPassword()));
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Ajout du bouton retour en haut !
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft, // Place en haut à gauche
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: 30, color: TColor.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomeView()),
                    ); // Retourner à la page précédente
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
