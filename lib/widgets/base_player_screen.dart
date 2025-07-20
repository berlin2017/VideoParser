import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/video_format.dart' as app_models;

// Main Widget
class BasePlayerScreen extends StatefulWidget {
  final String videoTitle;
  final List<app_models.VideoFormat> formats;
  final String? detailPageUrl;

  const BasePlayerScreen({
    super.key,
    required this.videoTitle,
    required this.formats,
    this.detailPageUrl,
  });

  @override
  _BasePlayerScreenState createState() => _BasePlayerScreenState();
}

// State
class _BasePlayerScreenState extends State<BasePlayerScreen> {
  late final Player _player = Player(
    configuration: const PlayerConfiguration(
      protocolWhitelist: [
        'file',
        'http',
        'https',
        'tcp',
        'tls',
        'crypto',
        'hls',
        'applehttp',
        'udp',
        'rtp',
        'data',
        'httpproxy'
            'file',
        'http',
        'https',
        'tcp',
        'tls',
        'crypto',
        'hls',
        'applehttp',
        'udp',
        'rtp',
        'data',
        'httpproxy',
      ],
      logLevel: MPVLogLevel.debug,
    ),
  );
  late final VideoController _videoController;

  app_models.VideoFormat? _currentFormat;
  String? _playerError;
  bool _isOverlayVisible = true;
  Timer? _hideOverlayTimer;
  bool _isLandscape = true;
  bool _isPoppingWithAppBarButton = false; // Flag to differentiate pop source

  // Focus Nodes for D-Pad Navigation
  final FocusNode _mainFocusNode = FocusNode();
  final FocusNode _backButtonFocusNode = FocusNode();
  final FocusNode _replayButtonFocusNode = FocusNode();
  final FocusNode _playPauseButtonFocusNode = FocusNode();
  final FocusNode _forwardButtonFocusNode = FocusNode();
  final FocusNode _speedButtonFocusNode = FocusNode();
  final FocusNode _qualityButtonFocusNode = FocusNode();
  final FocusNode _rotationButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );
    _initializeUI();
  }

  void _initializeUI() {
    _setLandscape();

    if (widget.formats.isNotEmpty) {
      _playFormat(_getBestFormat(widget.formats));
    } else {
      if (mounted) {
        setState(() {
          _playerError = "No video formats available.";
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mainFocusNode.requestFocus();
        _playPauseButtonFocusNode.requestFocus();
        _startHideOverlayTimer();
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _hideOverlayTimer?.cancel();
    _setPortrait(); // Reset to portrait when leaving
    // Dispose all focus nodes
    _mainFocusNode.dispose();
    _backButtonFocusNode.dispose();
    _replayButtonFocusNode.dispose();
    _playPauseButtonFocusNode.dispose();
    _forwardButtonFocusNode.dispose();
    _speedButtonFocusNode.dispose();
    _qualityButtonFocusNode.dispose();
    _rotationButtonFocusNode.dispose();
    super.dispose();
  }

  // --- UI & Rotation Management ---
  void _setLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _setPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _toggleRotation() {
    _cancelHideOverlayTimer(); // D-pad like interaction
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        _setLandscape();
      } else {
        _setPortrait();
      }
    });
  }

  // --- Overlay Management ---
  void _startHideOverlayTimer() {
    _hideOverlayTimer?.cancel();
    _hideOverlayTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _player.state.playing && _isOverlayVisible) {
        setState(() {
          _isOverlayVisible = false;
          _mainFocusNode.requestFocus(); // Clear focus from controls
        });
      }
    });
  }

  void _cancelHideOverlayTimer() {
    _hideOverlayTimer?.cancel();
  }

  void _toggleOverlay({required bool isDpadInteraction}) {
    setState(() {
      _isOverlayVisible = !_isOverlayVisible;
      if (_isOverlayVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _playPauseButtonFocusNode.requestFocus();
        });
        if (isDpadInteraction) {
          _cancelHideOverlayTimer();
        } else {
          _startHideOverlayTimer();
        }
      } else {
        _mainFocusNode.requestFocus();
      }
    });
  }

  // --- Playback Management ---
  app_models.VideoFormat _getBestFormat(List<app_models.VideoFormat> formats) {
    formats.sort((a, b) {
      int aRes = int.tryParse(a.resolution?.split('x').last ?? '0') ?? 0;
      int bRes = int.tryParse(b.resolution?.split('x').last ?? '0') ?? 0;
      return bRes.compareTo(aRes);
    });
    return formats.firstWhere(
      (f) => f.protocol.contains('m3u8'),
      orElse: () => formats.first,
    );
  }

  Future<void> _playFormat(app_models.VideoFormat format) async {
    setState(() => _currentFormat = format);
    var url = format.url;
    if (!url.startsWith('http') && widget.detailPageUrl != null) {
      try {
        final detailUri = Uri.parse(widget.detailPageUrl!);
        url = detailUri.resolve(url).toString();
      } catch (e) {
        if (mounted)
          setState(() => _playerError = 'Error resolving video URL: $e');
        return;
      }
    }
    final httpHeaders = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
    };
    if (widget.detailPageUrl != null) {
      httpHeaders['Referer'] = widget.detailPageUrl!;
    }
    final media = Media(url, httpHeaders: httpHeaders);
    await _player.open(media, play: true);
  }

  void _seekForward() {
    _cancelHideOverlayTimer(); // D-pad like interaction
    final current = _player.state.position;
    final duration = _player.state.duration;
    final newPosition = current + const Duration(seconds: 10);
    _player.seek(newPosition > duration ? duration : newPosition);
  }

  void _seekBackward() {
    _cancelHideOverlayTimer(); // D-pad like interaction
    final current = _player.state.position;
    final newPosition = current - const Duration(seconds: 10);
    _player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  // --- Keyboard & D-Pad Handling ---
  void _popWithAppBarButton() {
    // Set the flag directly without setState. This ensures the value is updated
    // synchronously before _onWillPop is called.
    _isPoppingWithAppBarButton = true;
    Navigator.of(context).pop();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

    if (!_isOverlayVisible) {
      // Controls are hidden: Handle shortcuts
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _seekBackward();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _seekForward();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _toggleOverlay(isDpadInteraction: true); // Show controls, no auto-hide
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _player.playOrPause();
        _toggleOverlay(
          isDpadInteraction: false,
        ); // Show controls, with auto-hide
        return KeyEventResult.handled;
      }
    }
    // Let the focused widget handle the event if overlay is visible
    return KeyEventResult.ignored;
  }

  Future<bool> _onWillPop() async {
    if (_isPoppingWithAppBarButton) {
      return true; // Allow pop if initiated by app bar button
    }

    // TV-specific back button logic
    if (_isOverlayVisible) {
      setState(() {
        _isOverlayVisible = false;
        _mainFocusNode.requestFocus(); // Clear focus
      });
      return false; // Prevent popping the route, just hide overlay
    } else {
      return true; // Allow popping the route
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Focus(
            focusNode: _mainFocusNode,
            onKey: _handleKeyEvent,
            autofocus: true,
            child: GestureDetector(
              onTap: () => _toggleOverlay(isDpadInteraction: false),
              child: Builder(
                builder: (context) {
                  if (_playerError != null) {
                    return Center(
                      child: Text(
                        _playerError!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (widget.formats.isEmpty) {
                    return const Center(
                      child: Text(
                        'No video sources found.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Video(
                        controller: _videoController,
                        controls: NoVideoControls,
                      ),
                      AnimatedOpacity(
                        opacity: _isOverlayVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          ignoring: !_isOverlayVisible,
                          child: CustomVideoControls(
                            player: _player,
                            videoTitle: widget.videoTitle,
                            formats: widget.formats,
                            currentFormat: _currentFormat,
                            onAppBarBackPressed: _popWithAppBarButton,
                            // Pass the new method
                            onQualityChanged: (format) => _playFormat(format),
                            onToggleRotation: _toggleRotation,
                            startHideOverlayTimer: _startHideOverlayTimer,
                            cancelHideOverlayTimer: _cancelHideOverlayTimer,
                            // Pass focus nodes
                            backButtonFocusNode: _backButtonFocusNode,
                            replayButtonFocusNode: _replayButtonFocusNode,
                            playPauseButtonFocusNode: _playPauseButtonFocusNode,
                            forwardButtonFocusNode: _forwardButtonFocusNode,
                            speedButtonFocusNode: _speedButtonFocusNode,
                            qualityButtonFocusNode: _qualityButtonFocusNode,
                            rotationButtonFocusNode: _rotationButtonFocusNode,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Controls Widget
class CustomVideoControls extends StatelessWidget {
  final Player player;
  final String videoTitle;
  final List<app_models.VideoFormat> formats;
  final app_models.VideoFormat? currentFormat;
  final VoidCallback onAppBarBackPressed; // Add this
  final ValueChanged<app_models.VideoFormat> onQualityChanged;
  final VoidCallback onToggleRotation;
  final VoidCallback startHideOverlayTimer;
  final VoidCallback cancelHideOverlayTimer;

  // Focus Nodes
  final FocusNode backButtonFocusNode;
  final FocusNode replayButtonFocusNode;
  final FocusNode playPauseButtonFocusNode;
  final FocusNode forwardButtonFocusNode;
  final FocusNode speedButtonFocusNode;
  final FocusNode qualityButtonFocusNode;
  final FocusNode rotationButtonFocusNode;

  const CustomVideoControls({
    super.key,
    required this.player,
    required this.videoTitle,
    required this.formats,
    required this.currentFormat,
    required this.onAppBarBackPressed, // Add this
    required this.onQualityChanged,
    required this.onToggleRotation,
    required this.startHideOverlayTimer,
    required this.cancelHideOverlayTimer,
    required this.backButtonFocusNode,
    required this.replayButtonFocusNode,
    required this.playPauseButtonFocusNode,
    required this.forwardButtonFocusNode,
    required this.speedButtonFocusNode,
    required this.qualityButtonFocusNode,
    required this.rotationButtonFocusNode,
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
          // Top Bar: Back Button and Title
          Row(
            children: [
              _FocusableControl(
                focusNode: backButtonFocusNode,
                onPressed: onAppBarBackPressed,
                // Use the new method
                startHideOverlayTimer: startHideOverlayTimer,
                cancelHideOverlayTimer: cancelHideOverlayTimer,
                onKey: (node, event) {
                  if (event is RawKeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    playPauseButtonFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: const BackButton(color: Colors.white),
              ),
              Expanded(
                child: Text(
                  videoTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Middle Controls: Replay, Play/Pause, Forward
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FocusableControl(
                focusNode: replayButtonFocusNode,
                onPressed: () {
                  final current = player.state.position;
                  player.seek(current - const Duration(seconds: 10));
                },
                startHideOverlayTimer: startHideOverlayTimer,
                cancelHideOverlayTimer: cancelHideOverlayTimer,
                onKey: (node, event) {
                  if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    playPauseButtonFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    backButtonFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    speedButtonFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: const Icon(
                  Icons.replay_10,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 40),
              StreamBuilder<bool>(
                stream: player.stream.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return _FocusableControl(
                    focusNode: playPauseButtonFocusNode,
                    onPressed: () => player.playOrPause(),
                    startHideOverlayTimer: startHideOverlayTimer,
                    cancelHideOverlayTimer: cancelHideOverlayTimer,
                    onKey: (node, event) {
                      if (event is! RawKeyDownEvent)
                        return KeyEventResult.ignored;
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        replayButtonFocusNode.requestFocus();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowRight) {
                        forwardButtonFocusNode.requestFocus();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowUp) {
                        backButtonFocusNode.requestFocus();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowDown) {
                        speedButtonFocusNode.requestFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
              const SizedBox(width: 40),
              _FocusableControl(
                focusNode: forwardButtonFocusNode,
                onPressed: () {
                  final current = player.state.position;
                  player.seek(current + const Duration(seconds: 10));
                },
                startHideOverlayTimer: startHideOverlayTimer,
                cancelHideOverlayTimer: cancelHideOverlayTimer,
                onKey: (node, event) {
                  if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    playPauseButtonFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    backButtonFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    qualityButtonFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: const Icon(
                  Icons.forward_10,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Bottom Bar: Progress, Timers, and Settings
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    StreamBuilder<Duration>(
                      stream: player.stream.position,
                      builder: (context, snapshot) => Text(
                        _formatDuration(snapshot.data ?? Duration.zero),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: player.stream.position,
                        builder: (context, positionSnapshot) {
                          final position =
                              positionSnapshot.data ?? Duration.zero;
                          final duration = player.state.duration;
                          return Slider(
                            value: position.inSeconds.toDouble(),
                            min: 0.0,
                            max: duration.inSeconds.toDouble().isNaN
                                ? 0.0
                                : duration.inSeconds.toDouble(),
                            onChanged: (value) {
                              cancelHideOverlayTimer();
                              player.seek(Duration(seconds: value.toInt()));
                            },
                            onChangeEnd: (value) {
                              startHideOverlayTimer();
                            },
                          );
                        },
                      ),
                    ),
                    Text(
                      _formatDuration(player.state.duration),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Builder(
                      builder: (context) => _FocusableControl(
                        focusNode: speedButtonFocusNode,
                        shape: BoxShape.rectangle,
                        startHideOverlayTimer: startHideOverlayTimer,
                        cancelHideOverlayTimer: cancelHideOverlayTimer,
                        onPressed: () {
                          final RenderBox button =
                              context.findRenderObject() as RenderBox;
                          final RenderBox overlay =
                              Overlay.of(context).context.findRenderObject()
                                  as RenderBox;
                          final RelativeRect position = RelativeRect.fromRect(
                            Rect.fromPoints(
                              button.localToGlobal(
                                Offset.zero,
                                ancestor: overlay,
                              ),
                              button.localToGlobal(
                                button.size.bottomRight(Offset.zero),
                                ancestor: overlay,
                              ),
                            ),
                            Offset.zero & overlay.size,
                          );
                          showMenu<double>(
                            context: context,
                            position: position,
                            items: [0.5, 1.0, 1.5, 2.0]
                                .map(
                                  (rate) => PopupMenuItem(
                                    value: rate,
                                    child: Text('${rate}x'),
                                  ),
                                )
                                .toList(),
                          ).then((rate) {
                            if (rate != null) player.setRate(rate);
                            startHideOverlayTimer();
                          });
                        },
                        onKey: (node, event) {
                          if (event is! RawKeyDownEvent)
                            return KeyEventResult.ignored;
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            playPauseButtonFocusNode.requestFocus();
                            return KeyEventResult.handled;
                          } else if (event.logicalKey ==
                              LogicalKeyboardKey.arrowRight) {
                            qualityButtonFocusNode.requestFocus();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.speed, color: Colors.white),
                            const SizedBox(width: 4),
                            StreamBuilder<double>(
                              stream: player.stream.rate,
                              builder: (context, snapshot) => Text(
                                '${snapshot.data ?? 1.0}x',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) => _FocusableControl(
                        focusNode: qualityButtonFocusNode,
                        shape: BoxShape.rectangle,
                        startHideOverlayTimer: startHideOverlayTimer,
                        cancelHideOverlayTimer: cancelHideOverlayTimer,
                        onPressed: () {
                          final RenderBox button =
                              context.findRenderObject() as RenderBox;
                          final RenderBox overlay =
                              Overlay.of(context).context.findRenderObject()
                                  as RenderBox;
                          final RelativeRect position = RelativeRect.fromRect(
                            Rect.fromPoints(
                              button.localToGlobal(
                                Offset.zero,
                                ancestor: overlay,
                              ),
                              button.localToGlobal(
                                button.size.bottomRight(Offset.zero),
                                ancestor: overlay,
                              ),
                            ),
                            Offset.zero & overlay.size,
                          );
                          showMenu<app_models.VideoFormat>(
                            context: context,
                            position: position,
                            items: formats
                                .map(
                                  (format) => PopupMenuItem(
                                    value: format,
                                    child: Text(format.displayName),
                                  ),
                                )
                                .toList(),
                          ).then((format) {
                            if (format != null) onQualityChanged(format);
                            startHideOverlayTimer();
                          });
                        },
                        onKey: (node, event) {
                          if (event is! RawKeyDownEvent)
                            return KeyEventResult.ignored;
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            playPauseButtonFocusNode.requestFocus();
                            return KeyEventResult.handled;
                          } else if (event.logicalKey ==
                              LogicalKeyboardKey.arrowLeft) {
                            speedButtonFocusNode.requestFocus();
                            return KeyEventResult.handled;
                          } else if (event.logicalKey ==
                              LogicalKeyboardKey.arrowRight) {
                            rotationButtonFocusNode.requestFocus();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.hd, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              currentFormat?.displayName ?? 'Quality',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _FocusableControl(
                      focusNode: rotationButtonFocusNode,
                      onPressed: onToggleRotation,
                      startHideOverlayTimer: startHideOverlayTimer,
                      cancelHideOverlayTimer: cancelHideOverlayTimer,
                      onKey: (node, event) {
                        if (event is! RawKeyDownEvent)
                          return KeyEventResult.ignored;
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          playPauseButtonFocusNode.requestFocus();
                          return KeyEventResult.handled;
                        } else if (event.logicalKey ==
                            LogicalKeyboardKey.arrowLeft) {
                          qualityButtonFocusNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: const Icon(
                        Icons.screen_rotation,
                        color: Colors.white,
                        size: 28,
                      ),
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

// Helper widget for focusable controls
class _FocusableControl extends StatefulWidget {
  final FocusNode focusNode;
  final Widget child;
  final FocusOnKeyCallback? onKey;
  final VoidCallback? onPressed;
  final VoidCallback startHideOverlayTimer;
  final VoidCallback cancelHideOverlayTimer;
  final BoxShape shape;

  const _FocusableControl({
    required this.focusNode,
    required this.child,
    required this.startHideOverlayTimer,
    required this.cancelHideOverlayTimer,
    this.onKey,
    this.onPressed,
    this.shape = BoxShape.circle,
  });

  @override
  __FocusableControlState createState() => __FocusableControlState();
}

class __FocusableControlState extends State<_FocusableControl> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        if (mounted) {
          setState(() {
            _isFocused = focused;
          });
        }
      },
      onKey: (node, event) {
        if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowRight) {
          // Directional keys cancel the timer.
          widget.cancelHideOverlayTimer();
        } else if (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter) {
          // Activation keys reset the timer.
          widget.startHideOverlayTimer();
          widget.onPressed?.call();
          return KeyEventResult.handled;
        }

        // Delegate navigation to the specific onKey handler.
        return widget.onKey?.call(node, event) ?? KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          widget.onPressed?.call();
          widget.startHideOverlayTimer();
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(8)
                : null,
            color: _isFocused
                ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                : Colors.transparent,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
