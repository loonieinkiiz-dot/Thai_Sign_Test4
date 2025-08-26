import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sign_document_page.dart';

class MyDocumentsPage extends StatefulWidget {
  final String phoneNumber;

  const MyDocumentsPage({super.key, required this.phoneNumber});

  @override
  State<MyDocumentsPage> createState() => _MyDocumentsPageState();
}

class _MyDocumentsPageState extends State<MyDocumentsPage> {
  List<Map<String, dynamic>> allDocs = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortBy = 'date'; // หรือ 'title'

  @override
  void initState() {
    super.initState();
    fetchMyDocuments();
  }

  Future<void> fetchMyDocuments() async {
    final snapshot = await FirebaseFirestore.instance.collection('documents').get();
    final docs = snapshot.docs;

    final myDocs = docs.where((doc) {
      final signers = List<Map<String, dynamic>>.from(doc['signers']);
      return signers.any((s) => s['phone'] == widget.phoneNumber);
    }).map((doc) {
      return {
        'id': doc.id,
        'title': doc['title'],
        'fileUrl': doc['fileUrl'],
        'signers': doc['signers'],
        'createdAt': doc['createdAt'], // ISO string
      };
    }).toList();

    setState(() {
      allDocs = myDocs;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> filterDocs(String status) {
    List<Map<String, dynamic>> filtered = allDocs.where((doc) {
      final signer = List<Map<String, dynamic>>.from(doc['signers']).firstWhere(
        (s) => s['phone'] == widget.phoneNumber,
        orElse: () => {},
      );
      final matchesStatus = status == 'all' || signer['status'] == status;
      final matchesSearch = doc['title']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    if (sortBy == 'title') {
      filtered.sort((a, b) => a['title'].toString().compareTo(b['title'].toString()));
    } else {
      filtered.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    }

    return filtered;
  }

  Widget buildTab(String label, String status) {
    final docs = filterDocs(status);
    if (docs.isEmpty) return const Center(child: Text('ไม่มีเอกสาร'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('ทั้งหมด ${docs.length} รายการ', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final date = DateTime.tryParse(doc['createdAt'] ?? '');
              final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : '';

              return ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text(doc['title'] ?? 'ไม่มีชื่อ'),
                subtitle: Text(dateStr),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignDocumentPage(
                        documentId: doc['id'],
                        phoneNumber: widget.phoneNumber,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📑 เอกสารของฉัน'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) => setState(() => sortBy = value),
              icon: const Icon(Icons.sort),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'date', child: Text('เรียงตามวันที่')),
                PopupMenuItem(value: 'title', child: Text('เรียงตามชื่อ')),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ทั้งหมด'),
              Tab(text: 'ยังไม่เซ็น'),
              Tab(text: 'เซ็นแล้ว'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '🔍 ค้นหาชื่อเอกสาร...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            const Divider(height: 0),
            Expanded(
              child: TabBarView(
                children: [
                  buildTab('ทั้งหมด', 'all'),
                  buildTab('ยังไม่เซ็น', 'pending'),
                  buildTab('เซ็นแล้ว', 'signed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
