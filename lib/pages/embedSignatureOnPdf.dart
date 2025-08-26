import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_render/pdf_render.dart' as render;

/// รายละเอียดตำแหน่งของลายเซ็นบนเอกสาร PDF
/// แต่ละตำแหน่งสามารถกำหนดได้ว่าอยู่หน้าไหน (page),
/// พิกัดตำแหน่ง x และ y บนหน้าเอกสาร,
/// พร้อมข้อมูลเสริมอย่างชื่อและวันที่
class SignaturePlacement {
  final Uint8List signatureBytes;
  final double x;
  final double y;
  final int page;
  final String? name;
  final String? date;

  SignaturePlacement({
    required this.signatureBytes,
    required this.x,
    required this.y,
    required this.page,
    this.name,
    this.date,
  });
}

/// ฟังก์ชันสำหรับฝังลายเซ็นและข้อความกำกับ (ชื่อ / วันที่)
/// ลงใน PDF ที่กำหนด รองรับหลายหน้าและหลายจุดบนแต่ละหน้า
/// ส่งคืนเป็น PDF ใหม่แบบ Uint8List ที่ฝังลายเซ็นแล้ว
Future<Uint8List> embedSignaturesOnPdf({
  required Uint8List pdfData,
  required List<SignaturePlacement> placements,
}) async {
  final doc = pw.Document();
  final pdf = await render.PdfDocument.openData(pdfData);
  final totalPages = pdf.pageCount;

  for (int i = 0; i < totalPages; i++) {
    final page = await pdf.getPage(i + 1);
    final pageImage = await page.render(); // แปลงหน้า PDF เป็นรูปภาพ
    final uiImage = await pageImage.createImageIfNotAvailable();
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final imageBytes = byteData!.buffer.asUint8List();

    final image = pw.MemoryImage(imageBytes);

    final pageWidth = pageImage.width.toDouble();
    final pageHeight = pageImage.height.toDouble();

    doc.addPage(
      pw.Page(
        pageFormat: pw_pdf.PdfPageFormat(pageWidth, pageHeight),
        build: (context) {
          return pw.Stack(
            children: [
              // แสดงภาพพื้นหลังของหน้า PDF
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Image(image, width: pageWidth, height: pageHeight),
              ),
              // วางลายเซ็นและข้อความที่เกี่ยวข้อง
              ...placements.where((p) => p.page == i).map((p) {
                final sigImg = pw.MemoryImage(p.signatureBytes);
                return pw.Positioned(
                  left: p.x,
                  top: p.y,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(sigImg, width: 100), // ลายเซ็น
                      if (p.name != null)
                        pw.Text(p.name!, style: pw.TextStyle(fontSize: 10)),
                      if (p.date != null)
                        pw.Text(p.date!, style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    // No need to dispose or release pageImage or page
    
  }

  return doc.save(); // ส่งคืนไฟล์ PDF ที่ฝังลายเซ็นแล้ว
}
