import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/common_header.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

class EditItemPage extends StatefulWidget {
  final String itemDocId;
  final String itemName;
  final String price;
  final String description;
  final int categoryID;
  final String categoryName;
  final String type; // "Veg" or "Non-Veg"
  final String image;

  const EditItemPage({
    Key? key,
    required this.itemDocId,
    required this.itemName,
    required this.price,
    required this.description,
    required this.categoryID,
    required this.categoryName,
    required this.type,
    required this.image,
  }) : super(key: key);

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late Future<String?> _imageFuture;

  int? selectedCategoryID;
  String? selectedCategoryName;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  bool _isVeg = false;
  bool _isNonVeg = false;

  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemName);
    _priceController = TextEditingController(text: widget.price);
    _descriptionController = TextEditingController(text: widget.description);

    selectedCategoryID = widget.categoryID;
    selectedCategoryName = widget.categoryName;

    _isVeg = widget.type == "Veg";
    _isNonVeg = widget.type == "Non-Veg";

    _imageFuture = _loadImageUrl(widget.image);
    fetchCategories();
  }

  Future<String?> _loadImageUrl(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;
    try {
      final url = await FirebaseStorage.instanceFor(
        bucket: 'gs://menu-scan-web.firebasestorage.app',
      ).ref(fileName).getDownloadURL();
      return url;
    } catch (e) {
      debugPrint("Failed to load image: $e");
      return null;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> fetchCategories() async {
    final snapshot = await _firestore
        .collection('AddCategory')
        .orderBy('categoryID')
        .get();
    setState(() {
      categories = snapshot.docs.map((doc) {
        return {
          'categoryID': doc['categoryID'],
          'categoryName': doc['categoryName'],
        };
      }).toList();
    });
  }

  Future<void> updateItem() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        selectedCategoryID == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
      return;
    }

    try {
      String? imagePath = widget.image;

      // Upload new image if picked
      if (_imageBytes != null) {
        final ref = FirebaseStorage.instanceFor(
          bucket: 'gs://menu-scan-web.firebasestorage.app',
        ).ref('items/${widget.itemDocId}.png');

        await ref.putData(_imageBytes!);
        imagePath = ref.fullPath;
      }

      await _firestore.collection('AddItem').doc(widget.itemDocId).update({
        'itemName': _nameController.text.trim(),
        'price': _priceController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryID': selectedCategoryID,
        'categoryName': selectedCategoryName,
        'type': _isVeg ? "Veg" : (_isNonVeg ? "Non-Veg" : "Unknown"),
        'available': true,
        'imageUrl': imagePath,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        children: [
          const SizedBox(height: 25),
          const CommonHeader(showSearchBar: false, currentPage: "Items"),
          const SizedBox(height: 25),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: screenWidth > 600 ? 500 : screenWidth * 0.9,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Edit Item",
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CATEGORY DROPDOWN
                      DropdownButtonFormField<int>(
                        dropdownColor: AppColors.secondaryBackground,
                        value: selectedCategoryID,
                        decoration: _inputDecoration("Select Category"),
                        items: categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat['categoryID'],
                            child: Text(
                              cat['categoryName'],
                              style: const TextStyle(
                                color: AppColors.whiteColor,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final selected = categories.firstWhere(
                            (c) => c['categoryID'] == val,
                          );
                          setState(() {
                            selectedCategoryID = val;
                            selectedCategoryName = selected['categoryName'];
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _inputField(_nameController, "Item Name"),
                      const SizedBox(height: 16),
                      _inputField(
                        _priceController,
                        "Price",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        _descriptionController,
                        "Description",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // IMAGE PICKER + DISPLAY
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.LightGreyColor),
                            color: Colors.black12,
                          ),
                          child: _imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 160,
                                  ),
                                )
                              : FutureBuilder<String?>(
                                  future: _imageFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Container(
                                        color: Colors.grey.shade800,
                                      );
                                    } else if (snapshot.hasError ||
                                        snapshot.data == null) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 40,
                                            color: AppColors.LightGreyColor,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Upload Item Image",
                                            style: TextStyle(
                                              color: AppColors.LightGreyColor,
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 160,
                                        ),
                                      );
                                    }
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Veg / Non-Veg
                      Row(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _isVeg,
                                onChanged: (v) {
                                  setState(() {
                                    _isVeg = v!;
                                    _isNonVeg = false;
                                  });
                                },
                                activeColor: AppColors.OrangeColor,
                                checkColor: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "Veg",
                                style: TextStyle(color: AppColors.whiteColor),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _isNonVeg,
                                onChanged: (v) {
                                  setState(() {
                                    _isNonVeg = v!;
                                    _isVeg = false;
                                  });
                                },
                                activeColor: AppColors.OrangeColor,
                                checkColor: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "Non-Veg",
                                style: TextStyle(color: AppColors.whiteColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.OrangeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: updateItem,
                          child: const Text(
                            "Update Item",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.whiteColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.OrangeColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.OrangeColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.LightGreyColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.OrangeColor),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.whiteColor),
      decoration: _inputDecoration(label),
    );
  }
}
