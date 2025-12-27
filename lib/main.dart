import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/screens/Form%20Screens/weddingInfo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://ddluaenjbcatrjaziqzc.supabase.co",
    anonKey: "sb_publishable_YktGN7tpWvYXXAhGpLXXvw_u7Zz-BhR",
  );

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WedConnect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.inter().fontFamily, // Set as default font
        textTheme:
            TextTheme(
              displayLarge: GoogleFonts.inspiration(
                fontSize: 72,
                fontWeight: FontWeight.w600,
              ),
              displayMedium: GoogleFonts.inspiration(
                fontSize: 56,
                fontWeight: FontWeight.w600,
              ),
              bodyLarge: GoogleFonts.allura(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              bodyMedium: GoogleFonts.instrumentSerif(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              labelLarge: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ).apply(
              fontFamily: GoogleFonts.cormorantGaramond()
                  .fontFamily, // Apply to all text styles
            ),
      ),
      //home: Wrapper(),
      home: WeddingInfo(),
    );
  }
}
