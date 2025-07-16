
import '../parsers/base_video_parser.dart';

class VideoSource {
  final String name;
  final String baseUrl;
  final BaseVideoParser parser;

  VideoSource({
    required this.name,
    required this.baseUrl,
    required this.parser,
  });
}
