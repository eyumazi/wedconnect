import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/Authentication/Wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? startupError;
  try {
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined in .env.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    await Firebase.initializeApp(
      options: kIsWeb
          ? const FirebaseOptions(
              apiKey: 'AIzaSyCo3QE6RoUHwFW9hNVQ8jW5ktx95WD3Tbo',
              appId: '1:69195515876:android:38ccf0c38f069d171329f1',
              messagingSenderId: '69195515876',
              projectId: 'wedconnect-auth',
              authDomain: 'wedconnect-auth.firebaseapp.com',
              storageBucket: 'wedconnect-auth.firebasestorage.app',
            )
          : null,
    );
  } on Object catch (error, stackTrace) {
    startupError = error;
    debugPrint('Application startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(MyApp(startupError: startupError));
}

class MyApp extends StatelessWidget {
  final Object? startupError;

  const MyApp({super.key, this.startupError});

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
      home: startupError == null
          ? const Wrapper()
          : StartupErrorScreen(error: startupError!),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  final Object error;

  const StartupErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'WedConnect could not start',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
