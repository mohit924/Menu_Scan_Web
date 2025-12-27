import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';
import 'package:menu_scan_web/Custom/BottomCartContainer.dart';
import 'package:menu_scan_web/Custom/Custom_Button.dart';
import 'package:menu_scan_web/Customer/Screen_Ui/cart_page.dart';
import 'package:menu_scan_web/Customer/Widgets/Menu_Bottom_Sheet.dart';
import 'package:menu_scan_web/Customer/Widgets/Menu_Search_Bar.dart';
import 'package:menu_scan_web/Customer/Widgets/show_Category_Sheet.dart';

class MenuScreen extends StatefulWidget {
  final String hotelID;
  final String tableID;

  const MenuScreen({Key? key, required this.hotelID, required this.tableID})
    : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool get isSearching => _searchController.text.isNotEmpty;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> categories = [];
  Map<int, Map<String, dynamic>> buttonStates = {};
  Map<String, bool> expandedCategories = {};
  Map<String, GlobalKey> categoryKeys = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchCategoriesAndItems();
  }

  Future<void> fetchCategoriesAndItems() async {
    try {
      final categorySnapshot = await _firestore
          .collection('AddCategory')
          .where('hotelID', isEqualTo: widget.hotelID)
          .get();

      List<Map<String, dynamic>> tempCategories = [];

      for (var catDoc in categorySnapshot.docs) {
        final catData = catDoc.data();
        final catID = catData['categoryID'];

        final itemSnapshot = await _firestore
            .collection('AddItem')
            .where('hotelID', isEqualTo: widget.hotelID)
            .where('categoryID', isEqualTo: catID)
            .get();

        List<Map<String, dynamic>> items = itemSnapshot.docs.map((itemDoc) {
          final itemData = itemDoc.data();
          final id = itemData['itemID'] as int;

          // Initialize button state
          buttonStates[id] = {"isCompleted": false, "count": 0};

          return {
            "id": id,
            "name": itemData['itemName'] ?? '',
            "price": "₹${itemData['price'] ?? ''}",
            "description": itemData['description'] ?? '',
            "image": itemData['imageUrl'] ?? '',
            "category": catData['categoryName'] ?? '',
          };
        }).toList();

        tempCategories.add({
          "name": catData['categoryName'] ?? '',
          "expanded": true,
          "items": items,
        });
      }

      setState(() {
        categories = tempCategories;

        // Setup expanded states and keys
        for (var cat in categories) {
          final name = cat['name'];
          expandedCategories[name] = true;
          categoryKeys[name] = GlobalKey();
        }
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

  void _filterMenu(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showMenuBottomSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuBottomSheet(
        item: item,
        onAdd: (count) {
          final id = item["id"];
          setState(() {
            buttonStates[id]!["isCompleted"] = true;
            buttonStates[id]!["count"] = count;
          });
        },
      ),
    );
  }

  void _updateButtonState(int id, bool isCompleted, int count) {
    setState(() {
      buttonStates[id]!["isCompleted"] = isCompleted;
      buttonStates[id]!["count"] = count;
    });
  }

  void _scrollToCategory(String category) {
    setState(() {
      expandedCategories.updateAll((key, value) => key == category);
    });

    Future.delayed(const Duration(milliseconds: 310), () {
      final key = categoryKeys[category];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      } else {
        Future.delayed(const Duration(milliseconds: 20), () {
          _scrollToCategory(category);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalCount = buttonStates.values.fold(
      0,
      (sum, state) => sum + (state["count"] as int),
    );

    final groupedItems = <String, List<Map<String, dynamic>>>{};
    for (var cat in filteredCategories) {
      final catName = cat["name"];
      groupedItems[catName] = List<Map<String, dynamic>>.from(cat["items"]);
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          "Menu",
          style: TextStyle(color: AppColors.whiteColor, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBackground,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.whiteColor),
            onPressed: () {
              CategoryBottomSheet.show(
                context,
                groupedItems.keys.toList(),
                _scrollToCategory,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              MenuSearchBar(
                controller: _searchController,
                onChanged: _filterMenu,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: groupedItems.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.only(
                            bottom: totalCount > 0 ? 100 : 0,
                          ),
                          children: groupedItems.entries.map((entry) {
                            final categoryName = entry.key;
                            final items = entry.value;
                            final isExpanded =
                                expandedCategories[categoryName]!;

                            return Container(
                              key: categoryKeys[categoryName],
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        expandedCategories[categoryName] =
                                            !isExpanded;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      height: isExpanded ? 50 : 20,
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            categoryName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.LightGreyColor,
                                            ),
                                          ),
                                          Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: AppColors.OrangeColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: items.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 0.7,
                                          ),
                                      itemBuilder: (context, index) {
                                        final item = items[index];
                                        final id = item["id"];
                                        final state = buttonStates[id]!;

                                        return GestureDetector(
                                          onTap: () =>
                                              _showMenuBottomSheet(item),
                                          child: Card(
                                            color: AppColors.primaryBackground,
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: item["image"] == ''
                                                        ? Container(
                                                            color: Colors
                                                                .grey[300],
                                                            child: const Icon(
                                                              Icons.image,
                                                            ),
                                                          )
                                                        : Image.network(
                                                            item["image"],
                                                            fit: BoxFit.cover,
                                                            width:
                                                                double.infinity,
                                                          ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    item["name"],
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .LightGreyColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        item["price"],
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .OrangeColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      ToggleAddButton(
                                                        isCompleted:
                                                            state["isCompleted"],
                                                        count: state["count"],
                                                        onChanged:
                                                            (
                                                              newCompleted,
                                                              newCount,
                                                            ) {
                                                              _updateButtonState(
                                                                id,
                                                                newCompleted,
                                                                newCount,
                                                              );
                                                            },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    crossFadeState: isExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 300),
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
          if (totalCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomCartContainer(
                totalCount: totalCount,
                onViewCart: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
