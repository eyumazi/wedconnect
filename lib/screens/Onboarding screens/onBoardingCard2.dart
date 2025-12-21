import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Onboardingcard2 extends StatelessWidget {
  const Onboardingcard2({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.Button,
  });

  final String image, title, description;
  final Widget Button;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE3EF),
      body: Center(
        child: Container(
          margin: EdgeInsets.only(top: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Image.asset(image),
                  SizedBox(height: 25),
                  Column(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5AA0D6),
                        ),
                      ),
                      SizedBox(height: 15),
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          textAlign: TextAlign.center,
                          description,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5AA0D6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(child: Column(children: [Button])),
            ],
          ),
        ),
      ),
    );
  }
}
