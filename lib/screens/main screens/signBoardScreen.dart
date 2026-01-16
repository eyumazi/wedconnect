import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Util.dart' show pickImage;

class Signboardscreen extends StatefulWidget {
  final bool isHost; // Determine if user is host or guest
  final String? guestId; // Guest UUID (if user is a guest)

  const Signboardscreen({super.key, required this.isHost, this.guestId});

  @override
  State<Signboardscreen> createState() => _SignboardscreenState();
}

class _SignboardscreenState extends State<Signboardscreen> {
  final supabase = Supabase.instance.client;
  final firebaseAuth = FirebaseAuth.instance;
  late Future<List<Map<String, dynamic>>> _wishesFuture;
  late Future<Map<String, dynamic>?> _currentUserFuture;
  String? _hostUserId; // For hosts: Firebase UID

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.isHost) {
      // Host user - get their Firebase UID
      _hostUserId = firebaseAuth.currentUser?.uid;
      _currentUserFuture = _fetchHostProfile();
      _wishesFuture = _fetchHostWishes();
    } else {
      // Guest user
      _currentUserFuture = _fetchCurrentGuest();
      _wishesFuture = _fetchAllWishesForCurrentWedding();
    }
  }

  Future<Map<String, dynamic>?> _fetchHostProfile() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, avatar_url')
          .eq('id', _hostUserId!)
          .single();
      return response;
    } catch (e) {
      print('Error fetching host profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchCurrentGuest() async {
    try {
      final response = await supabase
          .from('guests')
          .select('id, guest_name, guest_photo_url, user_id')
          .eq('id', widget.guestId!)
          .single();
      return response;
    } catch (e) {
      print('Error fetching current guest: $e');
      return null;
    }
  }

  // Fetch all wishes for the current wedding (for guests to see everything)
  Future<List<Map<String, dynamic>>> _fetchAllWishesForCurrentWedding() async {
    try {
      // First, get the wedding ID for this guest
      final guestInfo = await supabase
          .from('guests')
          .select('user_id')
          .eq('id', widget.guestId!)
          .single();

      final hostUserId = guestInfo['user_id'] as String;

      // Get all wishes from guests invited by this host
      final response = await supabase
          .from('sign_board_wishes')
          .select('''
            id,
            message,
            image_url,
            guest_id,
            created_at,
            guests!inner(
              guest_name, 
              guest_photo_url,
              user_id
            )
          ''')
          .order('created_at', ascending: false);

      // Filter to only include wishes from guests of this host
      final filteredWishes = (response as List).where((wish) {
        final guestUserId = wish['guests']['user_id'] as String;
        return guestUserId == hostUserId;
      }).toList();

      return List<Map<String, dynamic>>.from(filteredWishes);
    } catch (e) {
      print('Error fetching all wishes: $e');
      return [];
    }
  }

  // Fetch only wishes from guests invited by this host
  Future<List<Map<String, dynamic>>> _fetchHostWishes() async {
    try {
      final response = await supabase
          .from('sign_board_wishes')
          .select('''
            id,
            message,
            image_url,
            guest_id,
            created_at,
            guests!inner(
              guest_name, 
              guest_photo_url,
              user_id
            )
          ''')
          .order('created_at', ascending: false);

      // Filter to only include wishes from guests of this host
      final filteredWishes = (response as List).where((wish) {
        final guestUserId = wish['guests']['user_id'] as String;
        return guestUserId == _hostUserId;
      }).toList();

      return List<Map<String, dynamic>>.from(filteredWishes);
    } catch (e) {
      print('Error fetching host wishes: $e');
      return [];
    }
  }

  void _openWishForm(
    BuildContext context, {
    String? wishId,
    String? initialMessage,
    String? existingImageUrl,
  }) {
    if (widget.isHost) {
      // Hosts cannot add wishes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only invited guests can leave wishes.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WishFormOverlay(
        guestId: widget.guestId!,
        isEditing: wishId != null,
        initialMessage: initialMessage,
        existingImageUrl: existingImageUrl,
        editingWishId: wishId, // Pass the wish ID for editing
        onWishSubmitted: () {
          // Refresh wishes when form is closed
          setState(() {
            _wishesFuture = widget.isHost
                ? _fetchHostWishes()
                : _fetchAllWishesForCurrentWedding();
          });
        },
      ),
    );
  }

  Future<void> _deleteWish(String wishId) async {
    if (widget.isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hosts cannot delete wishes.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirm deletion
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Wish'),
        content: Text('Are you sure you want to delete this wish?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      // First verify this wish belongs to the current guest
      final wish = await supabase
          .from('sign_board_wishes')
          .select('guest_id')
          .eq('id', wishId)
          .single();

      if (wish['guest_id'] != widget.guestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only delete your own wishes.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await supabase.from('sign_board_wishes').delete().eq('id', wishId);

      setState(() {
        _wishesFuture = _fetchAllWishesForCurrentWedding();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wish deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting wish: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting wish'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _wishCard(Map<String, dynamic> wish) {
    final isOwner = !widget.isHost && wish['guest_id'] == widget.guestId;
    final guestName = wish['guests']['guest_name'] ?? 'Guest';
    final guestPhotoUrl = wish['guests']['guest_photo_url'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: guestPhotoUrl != null
                      ? NetworkImage(guestPhotoUrl)
                      : null,
                  child: guestPhotoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guestName,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (wish['created_at'] != null)
                        Text(
                          _formatDate(wish['created_at']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // EDIT/DELETE buttons (ONLY for guest owners)
                if (!widget.isHost && isOwner)
                  PopupMenuButton<String>(
                    itemBuilder: (_) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteWish(wish['id']);
                      } else if (value == 'edit') {
                        _openWishForm(
                          context,
                          wishId: wish['id'],
                          initialMessage: wish['message'],
                          existingImageUrl:
                              wish['image_url'], // Pass existing image
                        );
                      }
                    },
                  ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              wish['message'],
              style: GoogleFonts.lindenHill(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),

            if (wish['image_url'] != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(wish['image_url']),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} • ${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_rounded),
        ),
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _currentUserFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data != null) {
              final userName =
                  data['full_name'] ?? data['guest_name'] ?? 'User';
              return Text(
                widget.isHost ? "Guest Wishes" : "Welcome, $userName!",
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            return Text(
              widget.isHost ? "Guest Wishes" : "Sign Board",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF6A5B7), Color(0xFFFFE4EC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.isHost ? "Guest Wishes" : "Leave a Wish",
                  style: GoogleFonts.sacramento(
                    fontSize: 48,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                Text(
                  textAlign: TextAlign.center,
                  widget.isHost
                      ? "Read lovely messages from your guests"
                      : "Share your love, advice and best wishes for the happy couple.",
                  style: GoogleFonts.lindenHill(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),

                if (!widget.isHost) SizedBox(height: 20),

                if (!widget.isHost)
                  ElevatedButton.icon(
                    onPressed: () => _openWishForm(context),
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    label: const Text(
                      'Write a Wish',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Serif',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Wishes List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _wishesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading wishes'));
                }

                final wishes = snapshot.data ?? [];

                if (wishes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isHost
                              ? Icons.mode_comment_outlined
                              : Icons.edit_note,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.isHost
                              ? "No wishes from your guests yet"
                              : "No wishes yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          widget.isHost
                              ? "Wait for your guests to share their wishes!"
                              : "Be the first to share your wishes!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _wishesFuture = widget.isHost
                          ? _fetchHostWishes()
                          : _fetchAllWishesForCurrentWedding();
                    });
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: wishes.length,
                    itemBuilder: (context, index) {
                      return _wishCard(wishes[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WishFormOverlay extends StatefulWidget {
  final String guestId;
  final bool isEditing;
  final String? initialMessage;
  final String? existingImageUrl; // Add this
  final String? editingWishId; // Add this
  final VoidCallback? onWishSubmitted;

  const _WishFormOverlay({
    required this.guestId,
    this.isEditing = false,
    this.initialMessage,
    this.existingImageUrl,
    this.editingWishId,
    this.onWishSubmitted,
  });

  @override
  State<_WishFormOverlay> createState() => _WishFormOverlayState();
}

class _WishFormOverlayState extends State<_WishFormOverlay> {
  final _wishController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  Uint8List? _wishPostImage;
  String? _existingImageUrl;
  String? _editingWishId; // Store editing wish ID

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _wishController.text = widget.initialMessage!;
    }
    if (widget.existingImageUrl != null) {
      _existingImageUrl = widget.existingImageUrl;
    }
    if (widget.editingWishId != null) {
      _editingWishId = widget.editingWishId;
    }
  }

  Future<String?> _uploadWishImage(Uint8List image, String wishId) async {
    final path = 'wish_${widget.guestId}_$wishId.jpg';

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
    if (_wishController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your wish'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      if (widget.isEditing && _editingWishId != null) {
        // EDIT FUNCTIONALITY - IMPLEMENTED
        // First, get the existing wish to preserve the image if not changing
        Map<String, dynamic>? existingWish;
        try {
          existingWish = await supabase
              .from('sign_board_wishes')
              .select('image_url')
              .eq('id', _editingWishId!)
              .single();
        } catch (e) {
          print('Error fetching existing wish: $e');
        }

        // Update the wish message
        final updateData = {
          'message': _wishController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Handle image update
        if (_wishPostImage != null) {
          // Upload new image
          final imageUrl = await _uploadWishImage(
            _wishPostImage!,
            _editingWishId!,
          );
          updateData['image_url'] = imageUrl!;
        } else if (_existingImageUrl != null && _wishPostImage == null) {
          updateData['image_url'] = _existingImageUrl!;
        } else if (existingWish != null && existingWish['image_url'] != null) {
          updateData['image_url'] = existingWish['image_url'];
        }
        // Update the wish in database
        await supabase
            .from('sign_board_wishes')
            .update(updateData)
            .eq('id', _editingWishId!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wish updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // CREATE NEW WISH
        final inserted = await supabase
            .from('sign_board_wishes')
            .insert({
              'guest_id': widget.guestId,
              'message': _wishController.text.trim(),
            })
            .select()
            .single();

        if (_wishPostImage != null) {
          final imageUrl = await _uploadWishImage(
            _wishPostImage!,
            inserted['id'],
          );

          await supabase
              .from('sign_board_wishes')
              .update({'image_url': imageUrl})
              .eq('id', inserted['id']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wish posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onWishSubmitted?.call();
      Navigator.pop(context);
    } catch (e) {
      print("Error submitting wish: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
              if (_wishPostImage != null || _existingImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Remove Photo",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _wishPostImage = null;
                      _existingImageUrl = null;
                    });
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
                        widget.isEditing ? "Edit Wish" : "Leave a Wish",
                        style: GoogleFonts.sacramento(fontSize: 36),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// WISH
                    Text(
                      "Your Wish",
                      style: GoogleFonts.lindenHill(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _wishController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            "Share your favorite memory or best advice for the couple",
                        filled: true,
                        fillColor: const Color(0xFFFFE4EC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// PHOTO
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
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFFB57BA6),
                              backgroundImage: _wishPostImage != null
                                  ? MemoryImage(_wishPostImage!)
                                  : (_existingImageUrl != null
                                        ? NetworkImage(_existingImageUrl!)
                                              as ImageProvider
                                        : null),
                              child:
                                  _wishPostImage == null &&
                                      _existingImageUrl == null
                                  ? const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Tap to upload a selfie"),
                                if (_wishPostImage != null ||
                                    _existingImageUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _wishPostImage != null
                                          ? "New photo selected ✓"
                                          : "Existing photo ✓",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// POST/UPDATE BUTTON
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
                          : Text(
                              widget.isEditing ? "Update Wish" : "Post Wish",
                            ),
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
}
