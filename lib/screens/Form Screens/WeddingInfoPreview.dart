import 'dart:convert' show base64Decode;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Reusable components/Button2.dart';

class WeddingPreviewScreen extends StatefulWidget {
  const WeddingPreviewScreen({super.key});

  @override
  State<WeddingPreviewScreen> createState() => _WeddingPreviewScreenState();
}

class _WeddingPreviewScreenState extends State<WeddingPreviewScreen> {
  Map<String, dynamic>? weddingData;
  Uint8List? _mapImageBytes;
  bool isLoading = true;
  String errorMessage = '';

  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

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

      // Fetch wedding data for the current user
      final response = await supabase
          .from('weddings')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      setState(() {
        weddingData = response;

        // Decode base64 image if exists
        if (weddingData!['venue_map_image'] != null) {
          try {
            _mapImageBytes = base64Decode(weddingData!['venue_map_image']);
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMMM dd, yyyy').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFFFE96AF), size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            "Wedding Preview",
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadWeddingData,
              tooltip: 'Refresh Data',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Text(
                "Your Wedding Details",
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "All the information you've provided",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 30),

              if (isLoading)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        "Loading your wedding details...",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                )
              else if (errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 50, color: Colors.orange),
                      SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate back to wedding setup
                          Navigator.pop(context);
                        },
                        child: Text("Go to Wedding Setup"),
                      ),
                    ],
                  ),
                )
              else if (weddingData != null)
                Column(
                  children: [
                    // Wedding Name Banner
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFFE96AF).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "The Wedding of",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            weddingData!['wedding_name'] ?? 'Unnamed Wedding',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),

                    // Couple Information
                    _buildInfoCard(
                      "The Groom",
                      weddingData!['groom_name'] ?? 'Not specified',
                      Icons.person,
                    ),
                    SizedBox(height: 16),

                    _buildInfoCard(
                      "The Bride",
                      weddingData!['bride_name'] ?? 'Not specified',
                      Icons.person,
                    ),
                    SizedBox(height: 16),

                    // Wedding Date
                    _buildInfoCard(
                      "Wedding Date",
                      weddingData!['wedding_date'] != null
                          ? _formatDate(weddingData!['wedding_date'])
                          : 'Not set',
                      Icons.calendar_month,
                    ),
                    SizedBox(height: 16),

                    // Venue Information
                    if (weddingData!['venue_name'] != null &&
                        weddingData!['venue_name'].isNotEmpty)
                      Column(
                        children: [
                          _buildInfoCard(
                            "Wedding Venue",
                            weddingData!['venue_name'],
                            Icons.location_on,
                          ),
                          SizedBox(height: 16),
                        ],
                      ),

                    // Map Preview
                    if (_mapImageBytes != null)
                      Column(
                        children: [
                          Text(
                            "Venue Location",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    color: Color(0xFFFE96AF).withOpacity(0.9),
                                    child: Row(
                                      children: [
                                        Icon(Icons.map, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          "Location Map",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Spacer(),
                                        if (weddingData!['venue_lat'] != null &&
                                            weddingData!['venue_lng'] != null)
                                          Text(
                                            "${weddingData!['venue_lat']!.toStringAsFixed(4)}, "
                                            "${weddingData!['venue_lng']!.toStringAsFixed(4)}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Image.memory(
                                    _mapImageBytes!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),

                    // Coordinates if available
                    if (weddingData!['venue_lat'] != null &&
                        weddingData!['venue_lng'] != null &&
                        _mapImageBytes == null)
                      _buildInfoCard(
                        "Venue Coordinates",
                        "Lat: ${weddingData!['venue_lat']!.toStringAsFixed(6)}, "
                            "Lng: ${weddingData!['venue_lng']!.toStringAsFixed(6)}",
                        Icons.gps_fixed,
                      ),

                    SizedBox(height: 30),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Edit wedding info - navigate back to WeddingInfo screen
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Color(0xFFFE96AF)),
                            ),
                            child: Text(
                              "Edit Details",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: CustomElevatedButton2(
                            text: "Continue",
                            onPressed: () {
                              // Navigate to next screen (Theme and Cover)
                              // You'll need to implement this navigation
                              Navigator.pushNamed(context, '/theme-setup');
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Data summary
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Data Status",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Complete",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "User ID",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                uid.substring(0, 8) + "...",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
