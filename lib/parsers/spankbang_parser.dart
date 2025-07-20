import 'package:html/parser.dart' as parser;
import '../models/video_info.dart';
import 'base_video_parser.dart';

class SpankBangParser implements BaseVideoParser {
  @override
  Future<List<VideoInfo>> parse({required String htmlContent, required String baseUrl}) async {
    final document = parser.parse(htmlContent);
    final List<VideoInfo> videos = [];

    final elements = document.querySelectorAll('div[data-testid="video-info-with-badge"]');

    for (final element in elements) {
      try {
        final titleLinkElement = element.querySelector('p.line-clamp-2 > a');
        // 封面图和时长可能通过JavaScript动态加载，此处暂时设为空
        final imgElement = null; // 暂时设为null，因为当前HTML片段中没有直接的img标签
        final durationElement = null; // 暂时设为null，因为当前HTML片段中没有直接的时长元素

        final title = titleLinkElement?.attributes['title']?.trim() ?? titleLinkElement?.text.trim() ?? '';
        final detailPageUrl = titleLinkElement?.attributes['href'] ?? '';
        final coverUrl = ''; // 暂时设为空，因为当前HTML片段中没有直接的img标签
        final duration = '00:00'; // 暂时设为默认值

        if (title.isNotEmpty && detailPageUrl.isNotEmpty) {
          videos.add(VideoInfo(
            coverUrl: coverUrl,
            title: title,
            duration: duration,
            detailPageUrl: Uri.parse(baseUrl).resolve(detailPageUrl).toString(),
          ));
        }
      } catch (e) {
        print('Error parsing an element in SpankBangParser: $e');
      }
    }

    return videos;
  }

  @override
  Future<List<String>> parseDetail({required String htmlContent}) async {
    final document = parser.parse(htmlContent);
    final List<String> videoUrls = [];

    // 尝试从 script 标签中获取视频源，通常是动态生成的链接
    final scriptElements = document.querySelectorAll('script');
    for (final script in scriptElements) {
      final scriptContent = script.text;
      // 查找类似 "video_url: '...'" 的模式
      final videoUrlMatch = RegExp(r"video_url:\s*'(.*?)'").firstMatch(scriptContent);
      if (videoUrlMatch != null) {
        videoUrls.add(videoUrlMatch.group(1)!);
      }
    }

    return videoUrls.toSet().toList(); // 去重并返回
  }
}