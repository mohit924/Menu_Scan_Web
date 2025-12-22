import 'package:flutter/material.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Category_List_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Contact_Us_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Dashboard.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Item_List_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Update_Profile_Page.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

class CommonHeader extends StatefulWidget {
  final double height;
  final double horizontalPadding; // padding outside container
  final double maxWidth;
  final bool showSearchBar;
  final ValueChanged<String>? onSearchChanged;

  const CommonHeader({
    Key? key,
    this.height = 70,
    this.horizontalPadding = 16,
    this.maxWidth = 1200,
    this.showSearchBar = false,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  State<CommonHeader> createState() => _CommonHeaderState();
}

class _CommonHeaderState extends State<CommonHeader> {
  bool _isMobileSearchOpen = false;
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
              const Icon(Icons.menu, color: AppColors.OrangeColor, size: 28),
              const SizedBox(width: 12),

              // Mobile search open
              if (!isDesktop && _isMobileSearchOpen)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: _controller,
                        onChanged: widget.onSearchChanged,
                        style: const TextStyle(color: AppColors.whiteColor),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          hintText: "Search...",
                          hintStyle: const TextStyle(
                            color: AppColors.LightGreyColor,
                          ),
                          filled: true,
                          fillColor: AppColors.primaryBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.whiteColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isMobileSearchOpen = false;
                                _controller.clear();
                                if (widget.onSearchChanged != null) {
                                  widget.onSearchChanged!("");
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                if (isDesktop || !_isMobileSearchOpen) ...[
                  _headerButton(context, "Dashboard", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardPage(),
                      ),
                    );
                  }),
                  const SizedBox(width: 24),
                  _headerButton(context, "Category", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryListPage(),
                      ),
                    );
                  }),
                  const SizedBox(width: 24),
                  _headerButton(context, "Items", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ItemListPage(categoryIndex: 0),
                      ),
                    );
                  }),
                  // const SizedBox(width: 24),
                  // _headerButton(context, "Contact", () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(builder: (_) => const ContactUsPage()),
                  //   );
                  // }),
                ],

                const Spacer(),

                // Desktop search bar or mobile search icon
                if (widget.showSearchBar)
                  if (isDesktop)
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: AppColors.whiteColor),
                          onChanged: (val) {
                            setState(() {});
                            if (widget.onSearchChanged != null) {
                              widget.onSearchChanged!(val);
                            }
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            hintText: "Search...",
                            hintStyle: const TextStyle(
                              color: AppColors.LightGreyColor,
                            ),
                            filled: true,
                            fillColor: AppColors.primaryBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppColors.whiteColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _controller.clear();
                                        if (widget.onSearchChanged != null) {
                                          widget.onSearchChanged!("");
                                        }
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: AppColors.whiteColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isMobileSearchOpen = true;
                        });
                      },
                    ),

                const SizedBox(width: 16),

                // Profile icon always visible
                // Replace your existing CircleAvatar in CommonHeader with this:
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpdateProfilePage(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.OrangeColor,
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),

                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerButton(BuildContext context, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.whiteColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
