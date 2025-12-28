import 'package:flutter/material.dart';

Widget textInsideWithIcon(String text, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: Color(0xFFFE96AF)),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 16)),
      ],
    ),
  );
}

Widget textFieldWithIconField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  Function(String)? onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        icon: Icon(icon, color: Color(0xFFFE96AF)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: InputBorder.none,
      ),
    ),
  );
}
