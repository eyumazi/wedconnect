import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Authentication/Wrapper.dart';
import 'package:wedconnect/Util.dart';

class HomepageTest extends StatefulWidget {
  const HomepageTest({super.key});

  @override
  State<HomepageTest> createState() => _HomepageTestState();
}

signout() async {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  await googleSignIn.signOut();
  await FirebaseAuth.instance.signOut();
  Get.offAll(Wrapper());
}

class _HomepageTestState extends State<HomepageTest> {
  final user = FirebaseAuth.instance.currentUser;
  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  late Future<List<dynamic>> coverPhoto;

  @override
  void initState() {
    super.initState();
    coverPhoto = fetchCoverPhoto();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Page")),
      body: Column(
        children: [
          FutureBuilder(
            future: coverPhoto,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;

              return ListView.builder(
                itemBuilder: (context, index) {
                  final coverUrl = data[index];
                  return Image.network(coverUrl['cover_photo_url']);
                },
                itemCount: data.length,
                shrinkWrap: true,
              );
            },
          ),
          Center(child: Text('${user!.email}')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          signout();
        },
        child: Icon(Icons.login_rounded),
      ),
    );
  }
}
