// lib/utils/email_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String serviceId = 'service_signd';
  static const String templateId = 'template_SignD_Noti';
  static const String userId = 'vCvXb1rr1tLr4u8Pw';

  static Future<bool> sendEmail({
    required String toName,
    required String toEmail,
    required String message,
  }) async {
    const url = 'https://api.emailjs.com/api/v1.0/email/send';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_name': toName,
            'to_email': toEmail,
            'message': message,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ EmailJS ส่งไม่สำเร็จ: \$e');
      return false;
    }
  }
}
