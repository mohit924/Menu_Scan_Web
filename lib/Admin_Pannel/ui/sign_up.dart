import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/login.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';
import 'dart:math';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _hotelNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate random 4-letter ID
  String _generateRandomID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rand = Random();
    return List.generate(
      4,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  // Generate unique hotel ID
  Future<String> _generateUniqueHotelID() async {
    String newID = '';
    bool exists = true;

    while (exists) {
      newID = _generateRandomID();
      final query = await _firestore
          .collection('AdminSignUp')
          .where('hotelID', isEqualTo: newID)
          .get();
      exists = query.docs.isNotEmpty;
    }

    return newID;
  }

  void signUp() async {
    final hotelName = _hotelNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final createdAt = DateTime.now();

    if (hotelName.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      // Check if phone already exists
      final phoneQuery = await _firestore
          .collection('AdminSignUp')
          .where('phone', isEqualTo: phone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number already registered!")),
        );
        return;
      }

      // Generate unique hotel ID
      final hotelID = await _generateUniqueHotelID();

      // Add new admin
      await _firestore.collection('AdminSignUp').add({
        'hotelName': hotelName,
        'phone': phone,
        'password': password,
        'hotelID': hotelID,
        'date': createdAt,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sign up successful!")));

      // Clear fields
      _hotelNameController.clear();
      _phoneController.clear();
      _passwordController.clear();

      // Navigate to LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/pre_login_bg.png", fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: screenWidth > 600 ? 400 : screenWidth * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Admin Sign Up",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBackground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _hotelNameController,
                      decoration: InputDecoration(
                        labelText: "Hotel Name",
                        labelStyle: const TextStyle(
                          color: AppColors.LightGreyColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.OrangeColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        labelStyle: const TextStyle(
                          color: AppColors.LightGreyColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.OrangeColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(
                          color: AppColors.LightGreyColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.OrangeColor,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.LightGreyColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.OrangeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: signUp,
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(color: AppColors.OrangeColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
