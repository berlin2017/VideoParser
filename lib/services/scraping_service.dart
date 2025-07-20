
import 'package:http/http.dart' as http;
import '../models/video_source.dart';
import '../models/video_info.dart';
import '../config/app_config.dart';

class ScrapingService {
  Future<List<VideoInfo>> fetchVideoList(VideoSource source, {int page = 1}) async {
    try {
      // Define a standard set of headers to mimic a real browser.
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Language': 'en-US,en;q=0.9',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
      };

      String url;
      if (page > 1 && source.paginatedUrlTemplate != null) {
        url = source.paginatedUrlTemplate!.replaceAll('%d', page.toString());
      } else {
        url = source.baseUrl;
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return await source.parser.parse(htmlContent: response.body, baseUrl: source.baseUrl);
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching video list for ${source.name} (page $page): $e');
      rethrow;
    }
  }

  Future<List<String>> fetchVideoDetail(String detailPageUrl, String sourceName) async {
    try {
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
      };

      final response = await http.get(Uri.parse(detailPageUrl), headers: headers);

      if (response.statusCode == 200) {
        final source = AppConfig.videoSources.firstWhere((s) => s.name == sourceName);
        return await source.parser.parseDetail(htmlContent: response.body);
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching video detail for $detailPageUrl: $e');
      rethrow;
    }
  }
}
