
import '../models/video_source.dart';
import '../parsers/source_a_parser.dart';
import '../parsers/source_b_parser.dart';

class AppConfig {
  static final List<VideoSource> videoSources = [
    VideoSource(
      name: '数据源 A',
      baseUrl: 'https://www.xvideos.com', // This is a placeholder URL
      parser: SourceAVideoParser(),
    ),
    VideoSource(
      name: '数据源 B',
      baseUrl: 'https://www.pornhub.com', // This is a placeholder URL
      parser: SourceBVideoParser(),
    ),
  ];
}
