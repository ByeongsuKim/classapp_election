// lib/web_downloader.dart

import 'dart:html' as html;
import 'dart:typed_data';

// 웹 환경에서 이미지를 다운로드하는 함수
void downloadImageInWeb(Uint8List imageBytes, String fileName) {
  final blob = html.Blob([imageBytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
