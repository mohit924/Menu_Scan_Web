import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Add_Category_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Edit_Category_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Item_List_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/common_header.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

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
            currentPage: "Category",
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
                  child: Align(
                    alignment: Alignment
                        .topLeft, // ensures top-left alignment for single items
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
                                    final categoryId = catDoc.id;

                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Delete Category"),
                                        content: const Text(
                                          "Are you sure you want to delete this category and all its items?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);

                                              try {
                                                final itemsSnapshot =
                                                    await _firestore
                                                        .collection('AddItem')
                                                        .where(
                                                          'categoryID',
                                                          isEqualTo:
                                                              catDoc['categoryID'],
                                                        )
                                                        .get();

                                                for (var itemDoc
                                                    in itemsSnapshot.docs) {
                                                  final imagePath =
                                                      itemDoc['imageUrl'];

                                                  await itemDoc.reference
                                                      .delete();

                                                  if (imagePath != null &&
                                                      imagePath.isNotEmpty) {
                                                    try {
                                                      final storageRef =
                                                          FirebaseStorage.instanceFor(
                                                            bucket:
                                                                'gs://menu-scan-web.firebasestorage.app',
                                                          ).ref(imagePath);
                                                      await storageRef.delete();
                                                    } catch (_) {}
                                                  }
                                                }

                                                await _firestore
                                                    .collection('AddCategory')
                                                    .doc(categoryId)
                                                    .delete();

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Category and all items deleted",
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Error deleting category: $e",
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
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
