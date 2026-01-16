import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Util.dart' show pickImage;

class PhotoWallScreen extends StatefulWidget {
  final bool isHost; // Determine if user is host or guest
  final String? guestId; // Guest UUID (if user is a guest)

  const PhotoWallScreen({super.key, required this.isHost, this.guestId});

  @override
  State<PhotoWallScreen> createState() => _PhotoWallScreenState();
}

class _PhotoWallScreenState extends State<PhotoWallScreen> {
  final supabase = Supabase.instance.client;
  final firebaseAuth = FirebaseAuth.instance;
  late Future<List<Map<String, dynamic>>> _memoriesFuture;
  late Future<Map<String, dynamic>?> _currentUserFuture;
  String? _hostUserId; // For hosts: Firebase UID
  bool _isGridView = true; // Toggle between grid and list view

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
      _memoriesFuture = _fetchHostMemories();
    } else {
      // Guest user
      _currentUserFuture = _fetchCurrentGuest();
      _memoriesFuture = _fetchAllMemoriesForCurrentWedding();
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

  // Fetch all memories for the current wedding
  Future<List<Map<String, dynamic>>>
  _fetchAllMemoriesForCurrentWedding() async {
    try {
      // First, get the host ID for this guest
      final guestInfo = await supabase
          .from('guests')
          .select('user_id')
          .eq('id', widget.guestId!)
          .single();

      final hostUserId = guestInfo['user_id'] as String;

      // Get all memories from guests invited by this host
      final response = await supabase
          .from('memories')
          .select('''
            id,
            image_url,
            caption,
            guest_id,
            created_at,
            guests!inner(
              guest_name, 
              guest_photo_url,
              user_id
            )
          ''')
          .order('created_at', ascending: false);

      // Filter to only include memories from guests of this host
      final filteredMemories = (response as List).where((memory) {
        final guestUserId = memory['guests']['user_id'] as String;
        return guestUserId == hostUserId;
      }).toList();

      return List<Map<String, dynamic>>.from(filteredMemories);
    } catch (e) {
      print('Error fetching all memories: $e');
      return [];
    }
  }

  // Fetch only memories from guests invited by this host
  Future<List<Map<String, dynamic>>> _fetchHostMemories() async {
    try {
      final response = await supabase
          .from('memories')
          .select('''
            id,
            image_url,
            caption,
            guest_id,
            created_at,
            guests!inner(
              guest_name, 
              guest_photo_url,
              user_id
            )
          ''')
          .order('created_at', ascending: false);

      // Filter to only include memories from guests of this host
      final filteredMemories = (response as List).where((memory) {
        final guestUserId = memory['guests']['user_id'] as String;
        return guestUserId == _hostUserId;
      }).toList();

      return List<Map<String, dynamic>>.from(filteredMemories);
    } catch (e) {
      print('Error fetching host memories: $e');
      return [];
    }
  }

  void _openAddMemoryForm(BuildContext context) {
    if (widget.isHost) {
      // Hosts cannot add memories
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only invited guests can add memories.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMemoryOverlay(
        guestId: widget.guestId!,
        onMemorySubmitted: () {
          // Refresh memories when form is closed
          setState(() {
            _memoriesFuture = widget.isHost
                ? _fetchHostMemories()
                : _fetchAllMemoriesForCurrentWedding();
          });
        },
      ),
    );
  }

  Future<void> _deleteMemory(String memoryId) async {
    if (widget.isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hosts cannot delete memories.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirm deletion
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Memory'),
        content: Text('Are you sure you want to delete this memory?'),
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
      // First verify this memory belongs to the current guest
      final memory = await supabase
          .from('memories')
          .select('guest_id')
          .eq('id', memoryId)
          .single();

      if (memory['guest_id'] != widget.guestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only delete your own memories.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await supabase.from('memories').delete().eq('id', memoryId);

      setState(() {
        _memoriesFuture = _fetchAllMemoriesForCurrentWedding();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Memory deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting memory: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting memory'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _memoryGridItem(Map<String, dynamic> memory, int index) {
    final isOwner = !widget.isHost && memory['guest_id'] == widget.guestId;
    final guestName = memory['guests']['guest_name'] ?? 'Guest';
    final imageUrl = memory['image_url'];
    final caption = memory['caption'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Delete button (ONLY for memory owners)
                if (!widget.isHost && isOwner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _deleteMemory(memory['id']),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Guest name overlay
                if (guestName.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage:
                                memory['guests']['guest_photo_url'] != null
                                ? NetworkImage(
                                    memory['guests']['guest_photo_url'],
                                  )
                                : null,
                            child: memory['guests']['guest_photo_url'] == null
                                ? Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              guestName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                caption,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _memoryListItem(Map<String, dynamic> memory, int index) {
    final isOwner = !widget.isHost && memory['guest_id'] == widget.guestId;
    final guestName = memory['guests']['guest_name'] ?? 'Guest';
    final imageUrl = memory['image_url'];
    final caption = memory['caption'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with guest info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: memory['guests']['guest_photo_url'] != null
                      ? NetworkImage(memory['guests']['guest_photo_url'])
                      : null,
                  child: memory['guests']['guest_photo_url'] == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guestName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (memory['created_at'] != null)
                        Text(
                          _formatDate(memory['created_at']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!widget.isHost && isOwner)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMemory(memory['id']),
                  ),
              ],
            ),
          ),

          // Memory Image Container with fixed height
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Caption
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                caption,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.day}/${date.month}/${date.year}';
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
              final userName = data['guest_name'] ?? 'User';
              return Text(
                widget.isHost ? "Photo Wall" : "Welcome, $userName!",
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            return Text(
              "Photo Wall",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          // View Toggle Button
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Color(0xFFC19AC7),
            ),
          ),

          // Add Memory button (only for guests)
          if (!widget.isHost)
            IconButton(
              onPressed: () => _openAddMemoryForm(context),
              icon: Icon(Icons.add_a_photo, color: Color(0xFFC19AC7)),
            ),
        ],
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
                  "Photo Wall",
                  style: GoogleFonts.sacramento(
                    fontSize: 48,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                Text(
                  textAlign: TextAlign.center,
                  widget.isHost
                      ? "See memories shared by your guests"
                      : "Share your favorite moments from the wedding",
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
                    onPressed: () => _openAddMemoryForm(context),
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Add Memory',
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

          // Memories List/Grid
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _memoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading memories'));
                }

                final memories = snapshot.data ?? [];

                if (memories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.isHost
                              ? "No memories shared yet"
                              : "No memories yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          widget.isHost
                              ? "Wait for your guests to share their photos!"
                              : "Be the first to share a memory!",
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
                      _memoriesFuture = widget.isHost
                          ? _fetchHostMemories()
                          : _fetchAllMemoriesForCurrentWedding();
                    });
                  },
                  child: _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio:
                                    0.7, // Adjusted from 0.8 to 0.7
                              ),
                          itemCount: memories.length,
                          itemBuilder: (context, index) {
                            return _memoryGridItem(memories[index], index);
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: memories.length,
                          itemBuilder: (context, index) {
                            return _memoryListItem(memories[index], index);
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

class _AddMemoryOverlay extends StatefulWidget {
  final String guestId;
  final VoidCallback? onMemorySubmitted;

  const _AddMemoryOverlay({required this.guestId, this.onMemorySubmitted});

  @override
  State<_AddMemoryOverlay> createState() => _AddMemoryOverlayState();
}

class _AddMemoryOverlayState extends State<_AddMemoryOverlay> {
  final _captionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  Uint8List? _selectedImage;

  Future<String?> _uploadMemoryImage(Uint8List image) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'memory_${widget.guestId}_$timestamp.jpg';

    await Supabase.instance.client.storage
        .from('memories')
        .uploadBinary(
          path,
          image,
          fileOptions: const FileOptions(upsert: true),
        );

    return Supabase.instance.client.storage.from('memories').getPublicUrl(path);
  }

  Future<void> _submitMemory() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Upload image
      final imageUrl = await _uploadMemoryImage(_selectedImage!);

      // Create memory record
      await supabase.from('memories').insert({
        'guest_id': widget.guestId,
        'image_url': imageUrl,
        'caption': _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Memory added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onMemorySubmitted?.call();
      Navigator.pop(context);
    } catch (e) {
      print("Error adding memory: $e");
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

  Future<void> _pickImage() async {
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
                      _selectedImage = image;
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
                      _selectedImage = image;
                    });
                  }
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Remove Photo",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
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
                        "Add Memory",
                        style: GoogleFonts.sacramento(fontSize: 36),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// PHOTO SELECTION
                    Text(
                      "Select a Photo",
                      style: GoogleFonts.lindenHill(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4EC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFB57BA6),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 60,
                                    color: const Color(0xFFB57BA6),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Tap to choose a photo",
                                    style: TextStyle(
                                      color: const Color(0xFFB57BA6),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// CAPTION (Optional)
                    Text(
                      "Add a Caption (Optional)",
                      style: GoogleFonts.lindenHill(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _captionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Describe this memory...",
                        filled: true,
                        fillColor: const Color(0xFFFFE4EC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// POST BUTTON
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitMemory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8FA3),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Post Memory"),
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
