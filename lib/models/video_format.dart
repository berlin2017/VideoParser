
class VideoFormat {
  final String formatId;
  final String? resolution;
  final String url;
  final String protocol;

  VideoFormat({
    required this.formatId,
    this.resolution,
    required this.url,
    required this.protocol,
  });

  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    return VideoFormat(
      formatId: json['formatId'] as String,
      resolution: json['resolution'] as String?,
      url: json['url'] as String,
      protocol: json['protocol'] as String,
    );
  }

  // A helper to get a display-friendly name for the button
  String get displayName {
    if (resolution != null) {
      return resolution!;
    }
    // Fallback to formatId if resolution is not available
    return formatId.replaceFirst('mp4-', '').toUpperCase();
  }
}
