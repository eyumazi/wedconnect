import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/screens/Form%20Screens/weddingInfo.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: FutureBuilder(
        future: Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', uid)
            .single(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data as Map;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(profile['profile_image']),
              ),
              const SizedBox(height: 20),
              Text(
                profile['role'] == 'groom' ? "The Groom" : "The Bride",
                style: const TextStyle(fontSize: 20),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WeddingInfo()),
                  );
                },
                child: const Text("Proceed to Wedding Info"),
              ),
            ],
          );
        },
      ),
    );
  }
}
