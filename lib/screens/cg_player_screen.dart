import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/cg_detail_parser_service.dart';
import 'player_screen.dart'; // Re-use the focusable widgets from player_screen

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
  final CGDetailParserService _parserService = CGDetailParserService();

  List<String> _videoUrls = [];
  int _currentSourceIndex = 0;
  String? _playerError;
  bool _isLoading = true;
  bool _isOverlayVisible = true;
  Timer? _hideOverlayTimer;

  @override
  void initState() {
    super.initState();
    _videoController = VideoController(_player);
    _loadVideoSources();
    _startHideOverlayTimer();
  }

  Future<void> _loadVideoSources() async {
    setState(() {
      _isLoading = true;
      _playerError = null;
    });
    try {
      final urls = await _parserService.parseDetailpage(widget.detailPageUrl);
      if (mounted) {
        setState(() {
          if (urls.isEmpty) {
            _playerError = "Failed to find any video sources on the page.";
          } else {
            _videoUrls = urls;
            _playCurrentSource();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _playerError = "Error loading video sources: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playCurrentSource() async {
    if (_videoUrls.isEmpty) return;
    final url = _videoUrls[_currentSourceIndex];
    await _player.open(Media(url), play: true);
    if (mounted) {
      setState(() {}); // Rebuild to update the source text
    }
  }

  void _switchToNextSource() {
    if (_videoUrls.length > 1) {
      setState(() {
        _currentSourceIndex = (_currentSourceIndex + 1) % _videoUrls.length;
      });
      _playCurrentSource();
    }
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _playerError != null
                  ? Center(child: Text(_playerError!, style: const TextStyle(color: Colors.white)))
                  : Stack(
                      children: [
                        Video(controller: _videoController),
                        AnimatedOpacity(
                          opacity: _isOverlayVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: _buildControls(context),
                        ),
                      ],
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
              if (_videoUrls.length > 1)
                FocusableActionDetector(
                  actions: {
                    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => _switchToNextSource()),
                  },
                  child: TextButton(
                    onPressed: _switchToNextSource,
                    child: Text('Switch Source (${_currentSourceIndex + 1}/${_videoUrls.length})'),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FocusableIconButton(icon: Icons.replay_10, onPressed: () {
                final currentPosition = _player.state.position;
                final newPosition = currentPosition - const Duration(seconds: 10);
                _player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
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
                final videoDuration = _player.state.duration;
                final newPosition = currentPosition + const Duration(seconds: 10);
                _player.seek(newPosition > videoDuration ? videoDuration : newPosition);
              }),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
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
                        max: duration.inSeconds.toDouble(),
                        onChanged: (value) => _player.seek(Duration(seconds: value.toInt())),
                      );
                    },
                  ),
                ),
                Text((_player.state.duration).toString().split('.').first.padLeft(8, '0'), style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}