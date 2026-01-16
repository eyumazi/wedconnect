import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Authentication/Wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
        fontFamily: GoogleFonts.inter().fontFamily,

        textTheme: TextTheme(
          displayLarge: GoogleFonts.inspiration(
            fontSize: 72,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: GoogleFonts.inspiration(
            fontSize: 56,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: GoogleFonts.allura(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: GoogleFonts.instrumentSerif(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          labelLarge: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ).apply(fontFamily: GoogleFonts.cormorantGaramond().fontFamily),

        snackBarTheme: SnackBarThemeData(
          contentTextStyle: GoogleFonts.cormorantGaramond(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      home: Wrapper(),
    );
  }
}
