// lib/stub_saver.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

// 웹/모바일 환경에서는 이 함수가 호출되지만 아무것도 하지 않습니다.
Future<void> saveImageInDesktop(BuildContext context, Uint8List imageBytes, String fileName) async {
  throw UnsupportedError('Cannot save image on this platform using desktop method.');
}
