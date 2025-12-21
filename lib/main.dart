import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wedconnect/screens/splashscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload ALL fonts you'll use in the app
  await GoogleFonts.pendingFonts([
    GoogleFonts.getFont('Inspiration'), // Your custom font
    GoogleFonts.getFont('Cormorant Garamond'), // Add more fonts
    GoogleFonts.getFont('Roboto'), // Another font
    GoogleFonts.getFont('Instrument Serif'), // And more...
    // Add any other Google Fonts you plan to use
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WedConnect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Define multiple text styles with different fonts
        textTheme: TextTheme(
          displayLarge: GoogleFonts.inspiration(
            fontSize: 72,
            fontWeight: FontWeight.w400,
          ),
          displayMedium: GoogleFonts.inspiration(
            fontSize: 56,
            fontWeight: FontWeight.w400,
          ),
          // For body text, use a different font
          bodyLarge: GoogleFonts.cormorantGaramond(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.instrumentSerif(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          // Add more as needed
        ),
      ),
      home: Splashscreen(),
    );
  }
}
