
import '../parsers/base_video_parser.dart';

class VideoSource {
  final String name;
  final String baseUrl;
  final String? paginatedUrlTemplate; // e.g., 'https://example.com/videos?page=%d'
  final BaseVideoParser parser;

  VideoSource({
    required this.name,
    required this.baseUrl,
    this.paginatedUrlTemplate,
    required this.parser,
  });
}
