
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import '../models/video_info.dart';
import 'base_video_parser.dart';

class SourceAVideoParser implements BaseVideoParser {
  @override
  Future<List<VideoInfo>> parse({required String htmlContent, required String baseUrl}) async {
    final document = parser.parse(htmlContent);
    final List<VideoInfo> videos = [];

    final elements = document.querySelectorAll('div.thumb-block');

    for (final element in elements) {
      try {
        final titleElement = element.querySelector('p.title a');
        final thumbElement = element.querySelector('div.thumb-inside a');
        final imgElement = thumbElement?.querySelector('img');
        final durationElement = element.querySelector('span.duration');

        final title = titleElement?.text.trim() ?? '';
        final relativeUrl = thumbElement?.attributes['href'] ?? '';
        final coverUrl = imgElement?.attributes['data-src'] ?? imgElement?.attributes['src'] ?? '';
        final duration = durationElement?.text.trim() ?? '00:00';

        if (title.isNotEmpty && relativeUrl.isNotEmpty && coverUrl.isNotEmpty) {
          // Construct the absolute URL
          final absoluteUrl = Uri.parse(baseUrl).resolve(relativeUrl).toString();

          videos.add(VideoInfo(
            coverUrl: coverUrl,
            title: title,
            duration: duration,
            detailPageUrl: absoluteUrl,
          ));
        }
      } catch (e) {
        print('Error parsing an element in SourceAVideoParser: $e');
      }
    }

    return videos;
  }
}
