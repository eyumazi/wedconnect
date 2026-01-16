import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThankYouScreen extends StatefulWidget {
  final bool isHost;
  final String? weddingId;

  const ThankYouScreen({super.key, required this.isHost, this.weddingId});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  late TextEditingController _thankYouController;
  bool _isEditing = false;
  String _thankYouText = '';
  bool _isLoading = true;
  bool _isSaving = false;

  List<dynamic> weddingData = [];
  String? _coverUrl;
  String? _weddingName;
  String? _coupleNames;
  final _supabase = Supabase.instance.client;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _thankYouController = TextEditingController();
    _loadWeddingData();
  }

  @override
  void dispose() {
    _thankYouController.dispose();
    super.dispose();
  }

  Future<void> _loadWeddingData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (widget.isHost) {
        await _loadHostWeddingData();
      } else {
        await _loadGuestWeddingData();
      }
    } catch (e) {
      print('Error loading wedding data: $e');
      _setDefaultValues();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHostWeddingData() async {
    try {
      final response = await _supabase
          .from('weddings')
          .select()
          .eq('user_id', _uid!)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        setState(() {
          weddingData = response;

          _coverUrl = response[0]['cover_image_url'] as String?;
          _weddingName = response[0]['wedding_name'] as String?;
          _coupleNames = response[0]['couple_names'] as String?;

          final existingText = response[0]['thank_you_text'] as String?;
          _thankYouText =
              existingText ??
              'Thank you for celebrating with us on our special day! Your presence and warm wishes mean the world to us.';
          _thankYouController.text = _thankYouText;
        });
      } else {
        _setDefaultValues();
      }
    } catch (e) {
      print('Error loading host wedding data: $e');
      _setDefaultValues();
    }
  }

  Future<void> _loadGuestWeddingData() async {
    try {
      String? targetWeddingId = widget.weddingId;

      if (targetWeddingId == null && _uid != null) {
        final guestResponse = await _supabase
            .from('guests')
            .select('wedding_id')
            .eq('guest_user_id', _uid)
            .maybeSingle();

        if (guestResponse != null) {
          targetWeddingId = guestResponse['wedding_id'] as String?;
        }
      }

      if (targetWeddingId != null) {
        final weddingResponse = await _supabase
            .from('weddings')
            .select()
            .eq('id', targetWeddingId)
            .single();

        if (weddingResponse != null) {
          setState(() {
            _coverUrl = weddingResponse['cover_image_url'] as String?;
            _weddingName = weddingResponse['wedding_name'] as String?;
            _coupleNames = weddingResponse['couple_names'] as String?;

            final existingText = weddingResponse['thank_you_text'] as String?;
            _thankYouText =
                existingText ??
                'Thank you for celebrating with us on our special day! Your presence and warm wishes mean the world to us.';
            _thankYouController.text = _thankYouText;
          });
        } else {
          _setDefaultValues();
        }
      } else {
        // Guest not linked to any wedding
        _setDefaultValues();
      }
    } catch (e) {
      print('Error loading guest wedding data: $e');
      _setDefaultValues();
    }
  }

  void _setDefaultValues() {
    _thankYouText =
        'Thank you for celebrating with us on our special day! Your presence and warm wishes mean the world to us.';
    _thankYouController.text = _thankYouText;
  }

  Future<void> _saveThankYouText() async {
    if (!widget.isHost) return; // Safety check - only hosts can save

    if (_thankYouController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter thank you text'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (weddingData.isNotEmpty) {
        final weddingId = weddingData[0]['id'];

        await _supabase
            .from('weddings')
            .update({'thank_you_text': _thankYouController.text.trim()})
            .eq('id', weddingId);

        setState(() {
          _thankYouText = _thankYouController.text.trim();
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you message saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('No wedding data found');
      }
    } catch (e) {
      print('Error saving thank you text: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _startEditing() {
    if (!widget.isHost) return;
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _thankYouController.text = _thankYouText;
    });
  }

  Widget _buildThankYouContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isEditing && widget.isHost) {
      return _buildEditView();
    }

    return _buildThankYouTextView();
  }

  Widget _buildThankYouTextView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Role indicator badge
            if (widget.isHost)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E6EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.black87),
                    const SizedBox(width: 6),
                    Text(
                      'Host',
                      style: GoogleFonts.libreBodoni(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            if (!widget.isHost)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.black87),
                    const SizedBox(width: 6),
                    Text(
                      'Guest',
                      style: GoogleFonts.libreBodoni(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            Text(
              'A Message from the Couple',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              _thankYouText,
              textAlign: TextAlign.center,
              style: GoogleFonts.libreBodoni(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Colors.grey[800],
                height: 1.8,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 30),

            // Couple's signature/names
            Text(
              'With love,',
              style: GoogleFonts.allura(fontSize: 32, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              _coupleNames ?? 'The Happy Couple',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            // EDIT BUTTON FOR HOSTS
            if (widget.isHost) ...[
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: _startEditing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8E6EC),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.grey.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.edit, size: 20),
                  label: Text(
                    'Edit Thank You Message',
                    style: GoogleFonts.libreBodoni(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8E6EC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Host Mode',
                              style: GoogleFonts.libreBodoni(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Edit Thank You Message',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _thankYouController,
                    maxLines: 8,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Type your thank you message here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF8E6EC)),
                      ),
                      fillColor: Colors.grey[50],
                      filled: true,
                    ),
                    style: GoogleFonts.libreBodoni(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tip: Personalize your message to make your guests feel special!',
                    style: GoogleFonts.libreBodoni(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _cancelEditing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.libreBodoni(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _saveThankYouText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8E6EC),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black87,
                          ),
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.libreBodoni(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildThankYouContent(),
                    const SizedBox(height: 40),

                    // Additional decorative elements
                    if (!_isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Divider(color: Colors.grey[300], thickness: 1),
                      ),

                    if (!_isEditing)
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(
                          'Thank you for being part of our journey',
                          style: GoogleFonts.allura(
                            fontSize: 26,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
