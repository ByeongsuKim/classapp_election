import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 확인용

// 1. 조건부 임포트: 웹과 데스크톱 라이브러리가 충돌하지 않도록 분리하여 가져옵니다.
// 윈도우/모바일용 (dart:io가 사용 가능한 환경에서만 작동)
import 'dart:io' show Platform;
// 데스크톱 파일 선택기
import 'package:file_selector/file_selector.dart';
// 파일 열기 (윈도우 전용)
import 'package:open_file_plus/open_file_plus.dart';

// 웹용 (웹 환경에서만 작동하는 전용 함수를 아래에서 사용하기 위해 분리 호출이 필요할 수 있으나,
// 현재는 하나의 파일로 통합하기 위해 전역 변수나 kIsWeb을 사용합니다.)
// 주의: dart:html은 웹 빌드 시에만 유효하므로, 실제 웹 기능을 넣으려면
// 'downloader.dart'에서 썼던 'conditional export' 방식을 사용하는 것이 가장 안전합니다.
// 여기서는 요청하신 대로 하나의 파일 안에서 최대한 안전하게 통합한 버전을 드립니다.

/// 플랫폼에 상관없이 이미지를 저장/다운로드하는 통합 함수
Future<void> saveImage(BuildContext context, Uint8List imageBytes, String fileName) async {

  // --- [1] 웹(Web) 환경 처리 ---
  if (kIsWeb) {
    debugPrint("웹 환경에서 다운로드를 시작합니다.");
    try {
      // 웹 전용 라이브러리는 런타임에 동적으로 처리하거나 별도 분리해야 하지만,
      // 웹 빌드가 주 목적이 아니라면 아래 로그로 대체하거나
      // 기존에 작성하신 web_downloader 기능을 여기에 연결하세요.
      // (직접적인 dart:html 호출은 윈도우 빌드 에러를 유발하므로
      // 웹 기능을 쓰려면 기존처럼 web_downloader.dart를 따로 두는 것이 좋습니다.)
      return;
    } catch (e) {
      debugPrint("Web download error: $e");
    }
    return;
  }

  // --- [2] 데스크톱(Windows, macOS, Linux) 환경 처리 ---
  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'images',
        extensions: <String>['png'],
      );

      // 저장 위치 선택 창 띄우기
      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );

      if (result != null) {
        final XFile imageFile = XFile.fromData(
            imageBytes,
            mimeType: 'image/png',
            name: fileName
        );

        // 파일 저장
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
    // --- [3] 모바일(Android, iOS) 환경 처리 ---
    else if (Platform.isAndroid || Platform.isIOS) {
      debugPrint("모바일 환경입니다. 별도의 갤러리 저장 로직이 필요합니다.");
    }
  } catch (e) {
    debugPrint("Desktop/Mobile save error: $e");
  }
}