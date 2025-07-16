import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import '../models/video_info.dart';
import 'base_video_parser.dart';

class CGParser implements BaseVideoParser {
  @override
  Future<List<VideoInfo>> parse({required String htmlContent, required String baseUrl}) async {
    final document = parser.parse(htmlContent);
    final List<VideoInfo> videos = [];

    final elements = document.querySelectorAll('article');

    for (final element in elements) {
      try {
        final aElement = element.querySelector('a');
        if (aElement == null) continue;

        final detailPageUrl = aElement.attributes['href'] ?? '';
        if (detailPageUrl.isEmpty || !detailPageUrl.contains('archives')) continue;

        final titleElement = element.querySelector('h2.post-card-title');
        final title = titleElement?.text.trim() ?? '';

        final scriptElement = element.querySelector('script');
        final scriptContent = scriptElement?.innerHtml ?? '';
        final coverUrlMatch = RegExp(r"loadBannerDirect\('(.*?)'").firstMatch(scriptContent);
        final coverUrl = coverUrlMatch?.group(1) ?? '';

        if (title.isNotEmpty && detailPageUrl.isNotEmpty && coverUrl.isNotEmpty) {
          videos.add(VideoInfo(
            duration: '', // Duration is not available on the list page
            coverUrl: coverUrl,
            title: title,
            detailPageUrl: Uri.parse(baseUrl).resolve(detailPageUrl).toString(),
          ));
        }
      } catch (e) {
        print('Error parsing an element in CGParser: $e');
      }
    }
    return videos;
  }
}