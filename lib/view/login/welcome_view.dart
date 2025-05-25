import 'package:flutter/material.dart';
import 'package:speedy2/common/color_extension.dart';
import 'package:speedy2/view/login/login_view.dart';
import 'package:speedy2/view/on_boarding/Startup_View.dart';
import 'package:speedy2/view/login/sign_up.dart';

import '../../common_widget/round_botton.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Image d'arrière-plan avec opacité
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

          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.all(0.0001), // Ajuste la hauteur du logo
              child: Image.asset(
                "assets/img/Speedy-removebg-preview.png",
                width: media.width, // Ajustement de la taille du logo
              ),
            ),
          ),

          // Boutons en bas
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding:
                  EdgeInsets.only(bottom: media.height * 0.1), // Marge en bas
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    child: RoundBotton(
                      title: "Login",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    child: RoundBotton(
                      title: "Create an account",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUp()),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    child: RoundBotton(
                      title: "Return",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StartupView()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
