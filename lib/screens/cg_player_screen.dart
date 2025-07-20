import 'package:flutter/material.dart';
import '../models/video_format.dart' as app_models;
import '../services/scraping_service.dart';
import '../widgets/base_player_screen.dart';

class CGPlayerScreen extends StatefulWidget {
  final String detailPageUrl;
  final String videoTitle;

  const CGPlayerScreen(
      {super.key, required this.detailPageUrl, required this.videoTitle});

  @override
  _CGPlayerScreenState createState() => _CGPlayerScreenState();
}

class _CGPlayerScreenState extends State<CGPlayerScreen> {
  final ScrapingService _scrapingService = ScrapingService();
  Future<List<String>>? _videoUrlsFuture;

  @override
  void initState() {
    super.initState();
    _videoUrlsFuture =
        _scrapingService.fetchVideoDetail(widget.detailPageUrl, '51cg');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _videoUrlsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: Text(widget.videoTitle),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Text(
                snapshot.error?.toString() ??
                    "Failed to find any video sources on the page.",
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final urls = snapshot.data!;
        final formats = urls.asMap().entries.map((entry) {
          int idx = entry.key;
          String url = entry.value;
          return app_models.VideoFormat(
            formatId: 'Source ${idx + 1}',
            url: url,
            protocol: 'hls', // Assuming hls, might need adjustment
            resolution: 'Source ${idx + 1}',
          );
        }).toList();

        return BasePlayerScreen(
          videoTitle: widget.videoTitle,
          formats: formats,
          detailPageUrl: widget.detailPageUrl,
        );
      },
    );
  }
}