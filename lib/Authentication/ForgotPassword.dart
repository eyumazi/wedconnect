import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Forgotpassword extends StatefulWidget {
  const Forgotpassword({super.key});

  @override
  State<Forgotpassword> createState() => _ForgotpasswordState();
}

class _ForgotpasswordState extends State<Forgotpassword> {
  TextEditingController emailController = TextEditingController();

  forgotPassowrd() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Column(
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(hintText: "Enter email"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              forgotPassowrd();
            },
            child: Text("Send Reset link"),
          ),
        ],
      ),
    );
  }
}
