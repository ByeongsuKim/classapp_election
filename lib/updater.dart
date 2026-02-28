import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdater {
  // GitHub 사용자명과 저장소 이름으로 변경하세요.
  static const String githubUser = "ByeongsuKim";
  static const String repoName = "classapp_election";

  static Future<void> checkForUpdates(context) async {
    try {
      // 1. 현재 앱 버전 가져오기
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      Version currentVersion = Version.parse(packageInfo.version);

      // 2. GitHub 최신 릴리즈 정보 가져오기
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubUser/$repoName/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestTagName = data['v.1.0.3']; // 예: "v1.0.1"
        // 'v' 제거 후 버전 파싱
        Version latestVersion = Version.parse(latestTagName.replaceAll('v', ''));

        // 3. 버전 비교
        if (latestVersion > currentVersion) {
          _showUpdateDialog(context, latestTagName, data['html_url']);
        }
      }
    } catch (e) {
      print("업데이트 확인 중 오류 발생: $e");
    }
  }

  static void _showUpdateDialog(context, String newVersion, String downloadUrl) {
    // 여기서 AlertDialog를 띄워 사용자에게 업데이트를 권유합니다.
    // 사용자가 '업데이트' 클릭 시 launchUrl(Uri.parse(downloadUrl)) 실행
  }
}