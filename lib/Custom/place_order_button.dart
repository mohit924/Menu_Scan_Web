import 'package:flutter/material.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

class PlaceOrderButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;

  const PlaceOrderButton({
    Key? key,
    required this.onPressed,
    this.title = "Place Order",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.OrangeColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // No border radius
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.whiteColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
