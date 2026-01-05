import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final supabase = Supabase.instance.client;
  bool isProcessing = false;
  String? scannedResult;
  String? statusMessage;
  bool isSuccess = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> processQRCode(String qrData) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      scannedResult = qrData;
      statusMessage = 'Processing...';
    });

    try {
      // Call Supabase function to mark guest as arrived
      final response = await supabase.rpc(
        'mark_guest_arrived',
        params: {'qr_data_param': qrData},
      );

      final result = response as Map<String, dynamic>;

      setState(() {
        isSuccess = result['success'] ?? false;
        statusMessage = result['message'] ?? 'Processing complete';

        if (result['guest_name'] != null) {
          statusMessage = '${result['guest_name']} - ${statusMessage}';
        }
      });

      // Show success/error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusMessage!),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // Reset after 2 seconds
      if (isSuccess) {
        await Future.delayed(Duration(seconds: 2));
        resetScanner();
      }
    } catch (e) {
      setState(() {
        isSuccess = false;
        statusMessage = 'Error: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanning failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void resetScanner() {
    setState(() {
      scannedResult = null;
      statusMessage = null;
      isSuccess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Scan Guest QR Code',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !isProcessing) {
                  processQRCode(barcode.rawValue!);
                }
              }
            },
          ),

          // Scanning overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Status overlay
          if (scannedResult != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    width: 300,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSuccess ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                          size: 60,
                        ),
                        SizedBox(height: 20),
                        Text(
                          statusMessage ?? 'Processing',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        if (!isSuccess)
                          ElevatedButton(
                            onPressed: resetScanner,
                            child: Text('Scan Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Instructions
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Position QR code within the frame',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Scanning will happen automatically',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
