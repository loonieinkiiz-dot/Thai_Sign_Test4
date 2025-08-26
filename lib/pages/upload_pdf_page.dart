import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UploadPdfPage extends StatefulWidget {
  const UploadPdfPage({super.key});

  @override
  State<UploadPdfPage> createState() => _UploadPdfPageState();
}

class _UploadPdfPageState extends State<UploadPdfPage> {
  File? selectedFile;
  final titleController = TextEditingController();
  final signerControllers = List.generate(5, (_) => TextEditingController());
  bool isUploading = false;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadDocument() async {
    if (selectedFile == null || titleController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'กรุณาเลือกไฟล์และกรอกชื่อเอกสาร');
      return;
    }

    // ✅ ตรวจสอบขนาดไฟล์
    final fileSizeInBytes = selectedFile!.lengthSync();
    final maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    if (fileSizeInBytes > maxSizeInBytes) {
      Fluttertoast.showToast(msg: 'ไฟล์ใหญ่เกิน 5MB กรุณาเลือกไฟล์ใหม่');
      return;
    }

    final signerList = signerControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => c.text.trim())
        .toList();

    if (signerList.isEmpty) {
      Fluttertoast.showToast(msg: 'กรุณาระบุเบอร์ผู้เซ็นอย่างน้อย 1 คน');
      return;
    }

    setState(() => isUploading = true);

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName');
      await ref.putFile(selectedFile!);
      final url = await ref.getDownloadURL();

      final docRef = FirebaseFirestore.instance.collection('documents').doc();
      final now = Timestamp.now();

      final signerData = signerList.asMap().entries.map((entry) {
        return {
          'phone': entry.value,
          'status': entry.key == 0 ? 'waiting' : 'pending',
          'signed_at': null,
        };
      }).toList();

      await docRef.set({
        'title': titleController.text.trim(),
        'file_url': url,
        'file_type': selectedFile!.path.endsWith('.pdf') ? 'pdf' : 'image',
        'signerList': signerData,
        'status': 'in_progress',
        'created_at': now,
        'admin_uid': 'demo_admin', // TODO: แทนที่ด้วย UID ของ Admin ที่ Login จริง
      });

      Fluttertoast.showToast(msg: 'อัปโหลดสำเร็จ');
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: 'เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📤 อัปโหลดเอกสาร')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ElevatedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('เลือก PDF หรือรูปภาพ'),
            ),
            const SizedBox(height: 12),
            if (selectedFile != null)
              Text('📄 เลือกไฟล์: ${selectedFile!.path.split('/').last}'),

            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'ชื่อเอกสาร'),
            ),

            const SizedBox(height: 12),
            const Text('👤 ผู้เซ็น (ลำดับสูงสุด 5 คน)',
                style: TextStyle(fontWeight: FontWeight.bold)),

            ...List.generate(5, (i) {
              return TextField(
                controller: signerControllers[i],
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'ลำดับที่ ${i + 1}',
                  hintText: 'ใส่เบอร์โทร เช่น 080000000${i + 1}',
                ),
              );
            }),

            const SizedBox(height: 20),
            isUploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: uploadDocument,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('อัปโหลด'),
                  ),
          ],
        ),
      ),
    );
  }
}
