// lib/desktop_saver.dart
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart'; // 필수 import
import 'package:flutter/material.dart';
import 'package:open_file_plus/open_file_plus.dart';

Future<void> saveImageInDesktop(BuildContext context, Uint8List imageBytes, String fileName) async {
  // [핵심 수정] FileType 대신 XTypeGroup을 사용해야 합니다.
  final XTypeGroup typeGroup = XTypeGroup(
    label: 'images',
    extensions: <String>['png'],
  );

  // getSaveLocation 호출 시 acceptedTypeGroups 매개변수에 전달합니다.
  final FileSaveLocation? result = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: <XTypeGroup>[typeGroup],
  );

  if (result != null) {
    // 저장 로직
    final XFile imageFile = XFile.fromData(
        imageBytes,
        mimeType: 'image/png',
        name: fileName
    );

    await imageFile.saveTo(result.path);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결과가 저장되었습니다: ${result.path}'),
          action: SnackBarAction(
              label: '열기',
              onPressed: () => OpenFile.open(result.path)
          ),
        ),
      );
    }
  }
}