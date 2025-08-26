import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePage extends StatefulWidget {
  final Function(Uint8List) onConfirm;

  const SignaturePage({super.key, required this.onConfirm});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final SignatureController _controller = SignatureController(penStrokeWidth: 3, penColor: Colors.black);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงลายเซ็น')),
      body: Column(
        children: [
          Expanded(
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.grey[200]!,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () => _controller.clear(),
                child: const Text('ล้าง'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final signature = await _controller.toPngBytes();
                  if (signature != null) {
                    widget.onConfirm(signature);
                    Navigator.pop(context);
                  }
                },
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
