import '../models/video_info.dart';

abstract class BaseVideoParser {
  Future<List<VideoInfo>> parse({required String htmlContent, required String baseUrl});
}