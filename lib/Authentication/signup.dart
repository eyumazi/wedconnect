import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wedconnect/Authentication/Wrapper.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  signup() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );
    Get.offAll(Wrapper());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("sign Up")),
      body: Column(
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(hintText: "Enter email"),
          ),
          SizedBox(height: 20),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(hintText: "Enter Password"),
          ),
          ElevatedButton(
            onPressed: () {
              signup();
            },
            child: Text("Sign up"),
          ),
        ],
      ),
    );
    ;
  }
}
