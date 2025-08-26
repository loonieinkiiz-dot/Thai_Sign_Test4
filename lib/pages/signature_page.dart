import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';


class SignaturePage extends StatefulWidget {
  final Function(Uint8List signatureBytes) onConfirm;

  const SignaturePage({super.key, required this.onConfirm});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  late SignatureController _controller;
  Color _penColor = Colors.black;
  double _penStrokeWidth = 3.0;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: _penStrokeWidth,
      penColor: _penColor,
    );
  }

  void _recreateController() {
    _controller.dispose();
    _controller = SignatureController(
      penStrokeWidth: _penStrokeWidth,
      penColor: _penColor,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปรดเซ็นก่อนกดยืนยัน')),
      );
      return;
    }

    final signatureBytes = await _controller.toPngBytes();
    if (signatureBytes != null) {
      widget.onConfirm(signatureBytes);
      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('ออกจากหน้าลายเซ็น?'),
            content: const Text('ลายเซ็นจะไม่ถูกบันทึก หากกดย้อนกลับ'),
            actions: [
              TextButton(
                child: const Text('ยกเลิก'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('ตกลง'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('✍️ เซ็นลายเซ็น')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Signature canvas
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.grey[200],
                  ),
                  child: Signature(
                    controller: _controller,
                    backgroundColor: Colors.grey[200]!,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pen color selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('สีปากกา:'),
                  const SizedBox(width: 8),
                  ...[
                    Colors.black,
                    Colors.blue,
                    Colors.red,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _penColor = color;
                          _recreateController();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _penColor == color ? Colors.grey[800]! : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),

              // Pen stroke width slider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ความหนาเส้น:'),
                  const SizedBox(width: 10),
                  Slider(
                    value: _penStrokeWidth,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${_penStrokeWidth.toStringAsFixed(1)} px',
                    onChanged: (value) {
                      setState(() {
                        _penStrokeWidth = value;
                        _recreateController();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('ลบ'),
                    onPressed: () => _controller.clear(),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('ยกเลิก'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('ยืนยันลายเซ็น'),
                    onPressed: _onConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
