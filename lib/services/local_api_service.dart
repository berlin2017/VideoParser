
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/playback_details.dart';

class LocalApiService {
  final String _baseUrl = 'http://192.168.1.199:8080/api/video-info';

  Future<PlaybackDetails> fetchPlaybackDetails(String detailPageUrl) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'url': detailPageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaybackDetails.fromJson(data);
      } else {
        throw Exception('Failed to load playback details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching playback details: $e');
      rethrow;
    }
  }
}
