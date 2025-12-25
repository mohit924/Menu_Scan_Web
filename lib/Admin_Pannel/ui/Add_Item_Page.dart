import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/common_header.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({Key? key}) : super(key: key);

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // Veg / Non-Veg state
  bool _isVeg = false;
  bool _isNonVeg = false;

  String hotelID = "OPSY";

  int? selectedCategoryID;
  String? selectedCategoryName;

  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
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

  Future<void> addItem() async {
    debugPrint("===== ADD ITEM CLICKED =====");

    try {
      // 1️⃣ Validation
      debugPrint("1️⃣ VALIDATING INPUTS...");
      if (_nameController.text.isEmpty ||
          _priceController.text.isEmpty ||
          selectedCategoryID == null) {
        debugPrint("❌ VALIDATION FAILED: Missing fields");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fill all required fields")),
        );
        return;
      }

      if (_imageBytes == null) {
        debugPrint("❌ IMAGE IS NULL");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please select an image")));
        return;
      }

      debugPrint("✅ VALIDATION PASSED");

      // 2️⃣ Generate new item ID safely using Firestore transaction
      debugPrint("2️⃣ GENERATING NEW ITEM ID...");
      int newItemID = 1;
      await _firestore.runTransaction((transaction) async {
        final counterRef = _firestore
            .collection('ItemCounters')
            .doc("GLOBAL_ITEM_COUNTER");
        final snapshot = await transaction.get(counterRef);

        if (snapshot.exists) {
          debugPrint("Counter exists, lastItemID: ${snapshot['lastItemID']}");
          newItemID = (snapshot['lastItemID'] ?? 0) + 1;
          transaction.update(counterRef, {'lastItemID': newItemID});
          debugPrint("Counter updated to $newItemID");
        } else {
          debugPrint(
            "Counter does not exist, creating new counter with lastItemID = 1",
          );
          transaction.set(counterRef, {'lastItemID': 1});
          newItemID = 1;
        }
      });
      debugPrint("✅ NEW ITEM ID GENERATED: $newItemID");

      // 3️⃣ Upload image to Firebase Storage (Web)
      debugPrint("3️⃣ UPLOADING IMAGE TO FIREBASE STORAGE...");
      final storageRef = FirebaseStorage.instanceFor(
        bucket: 'gs://menu-scan-web.firebasestorage.app',
      ).ref().child('items/$newItemID.jpg');

      try {
        debugPrint("🔹 Creating UploadTask...");
        UploadTask uploadTask = storageRef.putData(
          _imageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        debugPrint("🔹 UploadTask created, waiting for completion...");
        TaskSnapshot snapshot = await uploadTask.whenComplete(
          () => debugPrint("🔹 UploadTask complete"),
        );

        debugPrint("🔹 Retrieving download URL...");
        final imageUrl = await snapshot.ref.getDownloadURL();
        debugPrint("✅ IMAGE UPLOADED SUCCESSFULLY: $imageUrl");

        // 4️⃣ Save item details to Firestore
        debugPrint("4️⃣ SAVING ITEM DATA TO FIRESTORE...");
        await _firestore.collection('AddItem').add({
          'itemID': newItemID,
          'itemName': _nameController.text.trim(),
          'price': _priceController.text.trim(),
          'description': _descriptionController.text.trim(),
          'type': _isVeg ? "Veg" : (_isNonVeg ? "Non-Veg" : "Unknown"),
          'categoryID': selectedCategoryID,
          'categoryName': selectedCategoryName,
          'hotelID': hotelID,
          'available': "Yes",
          'createdAt': Timestamp.now(),
          'imageUrl': imageUrl,
        });
        debugPrint("✅ ITEM DATA SAVED TO FIRESTORE");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item added successfully")),
        );
        Navigator.pop(context);
      } catch (uploadError, stackTrace) {
        debugPrint("❌ IMAGE UPLOAD FAILED: $uploadError");
        debugPrint("STACKTRACE: $stackTrace");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image upload failed: $uploadError")),
        );
      }
    } catch (e, s) {
      debugPrint("❌ ERROR OCCURRED: $e");
      debugPrint("STACKTRACE: $s");
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
          const CommonHeader(showSearchBar: false),
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
                    children: [
                      const Text(
                        "Add Item",
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// CATEGORY DROPDOWN
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

                      // Image Picker
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
                          child: _imageBytes == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Veg / Non-Veg checkboxes in a single row
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

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: addItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.OrangeColor,
                          ),
                          child: const Text(
                            "Add Item",
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontWeight: FontWeight.bold,
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
