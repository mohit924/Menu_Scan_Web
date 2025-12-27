import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Add_Item_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Edit_Item_Page.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/login.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/common_header.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({Key? key}) : super(key: key);

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  String? hotelID;
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    _loadHotelID();
  }

  Future<void> _loadHotelID() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHotelID = prefs.getString('hotelID');

    if (savedHotelID == null || savedHotelID.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    setState(() {
      hotelID = savedHotelID;
    });
  }

  Stream<QuerySnapshot> _itemsStream() {
    return FirebaseFirestore.instance
        .collection('AddItem')
        .where('hotelID', isEqualTo: hotelID)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int cardsPerRow;
    if (screenWidth >= 1200) {
      cardsPerRow = 4;
    } else if (screenWidth >= 900) {
      cardsPerRow = 3;
    } else if (screenWidth >= 600) {
      cardsPerRow = 2;
    } else {
      cardsPerRow = 1;
    }

    final cardWidth = (screenWidth - (16 * (cardsPerRow + 1))) / cardsPerRow;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        children: [
          const SizedBox(height: 25),
          CommonHeader(
            currentPage: "Items",
            showSearchBar: true,
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _itemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No items found",
                      style: TextStyle(color: AppColors.whiteColor),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final name = doc['itemName'].toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

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
                                  data['itemName'],
                                  style: const TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                                        builder: (_) => EditItemPage(
                                          itemDocId: doc.id,
                                          itemName: data['itemName'],
                                          price: data['price'],
                                          description: data['description'],
                                          categoryID: data['categoryID'],
                                          categoryName: data['categoryName'],
                                          type: data['type'],
                                          image: data['imageUrl'],
                                        ),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    final imagePath =
                                        data['imageUrl']; // e.g., 'items/1.jpg'

                                    // Delete Firestore doc first
                                    await FirebaseFirestore.instance
                                        .collection('AddItem')
                                        .doc(doc.id)
                                        .delete();

                                    // Delete image from Firebase Storage
                                    if (imagePath != null &&
                                        imagePath.isNotEmpty) {
                                      try {
                                        final storageRef =
                                            FirebaseStorage.instanceFor(
                                              bucket:
                                                  'gs://menu-scan-web.firebasestorage.app',
                                            ).ref(imagePath);
                                        await storageRef.delete();
                                        debugPrint(
                                          "✅ Deleted image: $imagePath",
                                        );
                                      } catch (e) {
                                        debugPrint(
                                          "❌ Failed to delete image: $e",
                                        );
                                      }
                                    }
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
          "Add Item",
          style: TextStyle(color: AppColors.whiteColor),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemPage()),
          );
        },
      ),
    );
  }
}
