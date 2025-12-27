import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'wrapper.dart'; // 👈 import your Wrapper

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  User? user;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    if (user != null && !user!.emailVerified) {
      user!.sendEmailVerification();
    }
  }

  Future<void> onVerifiedClicked() async {
    setState(() => isLoading = true);

    await user!.reload();
    user = FirebaseAuth.instance.currentUser;

    setState(() => isLoading = false);

    if (user!.emailVerified) {
      Get.offAll(() => const Wrapper());
    } else {
      Get.snackbar(
        "Email not verified",
        "Please verify your email before continuing.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Email Verification"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 80),
              const SizedBox(height: 20),

              const Text(
                "Verify your email",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              const Text(
                "Check your inbox and click the verification link.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: onVerifiedClicked,
                      child: const Text("I've verified my email"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
