import 'package:html/parser.dart' as parser;

import '../models/video_info.dart';
import 'base_video_parser.dart';

class XHamsterParser implements BaseVideoParser {
  @override
  Future<List<VideoInfo>> parse({
    required String htmlContent,
    required String baseUrl,
  }) async {
    print(
      'DEBUG XHamster: Full HTML content received by XHamsterParser:\n$htmlContent\n--- End Full HTML Content ---',
    ); // 新增调试信息
    final document = parser.parse(htmlContent);
    final List<VideoInfo> videos = [];

    // 尝试解析移动端结构
    var elements = document.querySelectorAll('li.thumb-list-mobile-item');

    // 如果移动端结构为空，则尝试解析桌面端结构
    if (elements.isEmpty) {
      elements = document.querySelectorAll('div.video-thumb-info');
    }

    for (final element in elements) {
      try {
        String title = '';
        String detailPageUrl = '';
        String coverUrl = '';
        String duration = '00:00';

        // 移动端结构解析
        if (element.classes.contains('thumb-list-mobile-item')) {
          final titleLinkElement = element.querySelector(
            'a.mobile-video-thumb__name',
          );
          final imgElement = element.querySelector(
            'img.thumb-image-container__no-lazy-thumb',
          );
          final durationElement = element.querySelector(
            '.thumb-image-container__on-video time',
          );

          title = titleLinkElement?.text.trim() ?? '';
          detailPageUrl = titleLinkElement?.attributes['href'] ?? '';
          coverUrl = imgElement?.attributes['src'] ?? '';
          if (durationElement != null) {
            duration = durationElement.text.trim();
          }
        }
        // 桌面端结构解析
        else if (element.classes.contains('video-thumb-info')) {
          final titleLinkElement = element.querySelector(
            'a.video-thumb-info__name',
          );
          final imgElement = element.querySelector(
            'img.thumb-image-container__image',
          );
          final durationElement = element.querySelector(
            '[data-role="video-duration"]',
          );

          title = titleLinkElement?.text.trim() ?? '';
          detailPageUrl = titleLinkElement?.attributes['href'] ?? '';
          coverUrl = imgElement?.attributes['src'] ?? '';
          if (durationElement != null) {
            duration = durationElement.text.trim();
          }
        }

        final elements = document.querySelectorAll('div[data-video-id]');

        for (final element in elements) {
          try {
            print(
              'DEBUG XHamster Element HTML: ${element.outerHtml}',
            ); // 新增调试信息
            final titleLinkElement = element.querySelector(
              'a[data-role="thumb-link"]',
            );
            final imgElement = element.querySelector(
              'img[data-role="thumb-preview-img"]',
            );
            final durationElement = element.querySelector(
              '[data-role="video-duration"]',
            );

            final title =
                imgElement?.attributes['alt']?.trim() ??
                titleLinkElement?.attributes['title']?.trim() ??
                titleLinkElement?.text.trim() ??
                '';
            final detailPageUrl = titleLinkElement?.attributes['href'] ?? '';
            final coverUrl = imgElement?.attributes['src'] ?? '';

            String duration = '00:00';
            if (durationElement != null) {
              duration = durationElement.text.trim();
            }

            print('DEBUG XHamster - Title: $title'); // 新增调试信息
            print('DEBUG XHamster - DetailPageUrl: $detailPageUrl'); // 新增调试信息
            print('DEBUG XHamster - CoverUrl: $coverUrl'); // 新增调试信息
            print('DEBUG XHamster - Duration: $duration'); // 新增调试信息

            if (title.isNotEmpty &&
                detailPageUrl.isNotEmpty &&
                coverUrl.isNotEmpty) {
              videos.add(
                VideoInfo(
                  coverUrl: coverUrl,
                  title: title,
                  duration: duration,
                  detailPageUrl: Uri.parse(
                    baseUrl,
                  ).resolve(detailPageUrl).toString(),
                ),
              );
            }
          } catch (e) {
            print('Error parsing an element in XHamsterParser: $e');
          }
        }
      } catch (e) {
        print('Error parsing an element in XHamsterParser: $e');
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
      final videoUrlMatch = RegExp(
        r"video_url:\s*'(.*?)'",
      ).firstMatch(scriptContent);
      if (videoUrlMatch != null) {
        videoUrls.add(videoUrlMatch.group(1)!);
      }
    }

    return videoUrls.toSet().toList(); // 去重并返回
  }
}
