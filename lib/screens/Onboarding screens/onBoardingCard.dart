import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Onboardingcard extends StatelessWidget {
  const Onboardingcard({
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
            children: [
              Image.asset(image),
              SizedBox(height: 25),
              Column(
                children: [
                  Text(
                    "Live Updates & Timeline",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC19AC7),
                    ),
                  ),
                  SizedBox(height: 15),
                  Opacity(
                    opacity: 0.6,
                    child: Text(
                      textAlign: TextAlign.center,
                      "Track the ceremony schedule,\n reception highlights, and important\n announcements in real time.",
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFC19AC7),
                      ),
                    ),
                  ),
                ],
              ),
              Container(),
            ],
          ),
        ),
      ),
    );
  }
}
