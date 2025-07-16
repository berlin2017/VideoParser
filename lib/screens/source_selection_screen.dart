
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'video_list_screen.dart';

class SourceSelectionScreen extends StatelessWidget {
  const SourceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Source'),
      ),
      body: ListView.builder(
        itemCount: AppConfig.videoSources.length,
        itemBuilder: (context, index) {
          final source = AppConfig.videoSources[index];
          return ListTile(
            title: Text(source.name),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoListScreen(source: source),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
