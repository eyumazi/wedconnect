import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Reusable%20components/Button2.dart';
import 'package:wedconnect/Reusable%20components/CustomUploadingButton.dart';
import 'package:wedconnect/Util.dart' show pickImage;

class Guestlistform extends StatefulWidget {
  const Guestlistform({super.key});

  @override
  State<Guestlistform> createState() => _GuestlistformState();
}

class _GuestlistformState extends State<Guestlistform> {
  final guestNameController = TextEditingController();
  final guestPhoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Uint8List? guestPhoto;
  bool saving = false;

  Future<void> pickGuestPhoto() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () async {
                  Navigator.pop(context);

                  final Uint8List? image = await pickImage(ImageSource.camera);

                  if (image != null) {
                    setState(() {
                      guestPhoto = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context);

                  final Uint8List? image = await pickImage(ImageSource.gallery);

                  if (image != null) {
                    setState(() {
                      guestPhoto = image;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> saveGuest() async {
    if (guestNameController.text.isEmpty || guestPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => saving = true);

    final path = '$uid/guests/${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      /// Upload photo if exists
      if (guestPhoto != null) {
        await supabase.storage
            .from('guest-photos')
            .uploadBinary(
              path,
              guestPhoto!,
              fileOptions: const FileOptions(upsert: true),
            );
      }
      final photoUrl = supabase.storage.from('guest-photos').getPublicUrl(path);

      /// Insert guest
      await supabase.from('guests').insert({
        'user_id': uid,
        'guest_name': guestNameController.text,
        'phone_number': guestPhoneController.text,
        'guest_photo_url': photoUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Guest save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving guest: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => saving = false);
    }
  }

  //saveGuestOnly method is used by Save Guest button to only add a single guest
  Future<void> saveGuestOnly() async {
    if (guestNameController.text.isEmpty || guestPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => saving = true);

    final path = '$uid/guests/${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      /// Upload photo if exists
      if (guestPhoto != null) {
        await supabase.storage
            .from('guest-photos')
            .uploadBinary(
              path,
              guestPhoto!,
              fileOptions: const FileOptions(upsert: true),
            );
      }
      final photoUrl = supabase.storage.from('guest-photos').getPublicUrl(path);

      /// Insert guest
      await supabase.from('guests').insert({
        'user_id': uid,
        'guest_name': guestNameController.text,
        'phone_number': guestPhoneController.text,
        'guest_photo_url': photoUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Guest save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving guest: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => saving = false);
    }
  }

  void _saveAndContinue() {
    saveGuest();
  }

  void _clearForm() {
    guestNameController.clear();
    guestPhoneController.clear();
    setState(() {
      guestPhoto = null;
    });
  }

  void _save() {
    saveGuestOnly();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget addText(String text, double size) {
    return Text(
      text,
      style: GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7EB3DB),
      appBar: AppBar(
        title: Text(
          "Invitation and Guest List",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              width: 380,
              height: 600,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xFFFFE3EF),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  addText("Add Guest", 18),
                  Align(
                    alignment: Alignment.topLeft,
                    child: addText(
                      "You can clear the form and add as much guests you like",
                      15,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: guestNameController,
                    decoration: _inputDecoration("Guest Full Name"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: guestPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration("Phone Number"),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: pickGuestPhoto,
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(
                                0xFF7158E2,
                              ).withOpacity(0.5),
                              backgroundImage: guestPhoto != null
                                  ? MemoryImage(guestPhoto!)
                                  : null,
                              child: guestPhoto == null
                                  ? const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                            if (guestPhoto != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      guestPhoto = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              addText("Add Photo", 15),
                              const Text(
                                "Optional – helps identify guest",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              if (guestPhoto != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Photo selected ✓",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  CustomUploadingButton(
                    text: "Save Guest",
                    onPressed: () {
                      saving ? null : _save();
                    },
                    isLoading: saving,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            saving ? null : _clearForm();
                          },
                          child: const Text(
                            "Clear Form",
                            style: TextStyle(
                              color: Color(0xFF7158E2),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(onPressed: () {}, child: Text("Skip")),
            SizedBox(height: 30),
            CustomElevatedButton2(
              text: "Continue to Dashboard",
              onPressed: _saveAndContinue,
            ),
          ],
        ),
      ),
    );
  }
}
