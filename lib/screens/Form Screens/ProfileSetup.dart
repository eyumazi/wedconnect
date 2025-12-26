import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Util.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final nameController = TextEditingController();
  final bioController = TextEditingController();

  Uint8List? _image;

  Future<void> selectImage() async {
    final Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  Future<void> uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = 'profiles/$fileName.png';

    try {
      await Supabase.instance.client.storage
          .from('Images')
          .uploadBinary(
            path,
            _image!,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload successful ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed ❌: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Setup")),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundImage: _image != null
                        ? MemoryImage(_image!)
                        : const NetworkImage(
                                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQWr8eIHKJb-KDs4GE5UqnO6MREzIfetisirw&s",
                              )
                              as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.add_a_photo),
                      onPressed: selectImage,
                    ),
                  ),
                ],
              ),
              // Padding(
              //   padding: const EdgeInsets.all(20),
              //   child: TextField(
              //     controller: nameController,
              //     decoration: const InputDecoration(
              //       hintText: "Enter your name",
              //     ),
              //   ),
              // ),
              // Padding(
              //   padding: const EdgeInsets.all(20),
              //   child: TextField(
              //     controller: bioController,
              //     decoration: const InputDecoration(
              //       hintText: "Enter your bio",
              //     ),
              //   ),
              // ),
              ElevatedButton(
                onPressed: uploadImage,
                child: const Text("Save Information"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
