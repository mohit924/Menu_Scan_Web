import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

class MenuBottomSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(int count) onAdd;
  final String? imageUrl;

  const MenuBottomSheet({
    Key? key,
    required this.item,
    required this.onAdd,
    this.imageUrl,
  }) : super(key: key);

  @override
  State<MenuBottomSheet> createState() => _MenuBottomSheetState();
}

class _MenuBottomSheetState extends State<MenuBottomSheet> {
  int count = 1;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    Future<String?> _getImageUrl(String path) async {
      if (path.isEmpty) return null;
      try {
        final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://menu-scan-web.firebasestorage.app',
        );
        return await storage.ref(path).getDownloadURL();
      } catch (e) {
        debugPrint("Image load failed: $e");
        return null;
      }
    }

    return Container(
      height: height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: widget.imageUrl != null
                        ? Image.network(
                            widget.imageUrl!,
                            fit: BoxFit.contain,
                            height: height * 0.3,
                            width: double.infinity,
                          )
                        : Container(
                            height: height * 0.3,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 50),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    widget.item["name"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.LightGreyColor,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    widget.item["description"],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.LightGreyColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed bottom bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity Controller (- 1 +)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          color: AppColors.whiteColor,
                        ),
                        onPressed: () {
                          if (count > 1) {
                            setState(() {
                              count--;
                            });
                          }
                        },
                      ),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: AppColors.whiteColor,
                        ),
                        onPressed: () {
                          setState(() {
                            count++;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Add Item Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.onAdd(count);
                      Navigator.pop(context);
                    },

                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.OrangeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Add Item ${widget.item["price"]}',
                        style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
