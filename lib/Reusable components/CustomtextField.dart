import 'package:flutter/material.dart';

Widget TextBox(String text) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [Text(text, style: TextStyle(fontSize: 16))]),
  );
}

Widget textField({
  required TextEditingController controller,
  required String hint,
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
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: InputBorder.none,
      ),
    ),
  );
}
