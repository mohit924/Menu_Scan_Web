import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/common_header.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';
import 'package:shimmer/shimmer.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> categories = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchCategoriesAndItems();
  }

  Future<void> fetchCategoriesAndItems() async {
    try {
      // Fetch categories for hotel OPSY
      final categorySnapshot = await _firestore
          .collection('AddCategory')
          .where('hotelID', isEqualTo: 'OPSY')
          .get();

      List<Map<String, dynamic>> tempCategories = [];

      for (var catDoc in categorySnapshot.docs) {
        final catData = catDoc.data();
        final catID = catData['categoryID'];

        // Fetch items for this category
        final itemSnapshot = await _firestore
            .collection('AddItem')
            .where('hotelID', isEqualTo: 'OPSY')
            .where('categoryID', isEqualTo: catID)
            .get();

        List<Map<String, dynamic>> items = itemSnapshot.docs.map((itemDoc) {
          final itemData = itemDoc.data();
          return {
            "docId": itemDoc.id,
            "itemID": itemData['itemID'],
            "name": itemData['itemName'] ?? '',
            "price": "₹${itemData['price'] ?? ''}",
            "desc": "₹${itemData['description'] ?? ''}",
            "available": itemData['available'] as bool? ?? true,

            "imageUrl": itemData['imageUrl'],
          };
        }).toList();

        tempCategories.add({
          "name": catData['categoryName'] ?? '',
          "icon": Icons.fastfood,
          "expanded": true,
          "items": items,
        });
      }

      setState(() {
        categories = tempCategories;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

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

  Future<void> toggleAvailability(String docId, bool newValue) async {
    try {
      await _firestore.collection('AddItem').doc(docId).update({
        'available': newValue,
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        children: [
          const SizedBox(height: 25),
          CommonHeader(
            currentPage: "Dashboard",
            showSearchBar: true,
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
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
                                          onToggle: (val) {
                                            setState(() {
                                              item["available"] = val;
                                            });
                                            toggleAvailability(
                                              item["docId"],
                                              val,
                                            );
                                          },
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
  final Function(bool) onToggle;

  const ItemCard({
    Key? key,
    required this.item,
    required this.isMobile,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  late Future<String?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImageUrl();
  }

  Future<String?> _loadImageUrl() async {
    final String? path = widget.item['imageUrl'];
    if (path == null || path.isEmpty) return null;

    try {
      final storage = FirebaseStorage.instanceFor(
        bucket: 'gs://menu-scan-web.firebasestorage.app',
      );

      final url = await storage.ref(path).getDownloadURL();

      debugPrint("✅ Image loaded: $url");
      return url;
    } catch (e) {
      debugPrint("❌ Image load failed ($path): $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE / ICON
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 100,
              height: 100,
              child: FutureBuilder<String?>(
                future: _imageFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade800,
                      highlightColor: Colors.grey.shade600,
                      child: Container(color: Colors.grey),
                    );
                  } else if (snapshot.hasError || snapshot.data == null) {
                    return const Center(
                      child: Icon(
                        Icons.fastfood,
                        size: 50,
                        color: AppColors.LightGreyColor,
                      ),
                    );
                  } else {
                    return Image.network(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade800,
                          highlightColor: Colors.grey.shade600,
                          child: Container(color: Colors.grey),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.fastfood,
                          size: 50,
                          color: AppColors.LightGreyColor,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // DETAILS + Switch
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["name"] ?? '',
                        style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["price"] ?? "0",
                        style: const TextStyle(
                          color: AppColors.OrangeColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["desc"] ?? "",
                        style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Switch
                Switch(
                  value: item["available"],
                  activeColor: AppColors.OrangeColor,
                  onChanged: widget.onToggle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
