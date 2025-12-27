import 'dart:convert' show base64Encode;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Reusable components/Button2.dart';
import 'package:wedconnect/Util.dart';
import 'package:wedconnect/screens/Form%20Screens/WeddingInfoPreview.dart';

class WeddingInfo extends StatefulWidget {
  const WeddingInfo({super.key});

  @override
  State<WeddingInfo> createState() => _WeddingInfoState();
}

class _WeddingInfoState extends State<WeddingInfo> {
  final groomController = TextEditingController();
  final brideController = TextEditingController();
  final venueController = TextEditingController();

  DateTime? weddingDate;

  List<dynamic> venueSuggestions = [];
  double? venueLat;
  double? venueLng;
  Uint8List? _mapImageBytes; // Changed from String to Uint8List

  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Uint8List? _image;

  Future<void> saveWeddingInfo() async {
    if (groomController.text.isEmpty ||
        brideController.text.isEmpty ||
        weddingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    // Convert bytes to base64 for storage
    String? base64Image;
    if (_mapImageBytes != null) {
      base64Image = base64Encode(_mapImageBytes!);
    }

    await supabase.from('weddings').insert({
      'user_id': uid,
      'groom_name': groomController.text,
      'bride_name': brideController.text,
      'wedding_name': "${groomController.text} & ${brideController.text}",
      'wedding_date': weddingDate!.toIso8601String(),
      'venue_name': venueController.text,
      'venue_lat': venueLat,
      'venue_lng': venueLng,
      'venue_map_image': base64Image,
      'created_at': DateTime.now().toIso8601String(), // Add timestamp
    });

    // Navigate to preview screen instead of ProfileViewScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WeddingPreviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/Background/Bg2.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Wedding Info",
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              /// Wedding Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _nameField(groomController, "Groom"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("&", style: GoogleFonts.allura(fontSize: 32)),
                  ),
                  _nameField(brideController, "Bride"),
                ],
              ),

              const SizedBox(height: 30),

              /// Wedding Date
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => weddingDate = picked);
                },
                child: _infoBox(
                  weddingDate == null
                      ? "Select Wedding Date"
                      : "${weddingDate!.day}/${weddingDate!.month}/${weddingDate!.year}",
                  Icons.calendar_month,
                ),
              ),

              const SizedBox(height: 20),

              /// Venue Search
              _infoBoxField(
                controller: venueController,
                hint: "Wedding Venue",
                icon: Icons.map_outlined,
                onChanged: (value) async {
                  if (value.length < 3) return;
                  final results = await OSMLocationService.searchPlace(value);
                  setState(() => venueSuggestions = results);
                },
              ),

              /// Suggestions
              if (venueSuggestions.isNotEmpty)
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () async {
                          venueController.text = place['display_name'];
                          venueLat = double.parse(place['lat']);
                          venueLng = double.parse(place['lon']);

                          // Generate map image bytes
                          final mapBytes =
                              await OSMLocationService.getStaticMapImage(
                                venueLat!,
                                venueLng!,
                              );

                          setState(() {
                            _mapImageBytes = mapBytes;
                            venueSuggestions = [];
                          });
                        },
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, thickness: 1),
                  ),
                ),

              /// Map Preview using bytes
              if (_mapImageBytes != null)
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

              const SizedBox(height: 40),

              CustomElevatedButton2(
                text: "Continue to Theme and cover",
                onPressed: () {
                  saveWeddingInfo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameField(TextEditingController controller, String hint) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFE96AF)),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _infoBoxField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          icon: Icon(icon, color: Color(0xFFFE96AF)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
