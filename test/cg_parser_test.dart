import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_browser_app/parsers/cg_parser.dart';
import 'package:video_browser_app/models/video_info.dart';

void main() {
  test('CGParser should correctly parse the video list from 51cg.txt', () async {
    final file = File('D:/gemini project/51cg.txt');
    final htmlContent = await file.readAsString();

    final parser = CGParser();
    final videos = await parser.parse(htmlContent: htmlContent, baseUrl: 'https://case.ryhvlsd.com/');

    expect(videos, isNotEmpty, reason: 'The parser should find at least one video.');

    final firstVideo = videos.first;
    expect(firstVideo.title, isNotEmpty, reason: 'Video title should not be empty.');
    expect(firstVideo.coverUrl, isNotEmpty, reason: 'Video cover URL should not be empty.');
    expect(firstVideo.detailPageUrl, startsWith('https'), reason: 'Detail page URL should be an absolute URL.');

    // Optional: Add more specific checks if you know the exact expected values
    // expect(firstVideo.title, 'Expected Title');
    // expect(firstVideo.coverUrl, 'Expected Cover URL');
    // expect(firstVideo.detailPageUrl, 'Expected Detail Page URL');
  });
}