import 'package:flutter/material.dart';

import '../common/color_extension.dart';


class RoundBotton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  const RoundBotton({super.key,required this.title,required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TColor.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          title,
          style: TextStyle(
              color: TColor.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}