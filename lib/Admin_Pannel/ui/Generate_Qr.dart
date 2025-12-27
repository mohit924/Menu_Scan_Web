import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/common_header.dart';
import 'package:menu_scan_web/Custom/App_colors.dart';

class GenerateQr extends StatefulWidget {
  const GenerateQr({super.key});

  @override
  _GenerateQrState createState() => _GenerateQrState();
}

class _GenerateQrState extends State<GenerateQr> {
  final String hotelID = "OPSY";
  final CollectionReference qrCollection = FirebaseFirestore.instance
      .collection('qrcodes');

  Future<void> _generateQR() async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final counterDoc = FirebaseFirestore.instance
            .collection('QRCounters')
            .doc(hotelID);

        final counterSnapshot = await transaction.get(counterDoc);
        int nextId = 1;

        if (counterSnapshot.exists) {
          final lastId = counterSnapshot['lastID'] ?? 0;
          nextId = lastId + 1;
          transaction.update(counterDoc, {'lastID': nextId});
        } else {
          transaction.set(counterDoc, {'lastID': nextId});
        }

        final tableId = nextId;
        final url =
            "https://mohit924.github.io/Menu_Scan_Web/?hotelID=$hotelID&tableID=$tableId";

        final newDoc = qrCollection.doc();
        transaction.set(newDoc, {
          'hotelID': hotelID,
          'id': nextId,
          'tableID': tableId,
          'url': url,
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint("Generated QR URL: $url");
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR generated! Check console for link.")),
      );
    } catch (e) {
      debugPrint("Error generating QR: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error generating QR: $e")));
    }
  }

  void _shareQR(String url) {
    Share.share(url);
  }

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
          const CommonHeader(currentPage: "QR Codes", showSearchBar: false),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: qrCollection
                  .where('hotelID', isEqualTo: hotelID)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading QR codes: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.whiteColor),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No QR codes generated yet.',
                      style: TextStyle(color: AppColors.whiteColor),
                    ),
                  );
                }

                docs.sort((a, b) {
                  final tableA = a['tableID'] ?? 0;
                  final tableB = b['tableID'] ?? 0;
                  return tableA.compareTo(tableB);
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: docs.map((doc) {
                        final url = doc['url'] ?? '';
                        final tableId = doc['tableID'] ?? 0;

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
                              PrettyQr(
                                data: url,
                                size: 80,
                                elementColor: AppColors.whiteColor,
                                roundEdges: true,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'Table ID: ',
                                            style: TextStyle(
                                              color: AppColors.whiteColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '$tableId',
                                            style: const TextStyle(
                                              color: AppColors.OrangeColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(text: url),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'URL copied to clipboard!',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        url,
                                        style: const TextStyle(
                                          color: AppColors.whiteColor,
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: AppColors.OrangeColor,
                                ),
                                onPressed: () => _shareQR(url),
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
        onPressed: _generateQR,
        backgroundColor: AppColors.OrangeColor,
        icon: const Icon(Icons.qr_code, color: AppColors.whiteColor),
        label: const Text(
          'Generate QR',
          style: TextStyle(color: AppColors.whiteColor),
        ),
      ),
    );
  }
}
