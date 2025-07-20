import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/video_source.dart';
import '../models/video_info.dart';
import '../services/scraping_service.dart';
import 'player_screen.dart';
import 'cg_player_screen.dart';

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

  void _navigateToPlayer(VideoInfo video) {
    if (widget.source.name == '51cg') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CGPlayerScreen(detailPageUrl: video.detailPageUrl, videoTitle: video.title)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerScreen(detailPageUrl: video.detailPageUrl)),
      );
    }
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
                    return FocusableCard(
                      video: video,
                      onTap: () => _navigateToPlayer(video),
                      onFocus: () {
                        int itemsPerRow = (MediaQuery.of(context).size.width / 400).floor().clamp(1, _videos.length);
                        int totalRows = (_videos.length / itemsPerRow).ceil();
                        int currentRow = (index / itemsPerRow).floor();

                        // Trigger load if in the last two rows
                        if (totalRows - currentRow <= 2) {
                          _loadMoreVideos();
                        }
                      },
                    );
                  },
                ),
    );
  }
}

class FocusableCard extends StatefulWidget {
  final VideoInfo video;
  final VoidCallback onTap;
  final VoidCallback onFocus;

  const FocusableCard({super.key, required this.video, required this.onTap, required this.onFocus});

  @override
  _FocusableCardState createState() => _FocusableCardState();
}

class _FocusableCardState extends State<FocusableCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (isFocused) {
        setState(() => _isFocused = isFocused);
        if (isFocused) {
          widget.onFocus();
        }
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => widget.onTap()),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: _isFocused
              ? RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3))
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.video.coverUrl.isNotEmpty)
                Image.network(
                  widget.video.coverUrl,
                  fit: BoxFit.cover,
                  headers: const {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
                  },
                  errorBuilder: (c, o, s) => const Icon(Icons.error, size: 180),
                )
              else
                Container(color: Colors.grey[800]),
              if (_isFocused)
                Container(color: Colors.black.withOpacity(0.4)),
              Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black54], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              Positioned(bottom: 8, left: 8, right: 8, child: Text(widget.video.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
              if (widget.video.duration.isNotEmpty) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: Colors.black.withOpacity(0.7), child: Text(widget.video.duration, style: const TextStyle(color: Colors.white, fontSize: 12)))),
            ],
          ),
        ),
      ),
    );
  }
}