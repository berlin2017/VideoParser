import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playback_details.dart';
import '../services/local_api_service.dart';
import '../widgets/base_player_screen.dart';

class PlayerScreen extends StatefulWidget {
  final String detailPageUrl;

  const PlayerScreen({super.key, required this.detailPageUrl});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late Future<PlaybackDetails> _playbackFuture;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<LocalApiService>(context, listen: false);
    _playbackFuture = apiService.fetchPlaybackDetails(widget.detailPageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlaybackDetails>(
      future: _playbackFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.formats.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text('Video'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: const Center(
              child: Text(
                "Failed to find any video sources on the page.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final details = snapshot.data!;
        return BasePlayerScreen(
          videoTitle: details.title,
          formats: details.formats,
          detailPageUrl: widget.detailPageUrl,
        );
      },
    );
  }
}