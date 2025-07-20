import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:html_unescape/html_unescape.dart';
import '../models/video_info.dart';
import 'base_video_parser.dart';

class CGParser implements BaseVideoParser {
  @override
  Future<List<VideoInfo>> parse({required String htmlContent, required String baseUrl}) async {
    print('DEBUG: Full HTML content received by CGParser:\n$htmlContent\n--- End Full HTML Content ---'); // 新增调试信息
    final unescape = HtmlUnescape();
    final unescapedHtml = unescape.convert(htmlContent);

    final document = parser.parse(unescapedHtml);
    final List<VideoInfo> videos = [];

    final elements = document.querySelectorAll('article');

    for (final element in elements) {
      try {
        final aElement = element.querySelector('a');
        if (aElement == null) continue;

        final detailPageUrl = aElement.attributes['href'] ?? '';
        if (detailPageUrl.isEmpty) continue;

        final titleElement = element.querySelector('h2.post-card-title');
        final title = titleElement?.text.trim() ?? '';

        String coverUrl = '';
        final backgroundDiv = element.querySelector('.blog-background');
        if (backgroundDiv != null) {
          final style = backgroundDiv.attributes['style'] ?? '';
          print('DEBUG: Raw style attribute: $style'); // 保留调试信息
          final regExp = RegExp(r'''background-image: url((?:'|"|&quot;)(.*?)(?:'|"|&quot;))''');
          final match = regExp.firstMatch(style);
          if (match != null) {
            coverUrl = match.group(1)!;
            print('DEBUG: Regex matched. Extracted URL from style: $coverUrl'); // 新增调试信息
          } else {
            print('DEBUG: Regex did NOT match in style attribute.'); // 保留调试信息
          }
        }

        // 如果从 style 属性中没有获取到，则尝试从 script 标签中获取
        if (coverUrl.isEmpty) {
          final scriptElement = element.querySelector('script');
          if (scriptElement != null) {
            final scriptContent = scriptElement.text;
            final regExp = RegExp(r"loadBannerDirect\('(.*?)',");
            final match = regExp.firstMatch(scriptContent);
            if (match != null) {
              coverUrl = match.group(1)!;
              print('DEBUG: Extracted URL from script: $coverUrl'); // 新增调试信息
            }
          }
        }
        print('Parsed coverUrl: $coverUrl'); // 保留调试信息

        if (title.isNotEmpty && detailPageUrl.isNotEmpty) {
          videos.add(VideoInfo(
            duration: '',
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

  @override
  Future<List<String>> parseDetail({required String htmlContent}) async {
    if (kDebugMode) {
      print('--- 51CG Detail Page HTML ---');
      print(htmlContent);
      print('--- End 51CG Detail Page HTML ---');
    }

    final document = parser.parse(htmlContent);
    final videoUrls = <String>[];

    final dplayerElements = document.querySelectorAll('div.dplayer');
    for (final element in dplayerElements) {
      final config = element.attributes['data-config'];
      if (config != null) {
        try {
          final jsonConfig = jsonDecode(config);
          final videoUrl = jsonConfig['video']?['url'] as String?;
          if (videoUrl != null && videoUrl.isNotEmpty) {
            videoUrls.add(videoUrl);
          }
        } catch (e) {
          print('Error parsing data-config JSON: $e');
        }
      }
    }

    if (videoUrls.isEmpty) {
      final videoElement = document.querySelector('video.dplayer-video');
      if (videoElement != null) {
        final videoUrl = videoElement.attributes['src'] ?? '';
        if (videoUrl.isNotEmpty) {
          videoUrls.add(videoUrl);
        }
      }
    }

    return videoUrls;
  }
}