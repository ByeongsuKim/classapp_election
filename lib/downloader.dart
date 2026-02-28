// lib/downloader.dart

export 'stub_downloader.dart' // 기본적으로는 stub 파일을 사용하고,
if (dart.library.html) 'web_downloader.dart'; // 만약 dart:html 라이브러리를 사용할 수 있는 환경(웹)이라면 web_downloader 파일을 사용한다.
