import 'dart:convert' show base64Decode;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Authentication/Wrapper.dart';
import 'package:wedconnect/Reusable%20components/Button3.dart';
import 'package:wedconnect/Util.dart' show openGoogleMaps;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

Future<void> signout() async {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  await googleSignIn.signOut();
  await FirebaseAuth.instance.signOut();
  Get.offAll(() => const Wrapper());
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;
  List<dynamic> weddingData = [];
  bool isLoading = true;
  String errorMessage = '';
  Uint8List? _mapImageBytes;
  int _selectedIndex = 0; // For bottom navigation bar

  // Bottom navigation bar items
  static const List<Widget> _pages = <Widget>[
    // Home page content will be in body
    Placeholder(), // Placeholder for other pages
    Placeholder(),
    Placeholder(),
    Placeholder(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // You can add navigation logic here
    if (index == 1) {
      // Navigate to gallery or other page
    } else if (index == 2) {
      // Navigate to guests page
    } else if (index == 3) {
      // Navigate to profile page
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWeddingData();
  }

  Future<void> _loadWeddingData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Fetches wedding data for the current user
      final response = await supabase
          .from('weddings')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);

      setState(() {
        weddingData = response;

        if (weddingData.isNotEmpty &&
            weddingData[0]['venue_map_image'] != null) {
          try {
            _mapImageBytes = base64Decode(weddingData[0]['venue_map_image']);
          } catch (e) {
            print('Error decoding image: $e');
          }
        }
      });
    } catch (e) {
      print('Error loading wedding data: $e');
      setState(() {
        errorMessage = 'Failed to load wedding data. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    Duration getRemainingTime(DateTime weddingDate) {
      final now = DateTime.now();
      return weddingDate.difference(now);
    }

    // Remove FutureBuilder and use the data directly
    if (isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    if (errorMessage.isNotEmpty || weddingData.isEmpty) {
      return Scaffold(
        body: _buildDefaultLayout(screenHeight),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    // Variables used for fetched values
    final coverUrl = weddingData[0]['cover_image_url'] as String?;
    final weddingName = weddingData[0]['wedding_name'] as String?;
    final weddingDateString = weddingData[0]['wedding_date'] as String?;
    final weddingDate = weddingDateString != null
        ? DateTime.parse(weddingDateString)
        : null;
    final venueName = weddingData[0]['venue_name'] as String?;
    final venueLatRaw = weddingData[0]['venue_lat'];
    final venueLngRaw = weddingData[0]['venue_lng'];

    final venueLat = venueLatRaw != null
        ? double.tryParse(venueLatRaw.toString())
        : null;

    final venueLng = venueLngRaw != null
        ? double.tryParse(venueLngRaw.toString())
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _selectedIndex == 0
          ? _buildHomeContent(
              screenHeight,
              coverUrl,
              weddingName,
              weddingDate,
              venueName,
              venueLat,
              venueLng,
            )
          : _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: signout,
              backgroundColor: Colors.white,
              child: const Icon(Icons.logout, color: Colors.black),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeContent(
    double screenHeight,
    String? coverUrl,
    String? weddingName,
    DateTime? weddingDate,
    String? venueName,
    double? venueLat,
    double? venueLng,
  ) {
    Duration getRemainingTime(DateTime weddingDate) {
      final now = DateTime.now();
      return weddingDate.difference(now);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // COVER SECTION
          SizedBox(
            height: screenHeight * 0.8,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? Image.network(coverUrl, fit: BoxFit.cover)
                      : Container(
                          color: Colors.blueGrey,
                          child: const Center(
                            child: Icon(
                              Icons.photo_library,
                              size: 60,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                ),

                // VIGNETTE
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.7),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),

                /// 🏷 WEDDING NAME
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const SizedBox(height: 16),
                        if (weddingDate != null)
                          // Countdown box
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 30,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8E6EC).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: StreamBuilder(
                              stream: Stream.periodic(
                                const Duration(seconds: 1),
                              ),
                              builder: (context, snapshot) {
                                final remaining = getRemainingTime(weddingDate);

                                final days = remaining.inDays;
                                final hours = remaining.inHours % 24;
                                final mins = remaining.inMinutes % 60;
                                final secs = remaining.inSeconds % 60;

                                return Column(
                                  children: [
                                    // WEDDING NAME
                                    Text(
                                      weddingName ??
                                          'Wedding name not provided',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 20),

                                    /// TIME ROW
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _timeBox(days.toString(), 'days'),
                                        _timeBox(
                                          hours.toString().padLeft(2, '0'),
                                          'hours',
                                        ),
                                        _timeBox(
                                          mins.toString().padLeft(2, '0'),
                                          'mins',
                                        ),
                                        _timeBox(
                                          secs.toString().padLeft(2, '0'),
                                          'secs',
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 15),

                                    Text(
                                      'Until our wedding',
                                      style: GoogleFonts.allura(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 6),
                                    Text(
                                      '${weddingDate.day.toString().padLeft(2, '0')}/'
                                      '${weddingDate.month.toString().padLeft(2, '0')}/'
                                      '${weddingDate.year}',
                                      style: GoogleFonts.libreBodoni(
                                        fontSize: 18,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Venue section
          if (venueName != null && venueLat != null && venueLng != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: venueCard(
                venueName: venueName,
                lat: venueLat,
                lng: venueLng,
              ),
            ),
          //quick Navigating buttons
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomElevatedButton3(text: "Sign Board", onPressed: () {}),
                  CustomElevatedButton3(text: "Photo Wall", onPressed: () {}),
                ],
              ),
              SizedBox(height: 25),
              CustomElevatedButton3(text: "Manage Profile", onPressed: () {}),
            ],
          ),
          SizedBox(height: 20),
          // CONTENT SECTION
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'User',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                /// 👇 Add dashboard cards here
              ],
            ),
          ),
        ],
      ),
    );
  }

  //BOTTOM NAVIGATION BAR

  /// 🔹 FALLBACK LAYOUT
  Widget _buildDefaultLayout(double screenHeight) {
    return Container(
      height: screenHeight,
      color: Colors.white,
      child: const Center(
        child: Text(
          'Error fetching wedding data.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  // Helper widget for remaining time display
  Widget _timeBox(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.libreBodoni(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }

  // Helper widget that creates the Venue section
  Widget venueCard({
    required String venueName,
    required double lat,
    required double lng,
  }) {
    return GestureDetector(
      onTap: () => openGoogleMaps(lat, lng),
      child: Card(
        color: const Color(0xFFF8E6EC).withOpacity(0.7),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              /// TITLE
              Text(
                "VENUE",
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              /// VENUE NAME
              Text(
                venueName,
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              /// ADDRESS
              const SizedBox(height: 16),

              /// MAP PREVIEW (FREE)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.memory(
                      _mapImageBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),

                    /// Overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Open in Google Maps",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
