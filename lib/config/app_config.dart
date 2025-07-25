
import '../models/video_source.dart';
import '../parsers/eporner_parser.dart';
import '../parsers/xvideos_parser.dart';
import '../parsers/pornhub_parser.dart';
import '../parsers/cg_parser.dart';
import '../parsers/xnxx_parser.dart';
import '../parsers/xhamster_parser.dart';
import '../parsers/spankbang_parser.dart';

class AppConfig {
  static final List<VideoSource> videoSources = [
    VideoSource(
      name: 'XVideos',
      baseUrl: 'https://www.xvideos.com', // This is a placeholder URL
      paginatedUrlTemplate: 'https://www.xvideos.com/new/%d',
      parser: XVideosParser(),
    ),
    VideoSource(
      name: 'PornHub',
      baseUrl: 'https://www.pornhub.com', // This is a placeholder URL
      paginatedUrlTemplate: 'https://www.pornhub.com/video?page=%d', // Example template
      parser: PornHubParser(),
    ),
    VideoSource(
      name: '51cg',
      baseUrl: 'https://51cg1.com/',
      paginatedUrlTemplate: 'https://51cg1.com/page/%d/',
      parser: CGParser(),
    ),
    VideoSource(
      name: 'XNXX',
      baseUrl: 'https://www.xnxx.com/hits',
      paginatedUrlTemplate: 'https://www.xnxx.com/hits/%d',
      parser: XNXXParser(),
    ),
    VideoSource(
      name: 'xHamster',
      baseUrl: 'https://zh.xhamster.com/',
      paginatedUrlTemplate: 'https://zh.xhamster.com/%d',
      parser: XHamsterParser(),
    ),
    VideoSource(
      name: 'Eporner',
      baseUrl: 'https://www.eporner.com/',
      paginatedUrlTemplate: 'https://www.eporner.com/%d/',
      parser: EpornerParser(),
    ),
    VideoSource(
      name: 'SpankBang',
      baseUrl: 'https://spankbang.com/trending_videos/',
      paginatedUrlTemplate: 'https://spankbang.com/trending_videos/%d/',
      parser: SpankBangParser(),
    ),
  ];
}
