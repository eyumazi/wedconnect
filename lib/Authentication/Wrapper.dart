import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wedconnect/Authentication/EmailVerification.dart';
import 'package:wedconnect/screens/main%20screens/HomeScreen.dart';
import 'package:wedconnect/screens/splashscreen.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Icon(Icons.error_outline, size: 40, color: Colors.red),
            );
          }
          if (snapshot.hasData) {
            if (snapshot.data!.emailVerified) {
              return HomeScreen();
            } else {
              return EmailVerification();
            }
          }
          return Splashscreen();
        },
      ),
    );
  }
}
