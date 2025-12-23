import 'package:flutter/material.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Category_List_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/common_header.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final List<Map<String, dynamic>> categories = [
    {
      "name": "Starters",
      "icon": Icons.fastfood,
      "expanded": true,
      "items": [
        {
          "name": "Spring Rolls Rolls Rolls Rolls Rolls Rolls",
          "price": "₹100",
          "show": true,
        },
        {"name": "Fried Momos", "price": "₹120", "show": true},
        {"name": "Paneer Pakora", "price": "₹150", "show": true},
        {"name": "Veg Cutlet", "price": "₹80", "show": true},
      ],
    },
    {
      "name": "Main Course",
      "icon": Icons.restaurant,
      "expanded": true,
      "items": [
        {"name": "Paneer Butter Masala", "price": "₹250", "show": true},
        {"name": "Veg Biryani", "price": "₹200", "show": true},
        {"name": "Dal Makhani", "price": "₹180", "show": true},
        {"name": "Mixed Veg", "price": "₹220", "show": true},
      ],
    },
  ];

  String _searchQuery = '';

  List<Map<String, dynamic>> get filteredCategories {
    if (_searchQuery.isEmpty) return categories;

    return categories
        .map((category) {
          final filteredItems = (category["items"] as List)
              .where(
                (item) => item["name"].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

          return {...category, "items": filteredItems};
        })
        .where((cat) => (cat["items"] as List).isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        children: [
          // Fixed header at top
          const SizedBox(height: 25),

          CommonHeader(
            showSearchBar: true,
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: filteredCategories.map((category) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              category["expanded"] =
                                  !(category["expanded"] as bool);
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    category["icon"],
                                    color: AppColors.OrangeColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category["name"],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.LightGreyColor,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                category["expanded"]
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.OrangeColor,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (category["expanded"] as bool)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cardCount = isMobile
                                  ? 1
                                  : (constraints.maxWidth ~/ 320);
                              final spacing = 16.0;
                              final cardWidth = isMobile
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth -
                                            (cardCount - 1) * spacing) /
                                        cardCount;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: (category["items"] as List)
                                    .map<Widget>(
                                      (item) => SizedBox(
                                        width: cardWidth,
                                        child: ItemCard(
                                          item: item,
                                          isMobile: true,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isMobile;
  const ItemCard({Key? key, required this.item, required this.isMobile})
    : super(key: key);

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              "assets/noodles.png",
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),

          // Text + Switch
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item["name"],
                        style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item["price"],
                        style: const TextStyle(
                          color: AppColors.OrangeColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Switch
                Switch(
                  value: widget.item["show"],
                  activeColor: AppColors.OrangeColor,
                  onChanged: (val) {
                    setState(() {
                      widget.item["show"] = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
