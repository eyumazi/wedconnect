import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedconnect/screens/main%20screens/GuestHomeScreen.dart';

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

  // Function to mark guest as arrived
  Future<void> _markGuestAsArrived(String guestId) async {
    try {
      // Update the guest's is_arrived status and set arrival_time
      await supabase
          .from('guests')
          .update({
            'is_arrived': true,
            'arrival_time': DateTime.now().toIso8601String(),
          })
          .eq('id', guestId);

      print('Guest $guestId marked as arrived');
    } catch (e) {
      print('Error marking guest as arrived: $e');
      // Don't throw error here - we still want to let the guest in
    }
  }

  Future<void> processQRCode(String qrData) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      scannedResult = qrData;
      statusMessage = 'Processing...';
    });

    try {
      // Try to parse as JSON first (new QR format)
      Map<String, dynamic>? qrJson;
      try {
        qrJson = json.decode(qrData);
      } catch (_) {
        // Not JSON, treat as old format
      }

      String? guestId;
      String? guestName;

      if (qrJson != null && qrJson['type'] == 'guest_invitation') {
        // New QR format with guest info
        guestId = qrJson['guest_id'] as String?;
        guestName = qrJson['guest_name'] as String?;

        if (guestId != null) {
          // Verify guest exists
          final guestResponse = await supabase
              .from('guests')
              .select()
              .eq('id', guestId)
              .maybeSingle();

          if (guestResponse != null) {
            guestName = guestResponse['guest_name'] ?? 'Guest';

            // MARK GUEST AS ARRIVED
            await _markGuestAsArrived(guestId);

            setState(() {
              isSuccess = true;
              statusMessage = 'Welcome, $guestName!';
            });

            await Future.delayed(Duration(seconds: 1));

            if (mounted) {
              // Navigate to GuestHomeScreen WITH guestId
              Get.offAll(
                () => GuestHomeScreen(guestToken: qrData, guestId: guestId),
              );
            }
            return;
          }
        }
      }

      // Fallback: Check if it's a valid guest QR code (old format - invitation_token)
      final guestResponse = await supabase
          .from('guests')
          .select()
          .eq('invitation_token', qrData)
          .maybeSingle();

      if (guestResponse != null) {
        guestId = guestResponse['id'];
        guestName = guestResponse['guest_name'] ?? 'Guest';

        // MARK GUEST AS ARRIVED
        await _markGuestAsArrived(guestId!);

        setState(() {
          isSuccess = true;
          statusMessage = 'Welcome, $guestName!';
        });

        await Future.delayed(Duration(seconds: 1));

        if (mounted) {
          // Navigate to GuestHomeScreen WITH guestId
          Get.offAll(
            () => GuestHomeScreen(guestToken: qrData, guestId: guestId),
          );
        }
        return;
      }

      // If not a guest invitation QR, check if it's an arrival QR (for separate arrival scanning)
      try {
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

        Get.snackbar(
          isSuccess ? 'Success' : 'Error',
          statusMessage!,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );

        if (isSuccess) {
          await Future.delayed(Duration(seconds: 2));
          resetScanner();
        }
      } catch (e) {
        // Not an arrival QR either
        setState(() {
          isSuccess = false;
          statusMessage =
              'Invalid QR code. Please scan a valid guest invitation.';
        });

        Get.snackbar(
          'Invalid QR Code',
          'Invalid QR code',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Error processing QR: $e');
      setState(() {
        isSuccess = false;
        statusMessage = 'Error: ${e.toString()}';
      });

      Get.snackbar(
        'Scanning Failed',
        'Scanning failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } finally {
      if (!isSuccess) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void resetScanner() {
    setState(() {
      scannedResult = null;
      statusMessage = null;
      isSuccess = false;
      isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Scan QR Code',
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
          if (scannedResult != null && statusMessage != null)
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
                          statusMessage!,
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
                        if (isSuccess)
                          ElevatedButton(
                            onPressed: () {
                              if (scannedResult != null) {
                                // Re-process the QR code to navigate properly
                                processQRCode(scannedResult!);
                              } else {
                                Get.offAll(() => GuestHomeScreen());
                              }
                            },
                            child: Text('Continue'),
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

          // Loading overlay
          if (isProcessing &&
              (statusMessage == null || statusMessage == 'Processing...'))
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'Verifying QR code...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Instructions
          if (scannedResult == null && !isProcessing)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Scan your invitation QR code',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Position QR code within the frame',
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
