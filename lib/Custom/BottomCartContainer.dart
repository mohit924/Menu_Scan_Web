import 'package:flutter/material.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

class BottomCartContainer extends StatelessWidget {
  final int totalCount;
  final VoidCallback onViewCart;

  const BottomCartContainer({
    Key? key,
    required this.totalCount,
    required this.onViewCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 0) return const SizedBox.shrink();

    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$totalCount item${totalCount > 1 ? 's' : ''} added",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.LightGreyColor,
            ),
          ),
          
          GestureDetector(
            onTap: onViewCart,
            child: Row(
              children: const [
                Icon(Icons.shopping_cart, color: AppColors.OrangeColor),
                SizedBox(width: 6),
                Text(
                  "View Cart",
                  style: TextStyle(color: AppColors.OrangeColor, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
