// ProfileManagementScreen.dart - Updated with cover image upload
import 'dart:convert' show base64Decode, base64Encode;
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Util.dart' show OSMLocationService, pickImage;

class ProfileManagementScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? weddingData;

  const ProfileManagementScreen({
    super.key,
    this.userProfile,
    this.weddingData,
  });

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _imagePicker = ImagePicker();

  late TextEditingController _roleController;
  late TextEditingController _groomNameController;
  late TextEditingController _brideNameController;
  late TextEditingController _weddingNameController;
  late TextEditingController _weddingDateController;
  late TextEditingController _venueController;

  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isUploadingCover = false;

  List<dynamic> venueSuggestions = [];
  double? venueLat;
  double? venueLng;
  Uint8List? _mapImageBytes;

  // Cover image variables
  File? _coverImageFile;
  String? _coverImageUrl;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _roleController = TextEditingController(
      text: widget.userProfile?['role'] ?? '',
    );
    _groomNameController = TextEditingController(
      text: widget.weddingData?['groom_name'] ?? '',
    );
    _brideNameController = TextEditingController(
      text: widget.weddingData?['bride_name'] ?? '',
    );
    _weddingNameController = TextEditingController(
      text: widget.weddingData?['wedding_name'] ?? '',
    );
    _venueController = TextEditingController(
      text: widget.weddingData?['venue_name'] ?? '',
    );

    // Set profile image URL
    _profileImageUrl = widget.userProfile?['profile_image'];

    // Set cover image URL
    _coverImageUrl = widget.weddingData?['cover_image_url'];

    // Parse wedding date
    if (widget.weddingData?['wedding_date'] != null) {
      _selectedDate = DateTime.parse(widget.weddingData!['wedding_date']);
      _weddingDateController = TextEditingController(
        text: _formatDate(_selectedDate!),
      );
    } else {
      _weddingDateController = TextEditingController();
    }

    // Load existing map image
    if (widget.weddingData?['venue_map_image'] != null) {
      try {
        _mapImageBytes = base64Decode(widget.weddingData!['venue_map_image']);
      } catch (e) {
        print('Error decoding map image: $e');
      }
    }

    // Set venue coordinates
    if (widget.weddingData?['venue_lat'] != null) {
      venueLat = double.tryParse(widget.weddingData!['venue_lat'].toString());
    }
    if (widget.weddingData?['venue_lng'] != null) {
      venueLng = double.tryParse(widget.weddingData!['venue_lng'].toString());
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _weddingDateController.text = _formatDate(picked);
      });
    }
  }

  // Extract image picking function from ProfileSetupScreen
  Future<void> selectProfileImage() async {
    try {
      final img = await pickImage(ImageSource.gallery);
      if (img != null) {
        setState(() {
          _profileImageBytes = img;
          _profileImageUrl = null; // Clear URL when using new image bytes
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick profile image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // EXTRACTED FROM WeddingCoverUpload: Cover image picking
  Future<void> pickCoverImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _coverImageFile = File(picked.path);
          _coverImageUrl = null; // Clear URL when using new file
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick cover image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImageBytes == null) return _profileImageUrl;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final path = '$uid/profile_${DateTime.now().millisecondsSinceEpoch}.png';

      // Upload to Supabase Storage
      await supabase.storage
          .from('profile-pictures')
          .uploadBinary(
            path,
            _profileImageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final imageUrl = supabase.storage
          .from('profile-pictures')
          .getPublicUrl(path);

      return imageUrl;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload profile image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return _profileImageUrl;
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<String?> _uploadCoverImage() async {
    if (_coverImageFile == null) return _coverImageUrl;

    setState(() {
      _isUploadingCover = true;
    });

    try {
      final ext = _coverImageFile!.path.split('.').last;
      final path = '$uid/cover_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage
          .from('wedding-covers')
          .upload(
            path,
            _coverImageFile!,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage
          .from('wedding-covers')
          .getPublicUrl(path);

      return imageUrl;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload cover image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return _coverImageUrl;
    } finally {
      setState(() {
        _isUploadingCover = false;
      });
    }
  }

  void _onVenueChanged(String value) async {
    if (value.length < 3) {
      setState(() {
        venueSuggestions = [];
      });
      return;
    }

    try {
      final results = await OSMLocationService.searchPlace(value);
      setState(() {
        venueSuggestions = results;
      });
    } catch (e) {
      print('Error searching venues: $e');
    }
  }

  Future<void> _onVenueSelected(Map<String, dynamic> place) async {
    try {
      // Set venue name
      _venueController.text = place['display_name'];

      // Parse coordinates
      venueLat = double.tryParse(place['lat'].toString());
      venueLng = double.tryParse(place['lon'].toString());

      // Generate map image bytes
      if (venueLat != null && venueLng != null) {
        final mapBytes = await OSMLocationService.getStaticMapImage(
          venueLat!,
          venueLng!,
        );

        setState(() {
          _mapImageBytes = mapBytes;
          venueSuggestions = []; // Clear suggestions
        });
      } else {
        setState(() {
          venueSuggestions = [];
        });
        Get.snackbar(
          'Error',
          'Could not parse venue coordinates',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error selecting venue: $e');
      Get.snackbar(
        'Error',
        'Failed to select venue: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Upload profile image if new one was selected
      String? finalImageUrl = await _uploadProfileImage();

      // Upload cover image if new one was selected
      String? finalCoverImageUrl = await _uploadCoverImage();

      // Update profile
      await supabase
          .from('profiles')
          .update({
            'role': _roleController.text,
            'profile_image': finalImageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', uid);

      // Update wedding info
      if (widget.weddingData != null) {
        await supabase
            .from('weddings')
            .update({
              'groom_name': _groomNameController.text,
              'bride_name': _brideNameController.text,
              'wedding_name': _weddingNameController.text,
              'wedding_date': _weddingDateController.text,
              'venue_name': _venueController.text,
              'venue_lat': venueLat,
              'venue_lng': venueLng,
              'venue_map_image': _mapImageBytes != null
                  ? base64Encode(_mapImageBytes!)
                  : null,
              'cover_image_url':
                  finalCoverImageUrl ?? _coverImageUrl, // Save cover image URL
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.weddingData!['id']);
      }

      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate back and trigger refresh by returning true
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Get.back(result: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wedding Cover Photo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC19AC7),
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploadingCover ? null : pickCoverImage,
          child: Container(
            height: 600,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[900],
              image: _coverImageFile != null
                  ? DecorationImage(
                      image: FileImage(_coverImageFile!),
                      fit: BoxFit.cover,
                    )
                  : (_coverImageUrl != null && _coverImageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_coverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null),
            ),
            child: Stack(
              children: [
                if (_coverImageFile == null &&
                    (_coverImageUrl == null || _coverImageUrl!.isEmpty))
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Colors.white70,
                          size: 60,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Tap to add cover photo',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                if (_isUploadingCover)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Tap the image to change cover photo',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Profile'),
        backgroundColor: Color(0xFFC19AC7),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image Section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingImage ? null : selectProfileImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 70,
                                backgroundColor: Color(
                                  0xFFC19AC7,
                                ).withOpacity(0.1),
                                backgroundImage: _profileImageBytes != null
                                    ? MemoryImage(_profileImageBytes!)
                                          as ImageProvider
                                    : (_profileImageUrl != null &&
                                              _profileImageUrl!.isNotEmpty
                                          ? NetworkImage(_profileImageUrl!)
                                          : null),
                                child:
                                    _profileImageBytes == null &&
                                        (_profileImageUrl == null ||
                                            _profileImageUrl!.isEmpty)
                                    ? Icon(
                                        Icons.add_a_photo_rounded,
                                        size: 60,
                                        color: Color(0xFFC19AC7),
                                      )
                                    : null,
                              ),
                              if (_isUploadingImage)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.5),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Tap the image to change profile photo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Role Selection
                  Text(
                    'Your Role',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC19AC7),
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _roleController.text.isNotEmpty
                        ? _roleController.text
                        : null,
                    items: ['groom', 'bride']
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              role == 'groom' ? 'Groom' : 'Bride',
                              style: TextStyle(color: Color(0xFFC19AC7)),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _roleController.text = value!;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Groom Name
                  Text(
                    'Groom Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC19AC7),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _groomNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText: 'Enter groom\'s full name',
                    ),
                  ),

                  SizedBox(height: 20),

                  // Bride Name
                  Text(
                    'Bride Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC19AC7),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _brideNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText: 'Enter bride\'s full name',
                    ),
                  ),

                  SizedBox(height: 20),

                  // Wedding Name
                  Text(
                    'Wedding Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC19AC7),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _weddingNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText: 'e.g., John & Jane\'s Wedding',
                    ),
                  ),

                  SizedBox(height: 20),

                  // Wedding Date
                  Text(
                    'Wedding Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC19AC7),
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _weddingDateController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: Icon(Icons.calendar_today),
                          hintText: 'Select wedding date',
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  _buildCoverImageSection(),

                  SizedBox(height: 25),

                  Text(
                    'Wedding Venue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC19AC7),
                    ),
                  ),
                  SizedBox(height: 8),

                  //wedding Venue Input update section
                  Opacity(
                    opacity: _isLoading ? 0.7 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _venueController,
                        enabled: !_isLoading,
                        onChanged: _onVenueChanged,
                        decoration: InputDecoration(
                          icon: Icon(
                            Icons.map_outlined,
                            color: Color(0xFFFE96AF),
                          ),
                          hintText: "Wedding Venue",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  if (venueSuggestions.isNotEmpty && !_isLoading)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: venueSuggestions.length,
                        itemBuilder: (context, index) {
                          final place = venueSuggestions[index];
                          return ListTile(
                            title: Text(
                              place['display_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () async {
                              await _onVenueSelected(place);
                            },
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, thickness: 1),
                      ),
                    ),

                  if (_mapImageBytes != null && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: Color(0xFFFE96AF).withOpacity(0.8),
                                child: Row(
                                  children: [
                                    Icon(Icons.map, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      "Venue Location Preview",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 200,
                                child: _mapImageBytes != null
                                    ? Image.memory(
                                        _mapImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 10),
                                              Text("Generating map..."),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 40),

                  // Save Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFC19AC7),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _roleController.dispose();
    _groomNameController.dispose();
    _brideNameController.dispose();
    _weddingNameController.dispose();
    _weddingDateController.dispose();
    _venueController.dispose();
    super.dispose();
  }
}
