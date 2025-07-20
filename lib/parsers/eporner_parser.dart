import 'package:html/parser.dart' as parser;
import '../models/video_info.dart';
import 'base_video_parser.dart';

class EpornerParser implements BaseVideoParser {
  @override
  Future<List<VideoInfo>> parse({required String htmlContent, required String baseUrl}) async {
    final document = parser.parse(htmlContent);
    final List<VideoInfo> videos = [];

    final elements = document.querySelectorAll('div.mb');

    for (final element in elements) {
      try {
        final titleLinkElement = element.querySelector('p.mbtit > a');
        final imgElement = element.querySelector('.mbimg img');
        final durationElement = element.querySelector('span.mbtim');

        final title = titleLinkElement?.text.trim() ?? '';
        final detailPageUrl = titleLinkElement?.attributes['href'] ?? '';
        final coverUrl = imgElement?.attributes['src'] ?? imgElement?.attributes['data-src'] ?? '';
        final duration = durationElement?.text.trim() ?? '00:00';

        if (title.isNotEmpty && detailPageUrl.isNotEmpty && coverUrl.isNotEmpty) {
          videos.add(VideoInfo(
            coverUrl: coverUrl,
            title: title,
            duration: duration,
            detailPageUrl: Uri.parse(baseUrl).resolve(detailPageUrl).toString(),
          ));
        }
      } catch (e) {
        print('Error parsing an element in EpornerParser: $e');
      }
    }

    return videos;
  }

  @override
  Future<List<String>> parseDetail({required String htmlContent}) async {
    final document = parser.parse(htmlContent);
    final List<String> videoUrls = [];

    // 尝试从 video 标签中获取视频源
    final videoElement = document.querySelector('video#vjs_video_3_html5_api');
    if (videoElement != null) {
      final sourceElements = videoElement.querySelectorAll('source');
      for (final source in sourceElements) {
        final src = source.attributes['src'];
        if (src != null && src.isNotEmpty) {
          videoUrls.add(src);
        }
      }
    }

    // 尝试从 script 标签中获取视频源，通常是动态生成的链接
    final scriptElements = document.querySelectorAll('script');
    for (final script in scriptElements) {
      final scriptContent = script.text;
      // 查找类似 "file: '...'" 的模式
      final fileMatch = RegExp(r"file:\s*'(.*?)'").firstMatch(scriptContent);
      if (fileMatch != null) {
        videoUrls.add(fileMatch.group(1)!);
      }
    }

    return videoUrls.toSet().toList(); // 去重并返回
  }
}