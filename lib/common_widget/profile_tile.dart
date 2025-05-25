import 'package:flutter/material.dart';
import 'package:speedy2/common/color_extension.dart'; // Assure-toi d'importer ton fichier de couleurs

class ProfileTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: 30,
      right: 20,
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage("assets/img/item_2.png"),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Good Morning, ",
                        style:
                            TextStyle(color: TColor.primaryText, fontSize: 16),
                      ),
                      TextSpan(
                        text: "Ben Abdou",
                        style: TextStyle(
                            color: TColor.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Where are you going?",
                  style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class currentLocationIcon extends StatelessWidget {
  const currentLocationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8,right: 8),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: TColor.primary,
          child: Icon( Icons.my_location,color: Colors.white,),
        
        ),
      ),
    );
  }
}
