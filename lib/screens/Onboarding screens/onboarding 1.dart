import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wedconnect/Reusable%20components/Button.dart';
import 'package:wedconnect/screens/Onboarding%20screens/OnboardingPage.dart';

class Onboarding1 extends StatefulWidget {
  const Onboarding1({super.key});

  @override
  State<Onboarding1> createState() => _Onboarding1State();
}

class _Onboarding1State extends State<Onboarding1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE3EF),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.max,
        children: [
          Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 160,
                  height: 160,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -20), // Move text UP by 20 pixels
                child: Text(
                  "Wed Connect",
                  style: GoogleFonts.inspiration(
                    fontSize: 45,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5AA0D6),
                    shadows: [
                      Shadow(
                        color: Color.fromRGBO(0, 0, 0, 0.4),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              //then to the texts following the logo.
              Transform.translate(
                offset: const Offset(0, 60), // Move text down by 60 pixels
                child: Text(
                  "Welcome to the Wedding Hub!",
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF5AA0D6),
                  ),
                ),
              ),

              Transform.translate(
                offset: const Offset(0, 85),
                child: Opacity(
                  opacity: 0.6,
                  child: Text(
                    textAlign: TextAlign.center,
                    "All your wedding moments,\n updates, and memories beautifully\n organized in one place.",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5AA0D6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, 100),
            child: CustomElevatedButton(
              text: "Continue",
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 800),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const OnboardingPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          final fadeAnimation = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );

                          final slideAnimation = Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(fadeAnimation);

                          return FadeTransition(
                            opacity: fadeAnimation,
                            child: SlideTransition(
                              position: slideAnimation,
                              child: child,
                            ),
                          );
                        },
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Image.asset("assets/images/Flower 1.png"),
          ),
        ],
      ),
    );
  }
}
