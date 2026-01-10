import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart'
    show Uint8List;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Util.dart' show pickImage;

class Signboardscreen extends StatefulWidget {
  final String guestId; // UUID from QR scan

  const Signboardscreen({super.key, required this.guestId});

  @override
  State<Signboardscreen> createState() => _SignboardscreenState();
}

class _SignboardscreenState extends State<Signboardscreen> {
  void _openWishForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WishFormOverlay(),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchWishes() async {
    final response = await Supabase.instance.client
        .from('sign_board_wishes')
        .select('''
        id,
        message,
        image_url,
        guest_id,
        created_at,
        guests!inner(guest_name, guest_photo_url)
      ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_rounded),
        ),
        title: Text(
          "Sign Boards",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Align(
        alignment: AlignmentGeometry.topCenter,
        child: SizedBox(
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Leave a Wish",
                style: GoogleFonts.sacramento(
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
              Text(
                textAlign: TextAlign.center,
                "Share your love, advice and best wishes for the \n happy couple.",
                style: GoogleFonts.lindenHill(
                  fontSize: 19,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Colors.black26,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _openWishForm(context);
                },
                icon: const Icon(Icons.edit, color: Colors.black, size: 20),
                label: const Text(
                  'Write a Wish',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Serif',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9DB2),
                  foregroundColor: Colors.black,
                  elevation: 5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 100,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: _fetchWishes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final wishes = snapshot.data!;

                    if (wishes.isEmpty) {
                      return const Center(child: Text("No wishes yet 💖"));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: wishes.length,
                      itemBuilder: (context, index) {
                        final wish = wishes[index];
                        final isOwner = wish['guest_id'] == widget.guestId;

                        return _wishCard(wish, isOwner);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishFormOverlay extends StatefulWidget {
  const _WishFormOverlay();

  @override
  State<_WishFormOverlay> createState() => _WishFormOverlayState();
}

class _WishFormOverlayState extends State<_WishFormOverlay> {
  final _nameController = TextEditingController();
  final _wishController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  Uint8List? _wishPostImage;

  Future<String?> _uploadWishImage(Uint8List image, String wishId) async {
    final path = 'wish_$wishId.jpg';

    await Supabase.instance.client.storage
        .from('wishPostImage')
        .uploadBinary(
          path,
          image,
          fileOptions: const FileOptions(upsert: true),
        );

    return Supabase.instance.client.storage
        .from('wishPostImage')
        .getPublicUrl(path);
  }

  Future<void> _submitWish() async {
    if (_wishController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final inserted = await Supabase.instance.client
        .from('sign_board_wishes')
        .insert({
          'guest_id': widget.guestId,
          'message': _wishController.text.trim(),
        })
        .select()
        .single();

    if (_wishPostImage != null) {
      final imageUrl = await _uploadWishImage(_wishPostImage!, inserted['id']);

      await Supabase.instance.client
          .from('sign_board_wishes')
          .update({'image_url': imageUrl})
          .eq('id', inserted['id']);
    }

    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  Future<void> pickwishPostImage() async {
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
                      _wishPostImage = image;
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
                      _wishPostImage = image;
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF6A5B7), Color(0xFFFFE4EC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Leave a Wish",
                        style: GoogleFonts.sacramento(fontSize: 36),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// NAME
                    Text(
                      "Your Name",
                      style: GoogleFonts.lindenHill(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    _inputField(
                      controller: _nameController,
                      hint: "e.g Aunt May",
                    ),

                    const SizedBox(height: 16),

                    /// WISH
                    Text(
                      "Your Wish",
                      style: GoogleFonts.lindenHill(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    _inputField(
                      controller: _wishController,
                      hint:
                          "Share your favorite memory or best advice for the couple",
                      maxLines: 5,
                    ),

                    const SizedBox(height: 16),

                    /// PHOTO (UI ONLY)
                    Text(
                      "Add a Photo (Optional)",
                      style: GoogleFonts.lindenHill(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4EC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: pickwishPostImage,
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFFB57BA6),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text("Tap to upload a selfie"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// POST BUTTON
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitWish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8FA3),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Post Wish"),
                    ),

                    const SizedBox(height: 10),

                    /// CANCEL
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Center(child: Text("Cancel")),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFFE4EC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
