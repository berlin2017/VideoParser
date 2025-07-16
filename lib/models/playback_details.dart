import 'video_format.dart';

class PlaybackDetails {
  final String title;
  final List<VideoFormat> formats;

  PlaybackDetails({
    required this.title,
    required this.formats,
  });

  factory PlaybackDetails.fromJson(Map<String, dynamic> json) {
    var formatsList = json['formats'] as List;
    List<VideoFormat> parsedFormats = formatsList.map((i) => VideoFormat.fromJson(i)).toList();

    return PlaybackDetails(
      title: json['title'] as String,
      formats: parsedFormats,
    );
  }
}