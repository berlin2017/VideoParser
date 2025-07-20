
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import '../models/video_info.dart';
import 'base_video_parser.dart';

class PornHubParser implements BaseVideoParser {
  @override
  Future<List<VideoInfo>> parse({required String htmlContent, required String baseUrl}) async {
    final document = parser.parse(htmlContent);
    final List<VideoInfo> videos = [];

    // Select all video items using the selector from your Kotlin code.
    final elements = document.querySelectorAll('li[data-video-vkey]');

    for (final element in elements) {
      try {
        final videoKey = element.attributes['data-video-vkey'];
        if (videoKey == null || videoKey.isEmpty) {
          continue; // Skip if the key is missing
        }

        final titleElement = element.querySelector('span.title a');
        final imgElement = element.querySelector('div.phimage img.js-videoThumb');
        final durationElement = element.querySelector('var.duration');

        final title = titleElement?.attributes['title']?.trim() ?? titleElement?.text.trim() ?? '';
        
        // Prioritize 'data-image', then 'data-path', then 'src' as in your Kotlin code.
        final coverUrl = imgElement?.attributes['data-image'] ?? 
                         imgElement?.attributes['data-path'] ?? 
                         imgElement?.attributes['src'] ?? '';

        final duration = durationElement?.text.trim() ?? '00:00';

        if (title.isNotEmpty && coverUrl.isNotEmpty) {
          // Construct the detail page URL from the base URL and the video key.
          final detailPageUrl = Uri.parse(baseUrl).resolve('/view_video.php?viewkey=$videoKey').toString();

          videos.add(VideoInfo(
            coverUrl: coverUrl,
            title: title,
            duration: duration,
            detailPageUrl: detailPageUrl,
          ));
        }
      } catch (e) {
        print('Error parsing an element in PornHubParser: $e');
      }
    }

    return videos;
  }

  @override
  Future<List<String>> parseDetail({required String htmlContent}) async {
    // TODO: implement parseDetail
    return [];
  }
}
