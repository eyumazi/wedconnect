import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const CustomElevatedButton({Key? key, required this.text, this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        foregroundColor: WidgetStateProperty.all(const Color(0xFF5AA0D6)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
        shadowColor: WidgetStateProperty.all(
          const Color(0xFF5AA0D6).withOpacity(0.45),
        ),
        elevation: WidgetStateProperty.all(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.instrumentSerif(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF5AA0D6),
        ),
      ),
    );
  }
}
