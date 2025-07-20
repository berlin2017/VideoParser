import 'package:html/parser.dart' as parser;
import '../models/video_info.dart';
import 'base_video_parser.dart';

class XNXXParser implements BaseVideoParser {
  @override
  Future<List<VideoInfo>> parse({required String htmlContent, required String baseUrl}) async {
    final document = parser.parse(htmlContent);
    final List<VideoInfo> videos = [];

    final elements = document.querySelectorAll('div.thumb-block');

    for (final element in elements) {
      try {
        final titleLinkElement = element.querySelector('.thumb-under > p > a');
        final imgElement = element.querySelector('.thumb-inside > .thumb > a > img');
        final durationElement = element.querySelector('.metadata');

        final title = titleLinkElement?.attributes['title']?.trim() ?? '';
        final detailPageUrl = titleLinkElement?.attributes['href'] ?? '';
        final coverUrl = imgElement?.attributes['data-src'] ?? imgElement?.attributes['src'] ?? '';
        print('DEBUG XNXX: imgElement outerHtml: ${imgElement?.outerHtml}'); // 新增调试信息
        print('DEBUG XNXX: Extracted coverUrl: $coverUrl'); // 新增调试信息
        
        String duration = '00:00';
        if (durationElement != null) {
          final text = durationElement.text.trim();
          final durationMatch = RegExp(r'(\d+min)').firstMatch(text);
          if (durationMatch != null) {
            duration = durationMatch.group(1)!;
          }
        }

        if (title.isNotEmpty && detailPageUrl.isNotEmpty && coverUrl.isNotEmpty) {
          videos.add(VideoInfo(
            coverUrl: coverUrl,
            title: title,
            duration: duration,
            detailPageUrl: Uri.parse(baseUrl).resolve(detailPageUrl).toString(),
          ));
        }
      } catch (e) {
        print('Error parsing an element in XNXXParser: $e');
      }
    }

    return videos;
  }

  @override
  Future<List<String>> parseDetail({required String htmlContent}) async {
    final document = parser.parse(htmlContent);
    final List<String> videoUrls = [];

    // 尝试从 video 标签中获取视频源
    final videoElement = document.querySelector('video#video_html5_api');
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
      // 查找类似 "html5player.setVideoUrlHigh('...')" 的模式
      final highQualityMatch = RegExp(r"html5player\.setVideoUrlHigh\('(.*?)'\)").firstMatch(scriptContent);
      if (highQualityMatch != null) {
        videoUrls.add(highQualityMatch.group(1)!);
      }
      // 查找类似 "html5player.setVideoUrlLow('...')" 的模式
      final lowQualityMatch = RegExp(r"html5player\.setVideoUrlLow\('(.*?)'\)").firstMatch(scriptContent);
      if (lowQualityMatch != null) {
        videoUrls.add(lowQualityMatch.group(1)!);
      }
      // 查找类似 "html5player.setVideoUrl('...')" 的模式
      final defaultQualityMatch = RegExp(r"html5player\.setVideoUrl\('(.*?)'\)").firstMatch(scriptContent);
      if (defaultQualityMatch != null) {
        videoUrls.add(defaultQualityMatch.group(1)!);
      }
    }

    return videoUrls.toSet().toList(); // 去重并返回
  }
}