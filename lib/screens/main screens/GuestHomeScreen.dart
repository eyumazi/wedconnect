import 'dart:convert' show base64Decode;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Authentication/Wrapper.dart';
import 'package:wedconnect/Reusable%20components/Button3.dart';
import 'package:wedconnect/Reusable%20components/CustomUploadingButton.dart';
import 'package:wedconnect/Util.dart' show openGoogleMaps;
import 'package:wedconnect/screens/main%20screens/photoWallScreen.dart';
import 'package:wedconnect/screens/main%20screens/signBoardScreen.dart'; // Import Signboardscreen

class GuestHomeScreen extends StatefulWidget {
  final String? guestToken; // Optional: Pass guest token if needed
  final String? guestId; // Add this parameter

  const GuestHomeScreen({super.key, this.guestToken, this.guestId});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

Future<void> guestSignout() async {
  // For guest, just go back to login/wrapper
  Get.offAll(() => const Wrapper());
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> weddingData = [];
  bool isLoading = true;
  String errorMessage = '';
  Uint8List? _mapImageBytes;
  int _selectedIndex = 0; // For bottom navigation bar
  String? guestName;
  String? guestToken;
  String? _guestId; // Store guest ID

  // Bottom navigation bar items - REMOVED Guest List
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    guestToken = widget.guestToken;
    _guestId = widget.guestId; // Use passed guestId if available

    if (_guestId != null) {
      _loadGuestInfo();
    } else if (guestToken != null) {
      _loadGuestIdFromToken();
    }

    _loadWeddingData();

    // Initialize pages
    _pages = [
      const SizedBox(), // Home (handled separately)
      _guestId != null
          ? Signboardscreen(
              isHost: false,
              guestId: _guestId!,
            ) // Sign Board for GUESTS
          : const Placeholder(), // Placeholder if no guestId yet
      PhotoWallScreen(isHost: false, guestId: _guestId), // Gallery
      const Placeholder(), // Thank You
    ];
  }

  Future<void> _loadGuestIdFromToken() async {
    if (guestToken != null) {
      try {
        final guestResponse = await supabase
            .from('guests')
            .select('id, guest_name')
            .eq('invitation_token', guestToken!)
            .maybeSingle();

        if (guestResponse != null) {
          setState(() {
            guestName = guestResponse['guest_name'] as String?;
            _guestId = guestResponse['id'] as String?;
            _updatePages();
          });
        }
      } catch (e) {
        print('Error loading guest info from token: $e');
      }
    }
  }

  Future<void> _loadGuestInfo() async {
    if (_guestId != null) {
      try {
        final guestResponse = await supabase
            .from('guests')
            .select('guest_name')
            .eq('id', _guestId!)
            .single();

        if (guestResponse != null) {
          setState(() {
            guestName = guestResponse['guest_name'] as String?;
          });
        }
      } catch (e) {
        print('Error loading guest info: $e');
      }
    }
  }

  void _updatePages() {
    setState(() {
      _pages = [
        const SizedBox(), // Home
        _guestId != null
            ? Signboardscreen(
                isHost: false,
                guestId: _guestId!,
              ) // Sign Board for GUESTS
            : const Placeholder(),
        const Placeholder(), // Gallery
        const Placeholder(), // Thank You
      ];
    });
  }

  void _onItemTapped(int index) {
    if (index == 1 && _guestId == null) {
      // Don't navigate to sign board if no guest ID
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please scan your invitation QR first')),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadWeddingData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Try to load the first wedding in the database
      // In a real app, you might want to filter by wedding ID or organization
      final response = await supabase
          .from('weddings')
          .select()
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
        errorMessage = 'Failed to load wedding details. Please try again.';
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

    // Check if we have wedding data
    final bool hasWeddingData = weddingData.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: _selectedIndex == 0 && hasWeddingData,
      body: _selectedIndex == 0
          ? _buildHomeContent(screenHeight, hasWeddingData)
          : _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 && hasWeddingData
          ? FloatingActionButton(
              onPressed: guestSignout,
              backgroundColor: Colors.white,
              child: const Icon(Icons.logout, color: Colors.black),
            )
          : null,
      bottomNavigationBar: hasWeddingData
          ? SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: GuestLuxuryBottomNav(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHomeContent(double screenHeight, bool hasWeddingData) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If no wedding data found
    if (!hasWeddingData) {
      return _buildWelcomeScreen();
    }

    // Normal flow - wedding data available
    return _buildWeddingContent(screenHeight);
  }

  Widget _buildWelcomeScreen() {
    return Container(
      color: Color(0xFFFFE3EF),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome message with guest name if available
              if (guestName != null) ...[
                Text(
                  'Welcome, $guestName!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC19AC7),
                  ),
                ),
                SizedBox(height: 10),
              ],

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

              SizedBox(height: 20),

              // Subtitle
              Text(
                guestName != null
                    ? 'Thank you for joining us on this special day'
                    : 'Welcome to the Wedding!',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  color: Color(0xFFC19AC7).withOpacity(0.8),
                ),
              ),

              SizedBox(height: 30),

              // Error message if no wedding data
              if (errorMessage.isNotEmpty)
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
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 16,
                      color: Color(0xFFC19AC7),
                    ),
                  ),
                )
              else
                // Wedding Information Card
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
                      _buildInfoItem(
                        icon: Icons.calendar_today,
                        text: 'View wedding details',
                      ),
                      SizedBox(height: 12),
                      _buildInfoItem(
                        icon: Icons.photo_camera,
                        text: 'Browse the photo gallery',
                      ),
                      SizedBox(height: 12),
                      _buildInfoItem(
                        icon: Icons.rate_review,
                        text: 'Leave a message on the sign board',
                      ),
                      SizedBox(height: 12),
                      _buildInfoItem(
                        icon: Icons.favorite,
                        text: 'Share your love and wishes',
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 40),

              // Explore Button
              Container(
                width: double.infinity,
                child: CustomUploadingButton(
                  text: 'Explore Wedding',
                  onPressed: _loadWeddingData,
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

  Widget _buildInfoItem({required IconData icon, required String text}) {
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
                                    // Guest welcome if available
                                    if (guestName != null) ...[
                                      Text(
                                        'Welcome, $guestName!',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                    ],

                                    // WEDDING NAME
                                    Text(
                                      weddingName ?? 'Wedding Celebration',
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
                                      'Until their wedding',
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
                  CustomElevatedButton3(
                    text: "Sign Board",
                    onPressed: () {
                      if (_guestId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please scan your invitation QR first',
                            ),
                          ),
                        );
                      } else {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      }
                    },
                  ),
                  CustomElevatedButton3(
                    text: "Photo Wall",
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 25),
              CustomElevatedButton3(
                text: "Thank You",
                onPressed: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 20),
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

class GuestLuxuryBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  static const List<String> _labels = [
    'Home',
    'Sign Board',
    'Gallery',
    'Thank You',
  ];

  const GuestLuxuryBottomNav({
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
          children: List.generate(4, (index) {
            return _GuestLuxuryNavItem(
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
        return Icon(Icons.rate_review);
      case 2:
        return Icon(FontAwesome.camera);
      case 3:
        return Icon(Icons.favorite);
      default:
        return Icon(Icons.circle);
    }
  }
}

class _GuestLuxuryNavItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget icon;
  final String label;

  const _GuestLuxuryNavItem({
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
