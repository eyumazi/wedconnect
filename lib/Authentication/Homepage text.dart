import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Authentication/Wrapper.dart';
import 'package:wedconnect/Util.dart' show fetchWeddingData, openGoogleMaps;

class HomepageTest extends StatefulWidget {
  const HomepageTest({super.key});

  @override
  State<HomepageTest> createState() => _HomepageTestState();
}

Future<void> signout() async {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  await googleSignIn.signOut();
  await FirebaseAuth.instance.signOut();
  Get.offAll(() => const Wrapper());
}

class _HomepageTestState extends State<HomepageTest> {
  final user = FirebaseAuth.instance.currentUser;
  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  late Future<List<dynamic>> weddingData;

  @override
  void initState() {
    super.initState();
    weddingData = fetchWeddingData();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    Duration getRemainingTime(DateTime weddingDate) {
      final now = DateTime.now();
      return weddingDate.difference(now);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: FutureBuilder<List<dynamic>>(
        future: weddingData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return _buildDefaultLayout(screenHeight);
          }

          //Variables used for fetched values
          final coverUrl = snapshot.data![0]['cover_image_url'] as String?;
          final weddingName = snapshot.data![0]['wedding_name'] as String?;
          final weddingDateString =
              snapshot.data![0]['wedding_date'] as String?;
          final weddingDate = weddingDateString != null
              ? DateTime.parse(weddingDateString)
              : null;
          final venueName = snapshot.data![0]['venue_name'] as String?;
          final venueAddress = snapshot.data![0]['venue_address'] as String?;
          final venueLat = snapshot.data![0]['venue_lat'] as double?;
          final venueLng = snapshot.data![0]['venue_lng'] as double?;

          return SingleChildScrollView(
            child: Column(
              children: [
                //COVER SECTION
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

                      //VIGNETTE
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
                        bottom: 30,
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
                                //count down box
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 30,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF8E6EC,
                                    ).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: StreamBuilder(
                                    stream: Stream.periodic(
                                      const Duration(seconds: 1),
                                    ),
                                    builder: (context, snapshot) {
                                      final remaining = getRemainingTime(
                                        weddingDate,
                                      );

                                      final days = remaining.inDays;
                                      final hours = remaining.inHours % 24;
                                      final mins = remaining.inMinutes % 60;
                                      final secs = remaining.inSeconds % 60;

                                      return Column(
                                        children: [
                                          //WEDDING NAME
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
                                                hours.toString().padLeft(
                                                  2,
                                                  '0',
                                                ),
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
                              //Venue section
                              if (venueName != null &&
                                  venueAddress != null &&
                                  venueLat != null &&
                                  venueLng != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: venueCard(
                                    venueName: venueName,
                                    venueAddress: venueAddress,
                                    lat: venueLat,
                                    lng: venueLng,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //CONTENT SECTION
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
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: signout,
        backgroundColor: Colors.white,
        child: const Icon(Icons.logout, color: Colors.black),
      ),
    );
  }

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
}

//helper widget for remaining time display
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

//helper widget that creates the Venue section
Widget venueCard({
  required String venueName,
  required String venueAddress,
  required double lat,
  required double lng,
}) {
  final mapUrl =
      'https://maps.googleapis.com/maps/api/staticmap'
      '?center=$lat,$lng'
      '&zoom=15'
      '&size=600x300'
      '&markers=color:red%7C$lat,$lng'
      '&key=YOUR_GOOGLE_MAPS_API_KEY';

  return GestureDetector(
    onTap: () => openGoogleMaps(lat, lng),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E6EC).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          /// TITLE
          Text(
            "VENUE",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          /// VENUE NAME
          Text(
            venueName,
            textAlign: TextAlign.center,
            style: GoogleFonts.libreBodoni(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          /// ADDRESS
          Text(
            venueAddress,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),

          const SizedBox(height: 16),

          /// MAP PREVIEW
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.network(
                  mapUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// Google badge overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Open in Maps",
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
