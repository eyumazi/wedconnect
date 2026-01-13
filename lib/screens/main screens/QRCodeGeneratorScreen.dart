import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QRCodeGeneratorScreen extends StatefulWidget {
  final String guestId;
  final String guestName;

  const QRCodeGeneratorScreen({
    Key? key,
    required this.guestId,
    required this.guestName,
  }) : super(key: key);

  @override
  State<QRCodeGeneratorScreen> createState() => _QRCodeGeneratorScreenState();
}

class _QRCodeGeneratorScreenState extends State<QRCodeGeneratorScreen> {
  String? qrData;
  bool isLoading = true;

  final supabase = Supabase.instance.client;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _generateInvitationQRCode();
  }

  // ===== Generate QR bytes =====
  Future<Uint8List?> _generateQrBytes({double size = 300}) async {
    if (qrData == null || qrData!.isEmpty) return null;

    final painter = QrPainter(
      data: qrData!,
      version: QrVersions.auto,
      color: Colors.black,
      emptyColor: Colors.white,
    );

    // 👇 PASS INT DIRECTLY (NO CAST!)
    final ui.Image image = await painter.toImage(size);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  // ===== Generate QR Token =====
  Future<void> _generateInvitationQRCode() async {
    try {
      // Get full guest info to embed in QR
      final guestResponse = await supabase
          .from('guests')
          .select('id, guest_name, phone_number')
          .eq('id', widget.guestId)
          .single();

      // Create a structured QR data that includes guest ID
      final qrPayload = {
        'type': 'guest_invitation',
        'guest_id': widget.guestId,
        'guest_name': guestResponse['guest_name'],
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Convert to JSON string for QR code
      final qrDataString = json.encode(qrPayload);

      // Store this QR data in the guest's record
      await supabase
          .from('guests')
          .update({'invitation_token': qrDataString})
          .eq('id', widget.guestId);

      setState(() {
        qrData = qrDataString;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('QR generation error: $e');
      setState(() => isLoading = false);
    }
  }

  // ===== Update invitation_sent status and related fields =====
  Future<void> _updateInvitationSentStatus() async {
    try {
      // Update multiple fields when invitation is sent
      await supabase
          .from('guests')
          .update({
            'invitation_sent': true, // Mark as sent
            'invitation_expiry': DateTime.now()
                .add(const Duration(days: 30))
                .toIso8601String(), // Set 30-day expiry
            'guest_access': true, // Grant access to guest
          })
          .eq('id', widget.guestId);

      debugPrint('Invitation sent status updated for guest: ${widget.guestId}');
    } catch (e) {
      debugPrint('Error updating invitation status: $e');
    }
  }

  // ===== Save to Gallery =====
  Future<void> _saveQRCodeToGallery() async {
    try {
      final bytes = await _generateQrBytes(size: 400);
      if (bytes == null) return;

      final directory = Directory('/storage/emulated/0/Pictures/WedConnect');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/Invitation_${widget.guestName}.png');

      await file.writeAsBytes(bytes);

      // ⭐ UPDATE THE DATABASE - Mark invitation as sent
      await _updateInvitationSentStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code saved and invitation marked as sent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  // ===== Share QR =====
  Future<void> _shareQRCode() async {
    try {
      final bytes = await _generateQrBytes();
      if (bytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Invitation_${widget.guestName}.png');

      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'You are invited to our wedding 💍✨\n'
            'Guest: ${widget.guestName}\n\n'
            'Scan the QR code to access wedding details.',
      );

      // ⭐ UPDATE THE DATABASE - Mark invitation as sent
      await _updateInvitationSentStatus();

      _snack('Invitation shared successfully!', success: true);
    } catch (e) {
      _snack('Error sharing QR Code: $e');
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Generate Invitation",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _guestCard(),
                  const SizedBox(height: 30),
                  _qrCard(),
                  const SizedBox(height: 30),
                  _actionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _guestCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _boxDecoration(),
    child: Column(
      children: [
        Text(
          widget.guestName,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const Text('Invitation QR Code', style: TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _qrCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _boxDecoration(),
    child: Column(
      children: [
        QrImageView(
          data: qrData ?? '',
          size: 250,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan this QR code to accept invitation',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _actionButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      ElevatedButton.icon(
        onPressed: _saveQRCodeToGallery,
        icon: const Icon(Icons.download),
        label: const Text('Save'),
      ),
      ElevatedButton.icon(
        onPressed: _shareQRCode,
        icon: const Icon(Icons.share),
        label: const Text('Share'),
      ),
    ],
  );

  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
  );
}
