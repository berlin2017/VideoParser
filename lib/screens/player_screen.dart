import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../models/playback_details.dart';
import '../models/video_format.dart' as app_models;
import '../services/local_api_service.dart';

class PlayerScreen extends StatefulWidget {
  final String detailPageUrl;

  const PlayerScreen({super.key, required this.detailPageUrl});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player = Player(
    configuration: const PlayerConfiguration(protocolWhitelist: [
      'file', 'http', 'https', 'tcp', 'tls', 'crypto', 'hls', 'applehttp', 'udp', 'rtp', 'data', 'httpproxy'
    ]),
  );
  late final VideoController _videoController;

  late Future<PlaybackDetails> _playbackFuture;
  app_models.VideoFormat? _currentFormat;
  String? _playerError;

  bool _isOverlayVisible = true;
  Timer? _hideOverlayTimer;

  @override
  void initState() {
    super.initState();
    _videoController = VideoController(_player);
    final apiService = Provider.of<LocalApiService>(context, listen: false);
    _playbackFuture = apiService.fetchPlaybackDetails(widget.detailPageUrl);

    _playbackFuture.then((details) {
      if (details.formats.isNotEmpty) {
        _playFormat(_getBestFormat(details.formats));
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

  app_models.VideoFormat _getBestFormat(List<app_models.VideoFormat> formats) {
    formats.sort((a, b) {
      int aRes = int.tryParse(a.resolution?.split('x').last ?? '0') ?? 0;
      int bRes = int.tryParse(b.resolution?.split('x').last ?? '0') ?? 0;
      return bRes.compareTo(aRes);
    });
    return formats.firstWhere((f) => f.protocol.contains('m3u8'), orElse: () => formats.first);
  }

  Future<void> _playFormat(app_models.VideoFormat format) async {
    setState(() => _currentFormat = format);
    var url = format.url;
    if (!url.startsWith('http')) {
      try {
        final detailUri = Uri.parse(widget.detailPageUrl);
        url = detailUri.resolve(url).toString();
      } catch (e) {
        if (mounted) setState(() => _playerError = 'Error resolving video URL: $e');
        return;
      }
    }
    final media = Media(url, httpHeaders: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
      'Referer': widget.detailPageUrl,
    });
    await _player.open(media, play: true);
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
          child: FutureBuilder<PlaybackDetails>(
            future: _playbackFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || _playerError != null) {
                return Center(child: Text(_playerError ?? snapshot.error.toString(), style: const TextStyle(color: Colors.white)));
              }
              if (!snapshot.hasData || snapshot.data!.formats.isEmpty) {
                return const Center(child: Text('No video sources found.', style: TextStyle(color: Colors.white)));
              }

              return Stack(
                children: [
                  Video(controller: _videoController),
                  AnimatedOpacity(
                    opacity: _isOverlayVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: CustomVideoControls(
                      player: _player,
                      details: snapshot.data!,
                      currentFormat: _currentFormat,
                      onQualityChanged: (format) => _playFormat(format),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class CustomVideoControls extends StatelessWidget {
  final Player player;
  final PlaybackDetails details;
  final app_models.VideoFormat? currentFormat;
  final ValueChanged<app_models.VideoFormat> onQualityChanged;

  const CustomVideoControls({
    super.key,
    required this.player,
    required this.details,
    required this.currentFormat,
    required this.onQualityChanged,
  });

  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first.padLeft(8, '0');
  }

  @override
  Widget build(BuildContext context) {
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
                child: Text(details.title, style: const TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FocusableIconButton(icon: Icons.replay_10, onPressed: () {
                final currentPosition = player.state.position;
                final newPosition = currentPosition - const Duration(seconds: 10);
                player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
              }),
              const SizedBox(width: 40),
              StreamBuilder<bool>(
                stream: player.stream.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return FocusableIconButton(
                    icon: isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    iconSize: 64,
                    onPressed: () => player.playOrPause(),
                  );
                },
              ),
              const SizedBox(width: 40),
              FocusableIconButton(icon: Icons.forward_10, onPressed: () {
                final currentPosition = player.state.position;
                final videoDuration = player.state.duration;
                final newPosition = currentPosition + const Duration(seconds: 10);
                player.seek(newPosition > videoDuration ? videoDuration : newPosition);
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
                    StreamBuilder<Duration>(stream: player.stream.position, builder: (context, snapshot) => Text(_formatDuration(snapshot.data ?? Duration.zero), style: const TextStyle(color: Colors.white))),
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: player.stream.position,
                        builder: (context, positionSnapshot) {
                          final position = positionSnapshot.data ?? Duration.zero;
                          final duration = player.state.duration;
                          return Slider(
                            value: position.inSeconds.toDouble(),
                            min: 0.0,
                            max: duration.inSeconds.toDouble(),
                            onChanged: (value) => player.seek(Duration(seconds: value.toInt())),
                          );
                        },
                      ),
                    ),
                    Text(_formatDuration(player.state.duration), style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FocusablePopupMenuButton<double>(
                      onSelected: (rate) => player.setRate(rate),
                      itemBuilder: (context) => [0.5, 1.0, 1.5, 2.0].map((rate) => PopupMenuItem(value: rate, child: Text('${rate}x'))).toList(),
                      child: Row(children: [const Icon(Icons.speed, color: Colors.white), const SizedBox(width: 4), StreamBuilder<double>(stream: player.stream.rate, builder: (context, snapshot) => Text('${snapshot.data ?? 1.0}x', style: const TextStyle(color: Colors.white)))]),
                    ),
                    FocusablePopupMenuButton<app_models.VideoFormat>(
                      onSelected: onQualityChanged,
                      itemBuilder: (context) => details.formats.map((format) => PopupMenuItem(value: format, child: Text(format.displayName))).toList(),
                      child: Row(children: [const Icon(Icons.hd, color: Colors.white), const SizedBox(width: 4), Text(currentFormat?.displayName ?? 'Quality', style: const TextStyle(color: Colors.white))]),
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

class FocusableIconButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;

  const FocusableIconButton({super.key, required this.icon, this.iconSize = 36, required this.onPressed});

  @override
  _FocusableIconButtonState createState() => _FocusableIconButtonState();
}

class _FocusableIconButtonState extends State<FocusableIconButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => widget.onPressed()),
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isFocused ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : Colors.transparent,
        ),
        child: IconButton(
          icon: Icon(widget.icon, color: Colors.white, size: widget.iconSize),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

class FocusablePopupMenuButton<T> extends StatefulWidget {
  final Function(T) onSelected;
  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final Widget child;

  const FocusablePopupMenuButton({super.key, required this.onSelected, required this.itemBuilder, required this.child});

  @override
  _FocusablePopupMenuButtonState<T> createState() => _FocusablePopupMenuButtonState<T>();
}

class _FocusablePopupMenuButtonState<T> extends State<FocusablePopupMenuButton<T>> {
  bool _isFocused = false;

  void _showMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    showMenu<T>(
      context: context,
      position: position,
      items: widget.itemBuilder(context),
    ).then((T? newValue) {
      if (newValue != null) {
        widget.onSelected(newValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: FocusableActionDetector(
        onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => _showMenu(context)),
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _isFocused ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : Colors.transparent,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}