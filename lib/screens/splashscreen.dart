import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wedconnect/screens/Onboarding%20screens/onboarding%201.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({Key? key}) : super(key: key);

  @override
  State<Splashscreen> createState() => _Splashscreen();
}

class _Splashscreen extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Onboarding1()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE3EF),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Image.asset("assets/images/Flower 1.png"),
          ),
          Align(
            alignment: Alignment.center,
            child: Image.asset("assets/images/logo.png"),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset("assets/images/Flower 2.png"),
          ),
        ],
      ),
    );
  }
}
