import 'dart:convert' show base64Decode;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:icons_flutter/icons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Authentication/Wrapper.dart';
import 'package:wedconnect/Reusable%20components/Button3.dart';
import 'package:wedconnect/Reusable%20components/CustomUploadingButton.dart';
import 'package:wedconnect/Util.dart' show openGoogleMaps;
import 'package:wedconnect/screens/Form%20Screens/ProfileSetup.dart';
import 'package:wedconnect/screens/main%20screens/GuestListScreen.dart';
import 'package:wedconnect/screens/main%20screens/signBoardScreen.dart';

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
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  String errorMessage = '';
  Uint8List? _mapImageBytes;
  int _selectedIndex = 0; // For bottom navigation bar

  // Bottom navigation bar items
  final List<Widget> _pages = [
    const SizedBox(), // Home (handled separately)
    GuestScreen(), // Guest List ✅
    Signboardscreen(), // Sign Board
    Placeholder(), // Gallery
    Placeholder(), // Thank You
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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Load user profile first
      final profileResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('id', uid)
          .maybeSingle();

      setState(() {
        userProfile = profileResponse;
      });

      // Only load wedding data if profile exists
      if (userProfile != null) {
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
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        errorMessage = 'Failed to load data. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToProfileSetup() {
    Get.to(() => ProfileSetupScreen());
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Check if user has profile and wedding data
    final bool hasProfile = userProfile != null;
    final bool hasWeddingData = weddingData.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar:
          _selectedIndex == 0 && hasProfile && hasWeddingData,
      body: _selectedIndex == 0
          ? _buildHomeContent(screenHeight, hasProfile, hasWeddingData)
          : _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 && hasProfile && hasWeddingData
          ? FloatingActionButton(
              onPressed: signout,
              backgroundColor: Colors.white,
              child: const Icon(Icons.logout, color: Colors.black),
            )
          : null,
      bottomNavigationBar: hasProfile && hasWeddingData
          ? SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: LuxuryBottomNav(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHomeContent(
    double screenHeight,
    bool hasProfile,
    bool hasWeddingData,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If user doesn't have profile
    if (!hasProfile) {
      return _buildProfileSetupPrompt(
        title: 'Welcome to WedConnect!',
        subtitle: 'You need to set up your profile first',
        buttonText: 'Set Up Profile',
      );
    }

    // If user has profile but no wedding data
    if (!hasWeddingData) {
      return _buildProfileSetupPrompt(
        title: 'Complete Your Wedding Details',
        subtitle: 'Add your wedding information to get started',
        buttonText: 'Add Wedding Details',
      );
    }

    // Normal flow - user has both profile and wedding data
    return _buildWeddingContent(screenHeight);
  }

  Widget _buildProfileSetupPrompt({
    required String title,
    required String subtitle,
    required String buttonText,
  }) {
    return Container(
      color: Color(0xFFFFE3EF),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decorative Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Color(0xFFC19AC7).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFC19AC7), width: 2),
                ),
                child: Icon(
                  Icons.celebration,
                  size: 60,
                  color: Color(0xFFC19AC7),
                ),
              ),

              SizedBox(height: 30),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC19AC7),
                ),
              ),

              SizedBox(height: 16),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  color: Color(0xFFC19AC7).withOpacity(0.8),
                ),
              ),

              SizedBox(height: 30),

              // Instruction List
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFC19AC7).withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInstructionItem(
                      icon: Icons.person,
                      text: 'Add your personal details',
                    ),
                    SizedBox(height: 12),
                    _buildInstructionItem(
                      icon: Icons.favorite,
                      text: "Enter your partner's name",
                    ),
                    SizedBox(height: 12),
                    _buildInstructionItem(
                      icon: Icons.calendar_today,
                      text: 'Set your wedding info',
                    ),
                    SizedBox(height: 12),
                    _buildInstructionItem(
                      icon: Icons.photo_camera,
                      text: 'Upload a profile photo',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Setup Button
              Container(
                width: double.infinity,
                child: CustomUploadingButton(
                  text: buttonText,
                  onPressed: _navigateToProfileSetup,
                  isLoading: false,
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(0xFFC19AC7).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Color(0xFFC19AC7)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16,
              color: Color(0xFFC19AC7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeddingContent(double screenHeight) {
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
              CustomElevatedButton3(
                text: "Manage Profile",
                onPressed: _navigateToProfileSetup,
              ),
            ],
          ),
          SizedBox(height: 20),
          // CONTENT SECTION
        ],
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
      child: Container(
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
            if (_mapImageBytes != null)
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
    );
  }
}

class LuxuryBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  static const List<String> _labels = [
    'Home',
    'Guest List',
    'Sign Board',
    'Gallery',
    'Thank You',
  ];

  const LuxuryBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE9F0),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            return _LuxuryNavItem(
              isSelected: currentIndex == index,
              onTap: () => onTap(index),
              icon: _placeholderIcon(index),
              label: _labels[index],
            );
          }),
        ),
      ),
    );
  }

  /// TEMP icons – you will replace these later
  Widget _placeholderIcon(int index) {
    switch (index) {
      case 0:
        return Icon(FontAwesome.home);
      case 1:
        return Icon(FontAwesome.users);
      case 2:
        return Icon(Icons.rate_review);
      case 3:
        return Icon(FontAwesome.camera);
      case 4:
        return Icon(Icons.favorite);
      default:
        return Icon(Icons.circle);
    }
  }
}

class _LuxuryNavItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget icon;
  final String label;

  const _LuxuryNavItem({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFFFF8FAF)
                  : const Color(0xFFFDEFF4),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: IconTheme(
              data: IconThemeData(
                size: 22,
                color: isSelected
                    ? Colors.white
                    : Colors.pinkAccent.withOpacity(0.8),
              ),
              child: icon,
            ),
          ),

          const SizedBox(height: 6),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: isSelected ? 1 : 0.45,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              offset: isSelected ? Offset.zero : const Offset(0, 0.2),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.pinkAccent.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
