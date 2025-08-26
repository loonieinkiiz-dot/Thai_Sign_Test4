import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DocumentListPage extends StatelessWidget {
  const DocumentListPage({super.key});

  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('documents')
        .where('admin_uid', isEqualTo: 'demo_admin') // เปลี่ยนเป็น uid จริงในอนาคต
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📑 เอกสารทั้งหมด')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีเอกสาร'));
          }

          final docs = snapshot.data!;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final title = doc['title'] ?? 'ไม่มีชื่อ';
              final status = doc['status'] ?? 'unknown';
              final signerList = doc['signerList'] as List<dynamic>? ?? [];

              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('สถานะ: $status'),
                      const SizedBox(height: 4),
                      ...signerList.map((s) => Text(
                          '• ${s['phone']} - ${s['status']}',
                          style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                  onTap: () {
                    // TODO: ไปหน้า Document Detail
                    // Navigator.pushNamed(context, '/document_detail', arguments: doc);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
