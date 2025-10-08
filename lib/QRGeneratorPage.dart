import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class QRManagerPage extends StatefulWidget {
  @override
  _QRManagerPageState createState() => _QRManagerPageState();
}

class _QRManagerPageState extends State<QRManagerPage> {
  final CollectionReference qrCollection = FirebaseFirestore.instance
      .collection('qrcodes');

  int nextId = 1;

  @override
  void initState() {
    super.initState();
    _getNextId();
  }

  void _getNextId() async {
    final snapshot = await qrCollection
        .orderBy('id', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        nextId = (snapshot.docs.first['id'] as int) + 1;
      });
    }
  }

  void _generateQR() async {
    final url = "https://mohit924.github.io/Menu_Scan_Web/?id=$nextId";

    await qrCollection.add({
      'id': nextId,
      'url': url,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      nextId += 1;
    });
  }

  void _shareQR(String url) {
    Share.share(url); // shares the URL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Manager')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(onPressed: _generateQR, child: Text('Generate QR')),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: qrCollection.orderBy('id').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) return Text('No QR codes generated yet.');

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final url = doc['url'];
                      final id = doc['id'];

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: PrettyQr(
                            data: url,
                            size: 80,
                            elementColor: Colors.blue,
                            roundEdges: true,
                          ),
                          title: Text('ID: $id'),
                          subtitle: Text(url),
                          trailing: IconButton(
                            icon: Icon(Icons.share),
                            onPressed: () => _shareQR(url),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
