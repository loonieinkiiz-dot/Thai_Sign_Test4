import 'package:flutter/material.dart';
import 'pages/phone_number_page.dart';
import 'pages/otp_verify_page.dart';
import 'pages/upload_pdf_page.dart';
import 'pages/document_list_page.dart';
import 'pages/sign_document_page.dart';
import 'pages/my_documents_page.dart';

// import 'pages/otp_verify_page.dart'; // ไว้สร้างต่อ

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignFlow',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const PhoneNumberPage(),
        '/otp': (context) {
          final phone = ModalRoute.of(context)!.settings.arguments as String;
          return OtpVerifyPage(phoneNumber: phone);
        },
        '/upload': (context) => const UploadPdfPage(),
        '/documents': (context) => const DocumentListPage(),
        '/sign': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return SignDocumentPage(
      documentId: args['documentId'],
      phoneNumber: args['phoneNumber'],
    );
        },
        '/my-documents': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return MyDocumentsPage(phoneNumber: args['phone']);
  },
        
      },
    );
  }
}