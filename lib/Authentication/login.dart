import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wedconnect/Authentication/ForgotPassword.dart';
import 'package:wedconnect/Authentication/signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  signin() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
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
          SizedBox(height: 30),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(hintText: "Enter Password"),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              signin();
            },
            child: Text("Login"),
          ),
          SizedBox(height: 30),
          TextButton(
            onPressed: () => Get.to(Signup()),
            child: Text("Register Now"),
          ),
          SizedBox(height: 30),
          TextButton(
            onPressed: () => Get.to(Forgotpassword()),
            child: Text("Forgotten password"),
          ),
        ],
      ),
    );
  }
}
