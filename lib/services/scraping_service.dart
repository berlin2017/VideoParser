
import 'package:http/http.dart' as http;
import '../models/video_source.dart';
import '../models/video_info.dart';

class ScrapingService {
  Future<List<VideoInfo>> fetchVideoList(VideoSource source) async {
    try {
      // Define a standard set of headers to mimic a real browser.
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Language': 'en-US,en;q=0.9',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
      };

      final response = await http.get(Uri.parse(source.baseUrl), headers: headers);

      if (response.statusCode == 200) {
        return await source.parser.parse(htmlContent: response.body, baseUrl: source.baseUrl);
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching video list for ${source.name}: $e');
      rethrow;
    }
  }
}
