import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:wedconnect/Reusable%20components/Button.dart';
import 'package:wedconnect/screens/Onboarding%20screens/onBoardingCard.dart';
import 'package:wedconnect/screens/Onboarding%20screens/onBoardingCard2.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final List<Widget> _onBoardingPages = [
    Onboardingcard(
      image: "assets/onboarding/weddingDay.png",
      title: "Live Updates & Timeline",
      description:
          "Track the ceremony schedule,\n reception highlights, and important\n announcements in real time.",
      Button: CustomElevatedButton(
        text: "Next",
        onPressed: () {
          _pageController.animateToPage(
            1,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInToLinear,
          );
        },
      ),
    ),
    Onboardingcard(
      image: "assets/onboarding/qr.png",
      title: "Smart QR Wedding Invitation",
      description:
          "Send and receive elegant digital invites with secure QR access for guests.",
      Button: CustomElevatedButton(
        text: "Next",
        onPressed: () {
          _pageController.animateToPage(
            2,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInToLinear,
          );
        },
      ),
    ),
    Onboardingcard(
      image: "assets/onboarding/qr.png",
      title: "Smart QR Wedding Invitation",
      description:
          "Send and receive elegant digital invites with secure QR access for guests.",
      Button: CustomElevatedButton(
        text: "Next",
        onPressed: () {
          _pageController.animateToPage(
            3,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInToLinear,
          );
        },
      ),
    ),
    Onboardingcard(
      image: "assets/onboarding/Photo Gallery.png",
      title: "Capture & Share Memories Together",
      description:
          "Guests can upload photos instantly and relive the celebration as it unfolds.",
      Button: CustomElevatedButton(
        text: "Next",
        onPressed: () {
          _pageController.animateToPage(
            4,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInToLinear,
          );
        },
      ),
    ),
    Onboardingcard(
      image: "assets/onboarding/Heart.png",
      title: "A Guestbook Filled With Love",
      description:
          "Collect heartfelt messages and blessings from your guests—stored forever.",
      Button: CustomElevatedButton(
        text: "Next",
        onPressed: () {
          _pageController.animateToPage(
            5,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInToLinear,
          );
        },
      ),
    ),
    Onboardingcard2(
      image: "assets/onboarding/App logo.png",
      title: "Your Wedding, Your Style",
      description:
          "Create your account and customize\n your wedding space to make the\n app truly yours.",
      Button: CustomElevatedButton(
        text: "Get Started",
        onPressed: () {
          _pageController.animateToPage(
            1,
            duration: Duration(milliseconds: 400),
            curve: Curves.linear,
          );
        },
      ),
    ),
  ];

  static final PageController _pageController = PageController(initialPage: 0);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE3EF),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                children: _onBoardingPages,
              ),
            ),
            SmoothPageIndicator(controller: _pageController, count: 6),
          ],
        ),
      ),
    );
  }
}
