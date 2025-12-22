import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wedconnect/Authentication/Homepage%20text.dart';
import 'package:wedconnect/Authentication/login.dart';

// import your screens
// import 'home_screen.dart';
// import 'login_screen.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return const Center(
              child: Icon(Icons.error_outline, size: 40, color: Colors.red),
            );
          }

          // User logged in
          if (snapshot.hasData) {
            if (snapshot.data!.emailVerified) {
              return HomepageTest();
            } else {
              return 
            }
          }

          // User not logged in
          return Login();
        },
      ),
    );
  }
}
