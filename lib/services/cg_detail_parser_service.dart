import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

class CGDetailParserService {
  Future<List<String>> parseDetailpage(String detailPageUrl) async {
    try {
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
      };
      final response = await http.get(Uri.parse(detailPageUrl), headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Failed to load detail page: ${response.statusCode}');
      }

      final document = parser.parse(response.body);
      final List<String> videoUrls = [];

      // Find all <video> tags and get their src attribute, as requested.
      final videoElements = document.querySelectorAll('video');

      for (final videoElement in videoElements) {
        final src = videoElement.attributes['src'];
        if (src != null && src.isNotEmpty) {
          if (!videoUrls.contains(src)) {
            videoUrls.add(src);
          }
        }
      }

      if (videoUrls.isEmpty) {
        print("No <video> tags with a src attribute were found. The parsing logic may need adjustment.");
      }

      return videoUrls;
    } catch (e) {
      print('Error parsing detail page: $e');
      rethrow;
    }
  }
}
