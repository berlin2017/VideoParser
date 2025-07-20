import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class BasePlayerScreen extends StatefulWidget {
  final List<String> videoUrls;
  final String videoTitle;

  const BasePlayerScreen({super.key, required this.videoUrls, required this.videoTitle});

  @override
  _BasePlayerScreenState createState() => _BasePlayerScreenState();
}

class _BasePlayerScreenState extends State<BasePlayerScreen> {
  late final Player _player = Player();
  late final VideoController _videoController;

  int _currentSourceIndex = 0;
  final List<double> _speeds = [0.5, 1.0, 1.5, 2.0];
  int _currentSpeedIndex = 1;
  bool _isOverlayVisible = true;
  Timer? _hideOverlayTimer;

  @override
  void initState() {
    super.initState();
    _videoController = VideoController(_player);
    _playCurrentSource();
    _startHideOverlayTimer();
  }

  Future<void> _playCurrentSource() async {
    if (widget.videoUrls.isEmpty) return;
    final url = widget.videoUrls[_currentSourceIndex];
    await _player.open(Media(url), play: true);
    if (mounted) {
      setState(() {});
    }
  }

  void _switchToNextSource() {
    if (widget.videoUrls.length > 1) {
      setState(() {
        _currentSourceIndex = (_currentSourceIndex + 1) % widget.videoUrls.length;
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
          child: Stack(
            alignment: Alignment.center,
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
                        max: duration.inSeconds.toDouble().clamp(0.0, double.infinity),
                        onChanged: (value) => _player.seek(Duration(seconds: value.toInt())),
                      );
                    },
                  ),
                ),
                Text((_player.state.duration).toString().split('.').first.padLeft(8, '0'), style: const TextStyle(color: Colors.white)),
                if (widget.videoUrls.length > 1)
                  FocusableActionDetector(
                    actions: {
                      ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => _switchToNextSource()),
                    },
                    child: TextButton(
                      onPressed: _switchToNextSource,
                      child: Text('Source (${_currentSourceIndex + 1}/${widget.videoUrls.length})'),
                    ),
                  ),
                FocusableActionDetector(
                  actions: {
                    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => _switchToNextSpeed()),
                  },
                  child: TextButton(
                    onPressed: _switchToNextSpeed,
                    child: Text('${_speeds[_currentSpeedIndex]}x'),
                  ),
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

  const FocusableIconButton({super.key, required this.icon, this.iconSize = 32, required this.onPressed});

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
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isFocused ? Colors.white.withOpacity(0.3) : Colors.transparent,
        ),
        child: IconButton(
          icon: Icon(widget.icon, color: Colors.white, size: widget.iconSize),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}