
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_source.dart';
import '../models/video_info.dart';
import '../services/scraping_service.dart';
import 'player_screen.dart';

class VideoListScreen extends StatefulWidget {
  final VideoSource source;

  const VideoListScreen({super.key, required this.source});

  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  late Future<List<VideoInfo>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() {
    final scrapingService = Provider.of<ScrapingService>(context, listen: false);
    _videosFuture = scrapingService.fetchVideoList(widget.source);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.source.name),
      ),
      body: FutureBuilder<List<VideoInfo>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No videos found. The site structure may have changed.'));
          } else {
            final videos = snapshot.data!;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(detailPageUrl: video.detailPageUrl),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.network(video.coverUrl, fit: BoxFit.cover, height: 180, errorBuilder: (c, o, s) => const Icon(Icons.error, size: 180)),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(video.duration, textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
