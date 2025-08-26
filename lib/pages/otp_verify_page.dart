import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpVerifyPage extends StatefulWidget {
  final String phoneNumber;

  const OtpVerifyPage({super.key, required this.phoneNumber});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final TextEditingController otpController = TextEditingController();
  String? verificationId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // รับ verificationId ที่ส่งมาจากหน้าก่อน
    verificationId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<void> _verifyOtp() async {
    final smsCode = otpController.text.trim();

    if (smsCode.length != 6 || verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัส OTP 6 หลักให้ถูกต้อง')),
      );
      return;
    }

    try {
      // สร้าง Credential จาก OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: smsCode,
      );

      // ✅ ล็อกอินสำเร็จ
      await FirebaseAuth.instance.signInWithCredential(credential);

      // ไปหน้าหลัก หรือแสดงว่าเข้าสู่ระบบแล้ว
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ!')),
      );

      // TODO: ไปหน้า Home หรือส่งไปยัง flow ถัดไป
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ผิดพลาด: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยัน OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('รหัส OTP ถูกส่งไปยังเบอร์: ${widget.phoneNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'กรอกรหัส OTP'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text('ยืนยันรหัส'),
            ),
          ],
        ),
      ),
    );
  }
}