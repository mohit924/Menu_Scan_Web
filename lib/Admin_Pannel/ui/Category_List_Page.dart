import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Add_Category_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Edit_Category_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Item_List_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/common_header.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

// Dummy data
List<Map<String, dynamic>> categories = [
  {
    "name": "Starters",
    "icon": Icons.fastfood,
    "items": [
      {"name": "Spring Rolls", "price": "₹100", "show": true},
      {"name": "Fried Momos", "price": "₹120", "show": true},
    ],
  },
  {"name": "Main Course", "icon": Icons.restaurant, "items": []},
  {"name": "Desserts", "icon": Icons.cake, "items": []},
  {"name": "Beverages", "icon": Icons.local_cafe, "items": []},
];

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({Key? key}) : super(key: key);

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String hotelID = "OPSY";

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int cardsPerRow = screenWidth >= 1200
        ? 4
        : screenWidth >= 900
        ? 3
        : screenWidth >= 600
        ? 2
        : 1;

    final cardWidth = (screenWidth - (16 * (cardsPerRow + 1))) / cardsPerRow;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        children: [
          const SizedBox(height: 25),
          CommonHeader(
            showSearchBar: true,
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('AddCategory')
                  .where('hotelID', isEqualTo: hotelID)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No categories found for this hotel",
                      style: TextStyle(color: AppColors.whiteColor),
                    ),
                  );
                }

                final categories = snapshot.data!.docs.where((cat) {
                  return cat['categoryName'].toString().toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: categories.map((catDoc) {
                      final categoryName = catDoc['categoryName'];
                      return Container(
                        width: cardWidth,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppColors.OrangeColor.withOpacity(0.2),
                              child: const Icon(
                                Icons.fastfood,
                                color: AppColors.OrangeColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                categoryName,
                                style: const TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            PopupMenuButton(
                              icon: const Icon(
                                Icons.more_horiz,
                                color: AppColors.OrangeColor,
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.edit,
                                        color: AppColors.OrangeColor,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditCategoryPage(
                                        categoryId: catDoc.id,
                                        hotelID: hotelID,
                                        initialName: catDoc['categoryName'],
                                      ),
                                    ),
                                  ).then((_) => setState(() {}));
                                }
                                if (value == 'delete') {
                                  await _firestore
                                      .collection('AddCategory')
                                      .doc(catDoc.id)
                                      .delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Category deleted"),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.OrangeColor,
        icon: const Icon(Icons.add, color: AppColors.whiteColor),
        label: const Text(
          "Add Category",
          style: TextStyle(color: AppColors.whiteColor),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCategoryPage()),
          );
        },
      ),
    );
  }
}
