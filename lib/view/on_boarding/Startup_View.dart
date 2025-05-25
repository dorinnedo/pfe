import 'package:flutter/material.dart';
import 'package:speedy2/view/login/welcome_view.dart';

import '../../common/color_extension.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key});

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  @override
  

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
        body: Stack(
        
      
      children: [
        Positioned.fill(child: Opacity(opacity: 0.4,child: Image.asset(
          "assets/img/Pattern.png",
          
          width: media.width ,
          height: media.height,
          fit: BoxFit.contain,
        ),),),
        Center(
          
          child:Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 300,height: 500,
              child: Image.asset(
          "assets/img/Speedy-removebg-preview.png",
        ),),
        
      
          Text("🚀Fast, Fresh, Delivered."),
          Text("📦Your Delivery, Your Way."),
          Text("⚡Speed Meets Convenience."),
          Text("🍽️ From Door to Door, in No Time."),
          Text("🛵 Quick. Reliable. At Your Doorstep."),
          SizedBox(height: 50,),
          Center( // Pour centrer le bouton
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomeView()),
                  );
                },style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: TColor.primary, // Couleur du bouton
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Get started",
                  style: TextStyle(fontSize: 18, color: Colors.white),
              ),),),
        SizedBox(height: 50,),
        Text("developped by dorinnedo."),
            ],
          )
        
        )
        
        
      ],
    ));
  }
}
