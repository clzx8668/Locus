/// 内容块类型枚举 —— 统一管理所有块类型
enum BlockType {
  text,
  image,
  voice,
  video,
  file;

  /// 根据文件扩展名推断块类型
  static BlockType fromExtension(String extension) {
    final ext = extension.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return BlockType.image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return BlockType.video;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
      case 'flac':
      case 'ogg':
        return BlockType.voice;
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'txt':
      case 'csv':
      case 'ppt':
      case 'pptx':
        return BlockType.file;
      default:
        return BlockType.file;
    }
  }

  String get displayName {
    switch (this) {
      case BlockType.text:
        return '文字';
      case BlockType.image:
        return '图片';
      case BlockType.voice:
        return '录音';
      case BlockType.video:
        return '视频';
      case BlockType.file:
        return '文件';
    }
  }
}
