import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Guestlistform extends StatefulWidget {
  const Guestlistform({super.key});

  @override
  State<Guestlistform> createState() => _GuestlistformState();
}

class _GuestlistformState extends State<Guestlistform> {
  final GuestNameController = TextEditingController();
  final GuestphoneNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7EB3DB),
      appBar: AppBar(
        title: Text(
          "Invitation and Guest List",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.center,
        child: Container(
          width: 330,
          height: 460,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Color(0xFFFFE3EF),
          ),
          child: Column(
            children: [
              Text(
                "Add Guest",
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: GuestNameController,
                  decoration: InputDecoration(
                    hintText: "Enter Your Name",
                    hintStyle: TextStyle(color: Colors.black26),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: GuestNameController,
                  decoration: InputDecoration(
                    hintText: "Enter Your Phone Number",
                    hintStyle: TextStyle(color: Colors.black26),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  SizedBox(width: 30),
                  CircleAvatar(
                    radius: 35,
                    child: Icon(Icons.add_rounded, color: Colors.white),
                    backgroundColor: Color(0xFF7158E2).withOpacity(0.5),
                  ),
                  Column(children: []),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget addText(String text) {
  return Text(
    text,
    style: GoogleFonts.cormorantGaramond(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  );
}
