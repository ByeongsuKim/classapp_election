// lib/saver_stub.dart

// 기본적으로는 stub_saver를 내보내고,
export 'stub_saver.dart'
// 만약 dart.io 라이브러리를 사용할 수 있는 환경(데스크톱/모바일)이라면 desktop_saver를 내보낸다.
if (dart.library.io) 'desktop_saver.dart';
