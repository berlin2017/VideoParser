import 'package:flutter/material.dart';
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
  final ScrapingService _scrapingService = ScrapingService();
  final List<VideoInfo> _videos = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialVideos();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialVideos() async {
    setState(() => _isLoading = true);
    try {
      final newVideos = await _scrapingService.fetchVideoList(widget.source, page: _currentPage);
      if (mounted) {
        setState(() {
          _videos.addAll(newVideos);
          _isLoading = false;
          if (newVideos.isEmpty) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load videos: $e')));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);
    _currentPage++;

    try {
      final newVideos = await _scrapingService.fetchVideoList(widget.source, page: _currentPage);
      if (mounted) {
        setState(() {
          if (newVideos.isEmpty) {
            _hasMore = false;
          } else {
            _videos.addAll(newVideos);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Revert page number if fetch fails
      _currentPage--;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load more videos: $e')));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.source.name)),
      body: _videos.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty && !_hasMore
              ? const Center(child: Text('No videos found. The site structure may have changed.'))
              : GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _videos.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _videos.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final video = _videos[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PlayerScreen(detailPageUrl: video.detailPageUrl)),
                      ),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(video.coverUrl, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.error, size: 180)),
                            Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black54], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                            Positioned(bottom: 8, left: 8, right: 8, child: Text(video.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            if (video.duration.isNotEmpty) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: Colors.black.withOpacity(0.7), child: Text(video.duration, style: const TextStyle(color: Colors.white, fontSize: 12)))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}