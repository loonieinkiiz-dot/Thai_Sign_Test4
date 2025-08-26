import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_image/network.dart';
import '../components/signature_page.dart';
import '../pages/OTPInputPage.dart'; 
import '../utils/email_service.dart';
import '../components/signer_status_list.dart';

class SignDocumentPage extends StatefulWidget {
  final String documentId;
  final String phoneNumber;

  const SignDocumentPage({
    super.key,
    required this.documentId,
    required this.phoneNumber,
  });

  @override
  State<SignDocumentPage> createState() => _SignDocumentPageState();
}

class _SignDocumentPageState extends State<SignDocumentPage> {
  Map<String, dynamic>? documentData;
  bool hasSigned = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDocument();
  }

  Future<void> fetchDocument() async {
    final docRef = FirebaseFirestore.instance.collection('documents').doc(widget.documentId);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      final signers = List<Map<String, dynamic>>.from(data['signers']);
      final thisSigner = signers.firstWhere(
        (s) => s['phone'] == widget.phoneNumber,
        orElse: () => {},
      );
      setState(() {
        documentData = data;
        hasSigned = thisSigner['status'] == 'signed';
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบเอกสาร')),
      );
    }
  }

  bool isMyTurnToSign(List<Map<String, dynamic>> signers) {
    for (var signer in signers) {
      if (signer['phone'] == widget.phoneNumber) return true;
      if (signer['status'] != 'signed') return false;
    }
    return false;
  }

  Future<void> notifyNextSigner(List<Map<String, dynamic>> signers) async {
    final index = signers.indexWhere((s) => s['phone'] == widget.phoneNumber);
    if (index != -1 && index + 1 < signers.length) {
      final next = signers[index + 1];
      final name = next['name'] ?? 'คุณ';
      final email = next['email'];
      if (email != null) {
        await EmailService.sendEmail(
          toName: name,
          toEmail: email,
          message: 'ถึงคิวของคุณแล้ว กรุณาเข้าไปเซ็นเอกสารในระบบ ThaiSign',
        );
      }
    }
  }

  Future<void> handleSign(Uint8List signatureBytes) async {
    final fileName = 'signatures/${widget.documentId}_${widget.phoneNumber}.png';
    await FirebaseStorage.instance.ref(fileName).putData(signatureBytes);

    final docRef = FirebaseFirestore.instance.collection('documents').doc(widget.documentId);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      final signers = List<Map<String, dynamic>>.from(data['signers']);
      final index = signers.indexWhere((s) => s['phone'] == widget.phoneNumber);
      if (index != -1) {
        signers[index]['status'] = 'signed';
        signers[index]['signedAt'] = DateTime.now().toIso8601String();
        signers[index]['signatureUrl'] = await FirebaseStorage.instance.ref(fileName).getDownloadURL();
        await docRef.update({'signers': signers});
        await notifyNextSigner(signers);
        setState(() {
          hasSigned = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เซ็นสำเร็จ')),
        );
      }
    }
  }

  Widget _buildDocumentPreview(String fileUrl) {
    if (fileUrl.toLowerCase().endsWith('.pdf')) {
      return PDF(
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ).cachedFromUrl(
        fileUrl,
        placeholder: (progress) => Center(child: Text('กำลังโหลด... $progress%')),
        errorWidget: (error) => Center(child: Text('❌ แสดง PDF ไม่ได้: $error')),
      );
    } else {
      return Image(
        image: NetworkImageWithRetry(fileUrl),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Text('❌ โหลดรูปภาพไม่ได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (documentData == null) return const Scaffold(body: Center(child: Text('ไม่พบข้อมูล')));

    final signers = List<Map<String, dynamic>>.from(documentData!['signers']);
    final fileUrl = documentData!['fileUrl'];

    return Scaffold(
      appBar: AppBar(title: const Text('เซ็นเอกสาร')),
      body: Column(
        children: [
          Expanded(
            child: fileUrl != null
                ? _buildDocumentPreview(fileUrl)
                : const Center(child: Text('ไม่พบไฟล์เอกสาร')),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('📄 เอกสาร: ${documentData!['title'] ?? 'ไม่มีชื่อ'}'),
                const SizedBox(height: 16),
                //  แสดงรายชื่อผู้เซ็นพร้อมสถานะ/=
                Text('🖋️ รายชื่อผู้เซ็น', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 200, child: SignerStatusList(documentId: widget.documentId),
      ),
                const SizedBox(height: 16),
                //  จบแสดงรายชื่อ

                if (hasSigned)
                  const Text('✅ คุณได้เซ็นแล้วเรียบร้อย', style: TextStyle(color: Colors.green))
                else if (!isMyTurnToSign(signers))
                  const Text('⏳ กรุณารอผู้เซ็นลำดับก่อนหน้าให้เสร็จก่อน', style: TextStyle(color: Colors.orange))
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OTPInputPage(
                            phoneNumber: widget.phoneNumber,
                            onVerified: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignaturePage(
                                    onConfirm: handleSign,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('✍️ เซ็นเอกสาร'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
