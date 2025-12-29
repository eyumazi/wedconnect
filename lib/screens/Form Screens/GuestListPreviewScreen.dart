import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuestPreviewScreen extends StatefulWidget {
  const GuestPreviewScreen({super.key});

  @override
  State<GuestPreviewScreen> createState() => _GuestPreviewScreenState();
}

class _GuestPreviewScreenState extends State<GuestPreviewScreen> {
  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  late Future<List<dynamic>> guests;

  @override
  void initState() {
    super.initState();
    guests = fetchGuests();
  }

  Future<List<dynamic>> fetchGuests() async {
    return await supabase
        .from('guests')
        .select()
        .eq('user_id', uid)
        .order('created_at');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7EB3DB),
      appBar: AppBar(
        title: Text(
          "Guest List Preview",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: guests,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(child: Text("No guests added yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final guest = data[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: guest['guest_photo_url'] != null
                        ? NetworkImage(guest['guest_photo_url'])
                        : null,
                    child: guest['photo_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    guest['guest_name'],
                    style: GoogleFonts.cormorantGaramond(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(guest['phone_number']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
