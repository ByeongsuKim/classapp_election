// lib/stub_downloader.dart

import 'dart:typed_data';

// 웹이 아닐 때 호출될 비어있는 함수
void downloadImageInWeb(Uint8List imageBytes, String fileName) {
  // 아무것도 하지 않음. 웹이 아니므로 이 함수는 절대 실행되지 않음.
  throw UnsupportedError('Cannot download image in non-web environment.');
}
