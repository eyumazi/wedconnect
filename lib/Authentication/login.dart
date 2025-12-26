import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wedconnect/Authentication/ForgotPassword.dart';
import 'package:wedconnect/Authentication/Homepage%20text.dart';
import 'package:wedconnect/Authentication/signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> signin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Get.offAll(() => HomepageTest());

      Get.snackbar(
        'Welcome',
        'Successfully logged in',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFC19AC7),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        default:
          errorMessage = 'Login failed. Please try again';
      }

      Get.snackbar(
        'Login Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFFE96AF),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFFE96AF),
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE3EF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50),

                  // Luxurious App Logo/Title
                  Column(
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFC19AC7).withOpacity(0.3),
                              blurRadius: 18,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/images/logo.png'),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'WedConnect',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC19AC7),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your Luxury Wedding Experience',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          color: Color(0xFFC19AC7).withOpacity(1),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 50),

                  // Welcome Back Text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Welcome',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC19AC7),
                      ),
                    ),
                  ),

                  SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sign in to continue your journey',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 16,
                        color: Color(0xFFC19AC7).withOpacity(1),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Email Field
                  _buildTextField(
                    controller: emailController,
                    label: 'Email Address',
                    hintText: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24),

                  // Password Field
                  _buildTextField(
                    controller: passwordController,
                    label: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Color(0xFFC19AC7).withOpacity(0.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.to(() => Forgotpassword()),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 16,
                          color: Color(0xFF5AA0D6),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Login Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFC19AC7), Color(0xFF5AA0D6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFC19AC7).withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : signin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Signing In...',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Sign In',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Color(0xFFC19AC7).withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'New to WedConnect?',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 14,
                            color: Color(0xFFC19AC7).withOpacity(1),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Color(0xFFC19AC7).withOpacity(0.6),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  // Register Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Color(0xFFC19AC7).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Get.to(() => Signup()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Create New Account',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC19AC7),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Luxurious Footer Text
                  Text(
                    'Every love story is beautiful,\nbut yours should be luxurious.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 16,
                      color: Color(0xFFC19AC7).withOpacity(1),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC19AC7),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFC19AC7).withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16,
              color: Color(0xFFC19AC7),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                color: Color(0xFFC19AC7).withOpacity(0.4),
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: Color(0xFFC19AC7).withOpacity(0.5),
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
