import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

pickImage(ImageSource source) async {
  final ImagePicker _imgepicker = ImagePicker();
  XFile? _file = await _imgepicker.pickImage(source: source);
  if (_file != null) {
    return await _file.readAsBytes();
  }
  return null;
}

class OSMLocationService {
  /// Search places
  static Future<List<dynamic>> searchPlace(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$query'
      '&format=json'
      '&addressdetails=1'
      '&limit=5',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'wedconnect-app'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch locations');
    }
  }

  /// Static map preview
  static Future<Uint8List?> getStaticMapImage(double lat, double lng) async {
    try {
      const apiKey =
          'pk.c56018c5255bcaeb963d9f60a3226bad'; // LocationIQ API Key

      final url = Uri.parse(
        'https://maps.locationiq.com/v3/staticmap'
        '?key=$apiKey'
        '&center=$lat,$lng'
        '&zoom=14'
        '&size=600x300'
        '&format=png'
        '&markers=icon:small-red-cutout|$lat,$lng',
      );

      print("Fetching map from: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("Map fetched successfully (${response.bodyBytes.length} bytes)");
        return response.bodyBytes;
      } else {
        print("Failed to fetch map: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching static map: $e");
      return null;
    }
  }

  /// Remove Arabic characters
  static String cleanText(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return text.replaceAll(arabicRegex, '').trim();
  }
}

//Featching functions for displaying data from the database.
final supabase = Supabase.instance.client;
final uid = FirebaseAuth.instance.currentUser!.uid;

//A function used for fetching wedding data.
Future<List<dynamic>> fetchWeddingData() async {
  return await supabase.from('weddings').select().eq('user_id', uid);
}

//Helper function to open Google Maps at specific coordinates i've used it on the map displayed on the homescree.
Future<void> openGoogleMaps(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not open Google Maps';
  }
}
