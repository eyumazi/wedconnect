import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomepageTest extends StatefulWidget {
  const HomepageTest({super.key});

  @override
  State<HomepageTest> createState() => _HomepageTestState();
}

final user = FirebaseAuth.instance.currentUser;

signout() async {
  await FirebaseAuth.instance.signOut();
}

class _HomepageTestState extends State<HomepageTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Page")),
      body: Center(child: Text('${user!.email}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          signout();
        },
        child: Icon(Icons.login_rounded),
      ),
    );
  }
}
