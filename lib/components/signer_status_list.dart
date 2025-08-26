import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignerStatusList extends StatelessWidget {
  final String documentId;

  const SignerStatusList({super.key, required this.documentId});

  Future<List<Map<String, dynamic>>> fetchSigners() async {
    final doc = await FirebaseFirestore.instance.collection('documents').doc(documentId).get();
    final data = doc.data();
    if (data == null || !data.containsKey('signers')) return [];
    return List<Map<String, dynamic>>.from(data['signers']);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchSigners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final signers = snapshot.data ?? [];

        return ListView.builder(
          shrinkWrap: true,
          itemCount: signers.length,
          itemBuilder: (context, index) {
            final signer = signers[index];
            final name = signer['name'] ?? 'ไม่ระบุชื่อ';
            final email = signer['email'] ?? '-';
            final status = signer['status'] ?? 'pending';

            return ListTile(
              leading: Icon(
                status == 'signed' ? Icons.check_circle : Icons.hourglass_empty,
                color: status == 'signed' ? Colors.green : Colors.orange,
              ),
              title: Text(name),
              subtitle: Text(email),
              trailing: Text(
                status == 'signed' ? '✅ เซ็นแล้ว' : '⏳ รอเซ็น',
                style: TextStyle(
                  color: status == 'signed' ? Colors.green : Colors.orange,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
