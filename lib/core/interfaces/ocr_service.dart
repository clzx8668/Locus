/// OCR 服务抽象接口 —— 为后续 google_mlkit_text_recognition 接入预留
abstract class OcrService {
  /// 从图片路径提取文本
  Future<String> extractText(String imagePath);
}

/// 空实现 —— 未接入 OCR 时使用
class NoOpOcrService implements OcrService {
  @override
  Future<String> extractText(String imagePath) async => '';
}
