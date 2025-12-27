import 'package:flutter/material.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Category_List_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Contact_Us_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Dashboard.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Generate_Qr.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Item_List_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Update_Profile_Page.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

class CommonHeader extends StatefulWidget {
  final double height;
  final double horizontalPadding;
  final double maxWidth;
  final bool showSearchBar;
  final ValueChanged<String>? onSearchChanged;
  final String currentPage; // NEW: current active page

  const CommonHeader({
    Key? key,
    this.height = 70,
    this.horizontalPadding = 16,
    this.maxWidth = 1200,
    this.showSearchBar = false,
    this.onSearchChanged,
    required this.currentPage, // require current page
  }) : super(key: key);

  @override
  State<CommonHeader> createState() => _CommonHeaderState();
}

class _CommonHeaderState extends State<CommonHeader> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              if (!isDesktop) MobileMenuButton(currentPage: widget.currentPage),
              const SizedBox(width: 12),
              if (isDesktop) HeaderMenuButtons(currentPage: widget.currentPage),
              if (isDesktop) const Spacer(),
              Expanded(
                child: Padding(
                  padding: isDesktop
                      ? const EdgeInsets.symmetric(horizontal: 12)
                      : EdgeInsets.zero,
                  child: SearchField(
                    controller: _controller,
                    onChanged: widget.onSearchChanged,
                    onClose: () {
                      _controller.clear();
                      widget.onSearchChanged?.call("");
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const ProfileAvatar(),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- Desktop Menu -------------------
class HeaderMenuButtons extends StatelessWidget {
  final String currentPage;
  const HeaderMenuButtons({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _headerButton(context, "Dashboard", const AdminDashboardPage()),
        const SizedBox(width: 24),
        _headerButton(context, "Category", const CategoryListPage()),
        const SizedBox(width: 24),
        _headerButton(context, "Items", const ItemListPage()),
        const SizedBox(width: 24),
        _headerButton(context, "Generate Qr", const GenerateQr()),
        const SizedBox(width: 24),
        _headerButton(context, "Contact Us", const ContactUsPage()),
        const SizedBox(width: 24),
        _headerButton(context, "Help", const ContactUsPage()),
      ],
    );
  }

  Widget _headerButton(BuildContext context, String text, Widget page) {
    final isActive = text == currentPage;
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? AppColors.OrangeColor : AppColors.whiteColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ------------------- Mobile Bottom Sheet -------------------
class MobileMenuButton extends StatelessWidget {
  final String currentPage;
  const MobileMenuButton({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu, color: AppColors.OrangeColor, size: 28),
      onPressed: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.secondaryBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bottomSheetItem(context, "Dashboard", const AdminDashboardPage()),
            _bottomSheetItem(context, "Category", const CategoryListPage()),
            _bottomSheetItem(context, "Items", const ItemListPage()),
            _bottomSheetItem(context, "Generate Qr", const GenerateQr()),
            _bottomSheetItem(context, "Contact", const ContactUsPage()),
            _bottomSheetItem(context, "Help", const ContactUsPage()),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _bottomSheetItem(BuildContext context, String title, Widget page) {
    final isActive = title == currentPage;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.OrangeColor : AppColors.whiteColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback onClose;

  const SearchField({
    super.key,
    required this.controller,
    this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.whiteColor),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          hintText: "Search...",
          hintStyle: const TextStyle(color: AppColors.LightGreyColor),
          filled: true,
          fillColor: AppColors.primaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.whiteColor),
                  onPressed: onClose,
                )
              : null,
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpdateProfilePage()),
        );
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.OrangeColor,
        child: const Icon(Icons.person, size: 20, color: AppColors.whiteColor),
      ),
    );
  }
}
