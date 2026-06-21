import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocParser {
  /// 从 PDF 提取纯文本
  static Future<String> extractTextFromPdf(String filePath) async {
    final File file = File(filePath);
    final PdfDocument document =
        PdfDocument(inputBytes: await file.readAsBytes());
    String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  /// 将长文本切片 (Chunking)
  /// 按照重叠滑动窗口切分，保证语义连贯性
  static List<String> chunkText(String text,
      {int chunkSize = 500, int overlap = 50}) {
    List<String> chunks = [];
    int i = 0;
    while (i < text.length) {
      int end = i + chunkSize;
      if (end > text.length) end = text.length;

      String chunk = text.substring(i, end);
      chunks.add(chunk);

      i += (chunkSize - overlap);
      if (i >= text.length) break;
    }
    return chunks;
  }
}
