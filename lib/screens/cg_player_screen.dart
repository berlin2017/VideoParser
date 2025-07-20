import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/scraping_service.dart';
import 'player_screen.dart'; // Re-use the focusable widgets

class CGPlayerScreen extends StatefulWidget {
  final String detailPageUrl;
  final String videoTitle;

  const CGPlayerScreen({super.key, required this.detailPageUrl, required this.videoTitle});

  @override
  _CGPlayerScreenState createState() => _CGPlayerScreenState();
}

class _CGPlayerScreenState extends State<CGPlayerScreen> {
  late final Player _player = Player(
    configuration: const PlayerConfiguration(protocolWhitelist: [
      'file', 'http', 'https', 'tcp', 'tls', 'crypto', 'hls', 'applehttp', 'udp', 'rtp', 'data', 'httpproxy'
    ]),
  );
  late final VideoController _videoController;
  final ScrapingService _scrapingService = ScrapingService();

  Future<List<String>>? _videoUrlsFuture;
  List<String> _videoUrls = [];
  int _currentSourceIndex = 0;
  final List<double> _speeds = [0.5, 1.0, 1.5, 2.0];
  int _currentSpeedIndex = 1;
  String? _playerError;

  bool _isOverlayVisible = true;
  Timer? _hideOverlayTimer;

  @override
  void initState() {
    super.initState();
    _videoController = VideoController(_player);
    _videoUrlsFuture = _scrapingService.fetchVideoDetail(widget.detailPageUrl, '51cg');

    _videoUrlsFuture?.then((urls) {
      if (kDebugMode) {
        print('--- 51CG Video URLs ---');
        print(urls);
        print('--- End 51CG Video URLs ---');
      }
      if (urls.isNotEmpty) {
        setState(() => _videoUrls = urls);
        _playCurrentSource();
      }
    }).catchError((e) {
      if (mounted) setState(() => _playerError = e.toString());
    });

    _startHideOverlayTimer();
  }

  void _startHideOverlayTimer() {
    _hideOverlayTimer?.cancel();
    _hideOverlayTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _player.state.playing) {
        setState(() => _isOverlayVisible = false);
      }
    });
  }

  void _toggleOverlay() {
    if (mounted) {
      setState(() => _isOverlayVisible = !_isOverlayVisible);
      if (_isOverlayVisible) _startHideOverlayTimer();
    }
  }

  Future<void> _playCurrentSource() async {
    if (_videoUrls.isEmpty) return;
    final url = _videoUrls[_currentSourceIndex];
    await _player.open(Media(url), play: true);
    if (mounted) setState(() {});
  }

  void _switchToNextSource() {
    if (_videoUrls.length > 1) {
      setState(() {
        _currentSourceIndex = (_currentSourceIndex + 1) % _videoUrls.length;
      });
      _playCurrentSource();
    }
  }

  void _switchToNextSpeed() {
    setState(() {
      _currentSpeedIndex = (_currentSpeedIndex + 1) % _speeds.length;
    });
    _player.setRate(_speeds[_currentSpeedIndex]);
  }

  @override
  void dispose() {
    _player.dispose();
    _hideOverlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleOverlay,
          child: FutureBuilder<List<String>>(
            future: _videoUrlsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || _playerError != null) {
                return Center(child: Text(_playerError ?? snapshot.error.toString(), style: const TextStyle(color: Colors.white)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No video sources found.', style: const TextStyle(color: Colors.white)));
              }

              return Stack(
                children: [
                  Video(controller: _videoController),
                  AnimatedOpacity(
                    opacity: _isOverlayVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildControls(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        children: [
          Row(
            children: [
              FocusableActionDetector(
                child: BackButton(color: Colors.white),
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => Navigator.pop(context)),
                },
              ),
              Expanded(
                child: Text(widget.videoTitle, style: const TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FocusableIconButton(icon: Icons.replay_10, onPressed: () {
                final currentPosition = _player.state.position;
                _player.seek(currentPosition - const Duration(seconds: 10));
              }),
              const SizedBox(width: 40),
              StreamBuilder<bool>(
                stream: _player.stream.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return FocusableIconButton(
                    icon: isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    iconSize: 64,
                    onPressed: () => _player.playOrPause(),
                  );
                },
              ),
              const SizedBox(width: 40),
              FocusableIconButton(icon: Icons.forward_10, onPressed: () {
                final currentPosition = _player.state.position;
                _player.seek(currentPosition + const Duration(seconds: 10));
              }),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    StreamBuilder<Duration>(stream: _player.stream.position, builder: (context, snapshot) => Text((snapshot.data ?? Duration.zero).toString().split('.').first.padLeft(8, '0'), style: const TextStyle(color: Colors.white))),
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: _player.stream.position,
                        builder: (context, positionSnapshot) {
                          final position = positionSnapshot.data ?? Duration.zero;
                          final duration = _player.state.duration;
                          return Slider(
                            value: position.inSeconds.toDouble(),
                            min: 0.0,
                            max: duration.inSeconds.toDouble().clamp(0.0, double.infinity),
                            onChanged: (value) => _player.seek(Duration(seconds: value.toInt())),
                          );
                        },
                      ),
                    ),
                    Text((_player.state.duration).toString().split('.').first.padLeft(8, '0'), style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FocusablePopupMenuButton<double>(
                      onSelected: (rate) => _player.setRate(rate),
                      itemBuilder: (context) => [0.5, 1.0, 1.5, 2.0].map((rate) => PopupMenuItem(value: rate, child: Text('${rate}x'))).toList(),
                      child: Row(children: [const Icon(Icons.speed, color: Colors.white), const SizedBox(width: 4), StreamBuilder<double>(stream: _player.stream.rate, builder: (context, snapshot) => Text('${snapshot.data ?? 1.0}x', style: const TextStyle(color: Colors.white)))]),
                    ),
                    if (_videoUrls.length > 1)
                      FocusablePopupMenuButton<int>(
                        onSelected: (index) {
                          setState(() => _currentSourceIndex = index);
                          _playCurrentSource();
                        },
                        itemBuilder: (context) => List.generate(_videoUrls.length, (index) => PopupMenuItem(value: index, child: Text('Source ${index + 1}'))),
                        child: Row(children: [const Icon(Icons.video_library, color: Colors.white), const SizedBox(width: 4), Text('Source ${_currentSourceIndex + 1}', style: const TextStyle(color: Colors.white))]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}