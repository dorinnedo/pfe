import 'package:flutter/material.dart';
import 'package:speedy2/common/color_extension.dart';
import '../../common_widget/round_botton.dart';
import '../../common_widget/round_textfield.dart';
import 'package:speedy2/view/login/login_view.dart';
import 'package:speedy2/view/login/welcome_view.dart';





class Otp  extends StatelessWidget {
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
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 25,horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 const SizedBox(height: 64,),

                // Logo + Background
            

                const SizedBox(height: 20),
                 Text(
                  "We have sent an OTP to your Mobile",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const Text(
                  "Please check your mobile number +2135******65\ncontinue to reset your password",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, ),
                ),

              
                const SizedBox(height: 70),
                
              

                
                // Bouton Login
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    child: RoundBotton(
                      title: "next",
                      onPressed: () {
                        
                      },
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
                        Text("Didn't Received?",
                            style: TextStyle(
                                color: TColor.secondaryText,
                                fontWeight: FontWeight.w500)),
                        Text(
                          "Click Here",
                          style: TextStyle(
                              color: TColor.primary,
                              fontWeight: FontWeight.w700),
                        )
                      ],
                    )),
                  
                   
                      
                     

                

                
              ],
            ),
            ),
          ),


          // 🔹 Ajout du bouton retour en haut !
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft, // Place en haut à gauche
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: IconButton(
                  icon:  Icon(Icons.arrow_back, size: 30, color: TColor.primary),
                  onPressed: () {
                    Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => WelcomeView()),
                        );  // Retourner à la page précédente
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
