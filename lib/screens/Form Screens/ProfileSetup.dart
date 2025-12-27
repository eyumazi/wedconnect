import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Reusable%20components/Button2.dart';
import 'package:wedconnect/Util.dart';
import 'package:wedconnect/screens/Form%20Screens/ProfileViewScreen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  Uint8List? _image;
  String _role = 'groom';

  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> selectImage() async {
    final img = await pickImage(ImageSource.gallery);
    if (img != null) {
      setState(() => _image = img);
    }
  }

  Future<void> saveProfile() async {
    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select a profile picture")));
      return;
    }

    final path = '$uid/profile.png';

    try {
      await supabase.storage
          .from('profile-pictures')
          .uploadBinary(
            path,
            _image!,
            fileOptions: const FileOptions(
              //contentType: 'image/png',
              upsert: true,
            ),
          );

      final imageUrl = supabase.storage
          .from('profile-pictures')
          .getPublicUrl(path);

      await supabase.from('profiles').upsert({
        'id': uid,
        'role': _role,
        'profile_image': imageUrl,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileViewScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/Background/Bg1.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Make Scaffold background transparent
        appBar: AppBar(
          title: Text(
            "Setup your profile",
            style: GoogleFonts.cormorantGaramond(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor:
              Colors.transparent, // Optional: make appbar transparent too
          elevation: 0, // Remove shadow
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: selectImage,
              child: CircleAvatar(
                radius: 75,
                backgroundImage: _image != null ? MemoryImage(_image!) : null,
                backgroundColor: Color(0xFFFE96AF),
                child: _image == null
                    ? const Icon(Icons.add_a_photo_rounded, size: 45)
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.5,
                    ), // Reduced opacity here directly
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Kindly Specify our title",
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            //Choice for the groom
                            width: 170,
                            height: 150,
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: 0,
                                  right: 3,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _role = 'groom';
                                      });
                                    },
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: _role == 'groom'
                                          ? Color(0xFFFE96AF)
                                          : Colors.grey,
                                      child: Text(
                                        "The Groom",
                                        style: GoogleFonts.allura(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: _role == 'groom'
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -15,
                                  top: 20,
                                  child: Image.asset(
                                    "assets/images/groom.png",
                                    height: 120,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          //const SizedBox(width: 30),
                          SizedBox(
                            //Choice for the groom
                            width: 180,
                            height: 150,
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _role = 'bride';
                                      });
                                    },
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: _role == 'bride'
                                          ? Color(0xFFFE96AF)
                                          : Colors.grey,
                                      child: Text(
                                        "The Bride",
                                        style: GoogleFonts.allura(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: _role == 'bride'
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -10,
                                  top: 20,
                                  child: Image.asset(
                                    "assets/images/bride.png",
                                    height: 120,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CustomElevatedButton2(
              text: "Continue to Wedding Setup",
              onPressed: () {
                saveProfile();
              },
            ),
          ],
        ),
      ),
    );
  }
}
