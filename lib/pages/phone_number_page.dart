import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  final TextEditingController phoneController = TextEditingController();

  // ✅ ส่ง OTP ผ่าน Firebase
  Future<void> _sendOtp() async {
    String phoneNumber = phoneController.text.trim();
    if (phoneNumber.isEmpty || phoneNumber.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเบอร์โทรให้ถูกต้อง')),
      );
      return;
    }

    // 🔐 ส่ง OTP ไปยังเบอร์นี้
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+66${phoneNumber.substring(1)}', // เปลี่ยน 0 เป็น +66
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        // ✅ ส่งสำเร็จ ไปหน้า OTP
        Navigator.pushNamed(context, '/otp', arguments: verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบด้วยเบอร์มือถือ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendOtp,
              child: const Text('ขอรหัส OTP'),
            ),
          ],
        ),
      ),
    );
  }
}