import 'package:flutter/material.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';
import 'package:menu_scan_web/Custom/Custom_Button.dart';
import 'package:menu_scan_web/Menu/Widgets/Menu_Bottom_Sheet.dart';
import 'package:menu_scan_web/Menu/Widgets/Menu_Search_Bar.dart';
import 'package:menu_scan_web/Menu/Widgets/show_Category_Sheet.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Hardcoded categories and menu items
  final List<String> categories = ["Starters", "Main Course", "Desserts"];
  late List<Map<String, dynamic>> menuItems;

  List<Map<String, dynamic>> filteredItems = [];

  Map<int, Map<String, dynamic>> buttonStates = {};
  Map<String, bool> expandedCategories = {};
  Map<String, GlobalKey> categoryKeys = {};

  @override
  void initState() {
    super.initState();

    // Hardcoded menu items
    menuItems = List.generate(10, (index) {
      return {
        "id": index,
        "name": "Menu ${index + 1}",
        "price": "₹${(index + 1) * 50}",
        "image": "assets/noodles.png",
        "description":
            "This is the description for Menu ${index + 1}. Delicious and fresh!",
        "category": categories[index % categories.length],
      };
    });

    filteredItems = List.from(menuItems);

    for (var item in menuItems) {
      buttonStates[item["id"]] = {"isCompleted": false, "count": 0};
    }

    for (var cat in categories) {
      expandedCategories[cat] = true; // default expanded
      categoryKeys[cat] = GlobalKey(); // assign key
    }
  }

  void _filterMenu(String query) {
    setState(() {
      filteredItems = menuItems
          .where(
            (item) => item["name"].toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  void _showMenuBottomSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuBottomSheet(item: item),
    );
  }

  void _updateButtonState(int id, bool isCompleted, int count) {
    setState(() {
      buttonStates[id]!["isCompleted"] = isCompleted;
      buttonStates[id]!["count"] = count;
    });
  }

  void _scrollToCategory(String category) {
    // Expand the target category
    setState(() {
      expandedCategories.updateAll((key, value) => key == category);
    });

    // Wait for crossfade animation to complete
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
        // Retry if widget still not rendered
        Future.delayed(const Duration(milliseconds: 20), () {
          _scrollToCategory(category);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group menu items by category
    final Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in filteredItems) {
      final cat = item["category"];
      groupedItems.putIfAbsent(cat, () => []);
      groupedItems[cat]!.add(item);
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          "Menu",
          style: TextStyle(color: AppColors.whiteColor),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBackground,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.whiteColor),
            onPressed: () {
              CategoryBottomSheet.show(context, categories, _scrollToCategory);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          MenuSearchBar(controller: _searchController, onChanged: _filterMenu),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ListView(
                controller: _scrollController,
                children: groupedItems.entries.map((entry) {
                  final categoryName = entry.key;
                  final items = entry.value;
                  final isExpanded = expandedCategories[categoryName]!;

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
                              expandedCategories[categoryName] = !isExpanded;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: isExpanded ? 50 : 20,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            physics: const NeverScrollableScrollPhysics(),
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
                                onTap: () => _showMenuBottomSheet(item),
                                child: Card(
                                  color: AppColors.primaryBackground,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.asset(
                                              item["image"],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item["name"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.LightGreyColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item["price"],
                                              style: const TextStyle(
                                                color: AppColors.OrangeColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ToggleAddButton(
                                              isCompleted: state["isCompleted"],
                                              count: state["count"],
                                              onChanged:
                                                  (newCompleted, newCount) {
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
    );
  }
}
