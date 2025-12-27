import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Dashboard.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/login.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/common_header.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({Key? key}) : super(key: key);

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final TextEditingController _hotelNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String hotelID = "OPSY"; // static hotel ID
  String? docId; // Firestore document ID
  bool _obscurePassword = true; // toggle for password visibility

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final snapshot = await _firestore
        .collection('AdminSignUp')
        .where('hotelID', isEqualTo: hotelID)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      docId = doc.id;

      _hotelNameController.text = doc['hotelName'];
      _mobileController.text = doc['phone'];
      _passwordController.text = doc['password'];
      setState(() {});
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile not found!")));
    }
  }

  Future<void> _updateProfile() async {
    if (_hotelNameController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (docId == null) return;

    try {
      await _firestore.collection('AdminSignUp').doc(docId).update({
        'hotelName': _hotelNameController.text.trim(),
        'phone': _mobileController.text.trim(),
        'password': _passwordController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      // Navigate to AdminDashboard after success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
    }
  }

  Future<void> _logout() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        children: [
          const SizedBox(height: 25),
          const CommonHeader(showSearchBar: false, currentPage: ""),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: screenWidth > 600 ? 500 : screenWidth * 0.9,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Update Profile",
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _inputField(_hotelNameController, "Hotel Name"),
                      const SizedBox(height: 16),
                      _inputField(
                        _mobileController,
                        "Mobile Number",
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _passwordField(_passwordController, "Password"),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.OrangeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _updateProfile,
                          child: const Text(
                            "Update Profile",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.OrangeColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _logout,
                          child: const Text(
                            "Logout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.OrangeColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.whiteColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.LightGreyColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.OrangeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.LightGreyColor),
        ),
      ),
    );
  }

  Widget _passwordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      style: const TextStyle(color: AppColors.whiteColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.LightGreyColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.OrangeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.LightGreyColor),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: AppColors.LightGreyColor,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }
}
