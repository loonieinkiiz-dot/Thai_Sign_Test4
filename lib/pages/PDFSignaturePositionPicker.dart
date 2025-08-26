import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class SignatureRequest {
  int page;
  double x;
  double y;
  final String signerName;
  final String signerEmail;
  final bool requireFullName;
  final bool requireDate;

  SignatureRequest({
    required this.page,
    required this.x,
    required this.y,
    required this.signerName,
    required this.signerEmail,
    required this.requireFullName,
    required this.requireDate,
  });
}

class PDFSignaturePositionPicker extends StatefulWidget {
  final String pdfUrl;
  final void Function(List<SignatureRequest> requests) onDone;

  const PDFSignaturePositionPicker({
    super.key,
    required this.pdfUrl,
    required this.onDone,
  });

  @override
  State<PDFSignaturePositionPicker> createState() =>
      _PDFSignaturePositionPickerState();
}

class _PDFSignaturePositionPickerState
    extends State<PDFSignaturePositionPicker> {
  int currentPage = 1;
  final List<SignatureRequest> _markers = [];

  void _addMarker(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localOffset = box.globalToLocal(details.globalPosition);

    showDialog(
      context: context,
      builder: (_) {
        final nameController = TextEditingController();
        final emailController = TextEditingController();
        bool requireName = false;
        bool requireDate = false;

        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('กำหนดผู้เซ็น'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อผู้เซ็น'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'อีเมลผู้เซ็น'),
                  keyboardType: TextInputType.emailAddress,
                ),
                CheckboxListTile(
                  value: requireName,
                  onChanged: (val) =>
                      setDialogState(() => requireName = val ?? false),
                  title: const Text('ต้องใส่ชื่อ-นามสกุลจริง'),
                ),
                CheckboxListTile(
                  value: requireDate,
                  onChanged: (val) =>
                      setDialogState(() => requireDate = val ?? false),
                  title: const Text('ต้องใส่วันที่'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  final request = SignatureRequest(
                    page: currentPage,
                    x: localOffset.dx,
                    y: localOffset.dy,
                    signerName: nameController.text,
                    signerEmail: emailController.text,
                    requireFullName: requireName,
                    requireDate: requireDate,
                  );
                  setState(() {
                    _markers.add(request);
                  });
                  Navigator.pop(context);
                },
                child: const Text('เพิ่มจุดเซ็น'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('กำหนดตำแหน่งลายเซ็น'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () => widget.onDone(_markers),
          ),
        ],
      ),
      body: GestureDetector(
        onTapDown: _addMarker,
        child: Stack(
          children: [
            PDF(
              onPageChanged: (page, total) {
                setState(() {
                  currentPage = page ?? 1;
                });
              },
            ).cachedFromUrl(widget.pdfUrl),
            ..._markers
                .where((m) => m.page == currentPage)
                .map((m) => Positioned(
                      left: m.x,
                      top: m.y,
                      child: Draggable(
                        feedback: _markerWidget(),
                        child: _markerWidget(),
                        onDragEnd: (details) {
                          final offset = details.offset;
                          final local = (context.findRenderObject() as RenderBox)
                              .globalToLocal(offset);
                          setState(() {
                            m.x = local.dx;
                            m.y = local.dy;
                          });
                        },
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _markerWidget() => const Icon(Icons.edit_location, color: Colors.red);
}
