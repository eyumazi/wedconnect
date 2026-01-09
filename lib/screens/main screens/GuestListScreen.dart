import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Reusable%20components/CustomUploadingButton.dart';
import 'package:wedconnect/Util.dart' show pickImage;
import 'package:wedconnect/screens/main%20screens/QRCodeGeneratorScreen.dart';

enum ArrivalFilter { all, arrived, notArrived }

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  late Future<List<dynamic>> guests;
  String searchQuery = '';
  ArrivalFilter arrivalFilter = ArrivalFilter.all;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    guests = fetchGuests();
  }

  final guestNameController = TextEditingController();
  final guestPhoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Uint8List? guestPhoto;
  bool saving = false;

  void _showGuestSelectionDialog(BuildContext context) async {
    final data = await guests;

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No guests to generate QR code for')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Guest for QR Code'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final guest = data[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: guest['guest_photo_url'] != null
                        ? NetworkImage(guest['guest_photo_url'])
                        : null,
                    child: guest['guest_photo_url'] == null
                        ? Icon(Icons.person)
                        : null,
                  ),
                  title: Text(guest['guest_name']),
                  subtitle: Text(guest['phone_number']),
                  trailing: guest['invitation_sent'] == true
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QRCodeGeneratorScreen(
                          guestId: guest['id'],
                          guestName: guest['guest_name'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

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
        'is_arrived': false,
      });

      // Refresh guest list
      setState(() {
        guests = fetchGuests();
      });

      // Clear form
      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Guest added successfully!"),
          backgroundColor: Colors.green,
        ),
      );
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

  Future<List<dynamic>> fetchGuests() async {
    return await supabase
        .from('guests')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
  }

  // Filter guests based on search and arrival status
  List<dynamic> filterGuests(List<dynamic> guestsList) {
    return guestsList.where((guest) {
      // Search filter
      final matchesSearch =
          searchQuery.isEmpty ||
          guest['guest_name'].toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          guest['phone_number'].contains(searchQuery);

      // Arrival filter
      final matchesArrival = switch (arrivalFilter) {
        ArrivalFilter.all => true,
        ArrivalFilter.arrived => guest['is_arrived'] == true,
        ArrivalFilter.notArrived => guest['is_arrived'] != true,
      };

      return matchesSearch && matchesArrival;
    }).toList();
  }

  Future<void> refreshGuests() async {
    setState(() {
      guests = fetchGuests();
    });
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search guests...',
              prefixIcon: Icon(Icons.search, color: Color(0xFFC19AC7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Color(0xFFF5F5F5),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),

          SizedBox(height: 12),

          // Filter Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilterChip(
                label: Text('All'),
                selected: arrivalFilter == ArrivalFilter.all,
                onSelected: (_) {
                  setState(() {
                    arrivalFilter = ArrivalFilter.all;
                  });
                },
                selectedColor: Color(0xFFC19AC7),
                checkmarkColor: Colors.white,
              ),
              FilterChip(
                label: Text('Arrived'),
                selected: arrivalFilter == ArrivalFilter.arrived,
                onSelected: (_) {
                  setState(() {
                    arrivalFilter = ArrivalFilter.arrived;
                  });
                },
                selectedColor: Colors.green,
                checkmarkColor: Colors.white,
              ),
              FilterChip(
                label: Text('Not Arrived'),
                selected: arrivalFilter == ArrivalFilter.notArrived,
                onSelected: (_) {
                  setState(() {
                    arrivalFilter = ArrivalFilter.notArrived;
                  });
                },
                selectedColor: Colors.red,
                checkmarkColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
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
          "Guest List",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _showGuestSelectionDialog(context);
            },
            icon: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFC19AC7)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshGuests,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Add Guest Form
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: const Color(0xFFFFE3EF),
                  ),
                  child: Column(
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

                      TextButton(
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
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Search and Filter Section
                _buildSearchAndFilter(),

                SizedBox(height: 20),

                // Guest List
                FutureBuilder(
                  future: guests,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading guests'));
                    }

                    final data = snapshot.data!;
                    final filteredGuests = filterGuests(data);

                    if (filteredGuests.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 10),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'No guests found for "$searchQuery"'
                                  : 'No guests found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: filteredGuests.length,
                        itemBuilder: (context, index) {
                          final guest = filteredGuests[index];
                          final isArrived = guest['is_arrived'] == true;

                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: isArrived
                                    ? Colors.green[100]
                                    : Colors.grey[200],
                                backgroundImage:
                                    guest['guest_photo_url'] != null
                                    ? NetworkImage(guest['guest_photo_url'])
                                    : null,
                                child: guest['guest_photo_url'] == null
                                    ? Icon(
                                        Icons.person,
                                        color: isArrived
                                            ? Colors.green
                                            : Colors.grey[600],
                                      )
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      guest['guest_name'],
                                      style: GoogleFonts.cormorantGaramond(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (isArrived)
                                    Icon(
                                      Icons.verified,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(guest['phone_number']),
                                  if (isArrived &&
                                      guest['arrival_time'] != null)
                                    Text(
                                      'Arrived: ${DateTime.parse(guest['arrival_time']).toLocal().toString().substring(0, 16)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isArrived
                                  ? Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: Text(
                                        'ARRIVED',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
