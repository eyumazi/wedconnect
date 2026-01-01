import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeddingCoverUpload extends StatefulWidget {
  const WeddingCoverUpload({super.key});

  @override
  State<WeddingCoverUpload> createState() => _WeddingCoverUploadState();
}

class _WeddingCoverUploadState extends State<WeddingCoverUpload> {
  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  File? coverImage;
  bool uploading = false;

  Future<void> pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => coverImage = File(picked.path));
    }
  }

  Future<void> uploadCoverImage() async {
    if (coverImage == null) return;

    setState(() => uploading = true);

    final ext = coverImage!.path.split('.').last;
    final path = '$uid/cover.$ext';

    try {
      await supabase.storage
          .from('wedding-covers')
          .upload(
            path,
            coverImage!,
            fileOptions: const FileOptions(upsert: true),
          );
      final imageUrl = supabase.storage
          .from('wedding-covers')
          .getPublicUrl(path);

      await supabase
          .from('weddings')
          .update({'cover_image_url': imageUrl})
          .eq('user_id', uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cover uploaded successfully")),
        );
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to upload cover")));
      }
    }

    if (mounted) setState(() => uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7EB3DB),
      appBar: AppBar(
        title: Text(
          "Theme & cover",
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Upload your favorite cover photo",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _hintText(
                    "Your cover photo will be used to construct your wedding wizard",
                  ),
                  const SizedBox(height: 20),

                  /// Preview
                  GestureDetector(
                    onTap: pickCoverImage,
                    child: Container(
                      height: 700,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[900],
                        image: coverImage != null
                            ? DecorationImage(
                                image: FileImage(coverImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: coverImage == null
                          ? const Center(
                              child: Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Colors.white,
                                size: 150,
                              ),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Upload Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: coverImage == null || uploading
                          ? null
                          : uploadCoverImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Upload Cover",
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (uploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hintText(String text) {
    return Text(
      text,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: Colors.white,
      ),
    );
  }
}
