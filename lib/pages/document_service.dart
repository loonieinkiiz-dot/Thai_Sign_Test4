import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> fetchSignerStatus(String documentId) async {
  final doc = await FirebaseFirestore.instance
      .collection('documents')
      .doc(documentId)
      .get();

  final data = doc.data();
  if (data == null || !data.containsKey('signers')) return [];

  final signers = List<Map<String, dynamic>>.from(data['signers']);

  return signers.asMap().entries.map((entry) {
    final index = entry.key + 1;
    final signer = entry.value;
    return {
      'order': index,
      'name': signer['name'],
      'email': signer['email'],
      'status': signer['status'] ?? 'pending',
      'signedAt': signer['signedAt'],
    };
  }).toList();
}
