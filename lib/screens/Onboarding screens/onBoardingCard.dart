import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wedconnect/Reusable%20components/Button.dart';
import 'package:wedconnect/screens/Onboarding%20screens/onBoardingCard2.dart';

import '../../Authentication/login.dart';

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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Image.asset(image),
                  SizedBox(height: 25),
                  Column(
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        title,
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
                          description,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFC19AC7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                child: Column(
                  children: [
                    Button,
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: TextButton(
                        onPressed: () {
                          // Using GetX instead of Navigator
                          Get.off(
                            () => Onboardingcard2(
                              image: "assets/images/logo.png",
                              title: "Your Wedding, Your Style",
                              description:
                                  "Create your account and customize\n your wedding space to make the\n app truly yours.",
                              Button: CustomElevatedButton(
                                text: "Get Started",
                                onPressed: () {
                                  Get.offAll(() => Login());
                                },
                              ),
                            ),
                          );
                        },
                        child: Text("Skip"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
