import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'file_saver_util.dart';

// 위젯 및 유틸리티
import 'package:classapp_election/widgets/candidate_layout.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

// 이미지 저장 라이브러리 (모바일/웹용)
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file_plus/open_file_plus.dart';
// 이미지 저장 라이브러리 (데스크톱용)
//import 'package:file_selector/file_selector.dart';
// lib/result.dart 상단 수정
import 'package:classapp_election/file_saver_util.dart'; // 파일명에 맞춰 수정
// 웹 전용 다운로드 기능을 위해 dart:html import
// import 'dart:html' as html;

class ResultPage extends StatefulWidget {
  final String title;
  final int columnCount;
  final List<List<TextEditingController>> descriptionColumns;
  final List<List<TextEditingController>> candidateColumns;
  final List<Color> candidateColors;
  final List<Color> fontColors;
  final List<List<int>> voteResults;

  const ResultPage({
    super.key,
    required this.title,
    required this.columnCount,
    required this.descriptionColumns,
    required this.candidateColumns,
    required this.candidateColors,
    required this.fontColors,
    required this.voteResults,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  String? _savedImagePath;
  bool _isProcessing = false;
  late int _totalVoteCount;


  @override
  void initState() {
    super.initState();
    _totalVoteCount = widget.voteResults.expand((votes) => votes).fold(0, (sum, item) => sum + item);
    // 페이지가 로드될 때 콘솔에 득표수를 출력
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("\n========================================");
      print("📊 [Result.dart] 최종 결과 데이터");
      print("========================================");
      for (int i = 0; i < widget.columnCount; i++) {
        print("[${i + 1}단 후보자 득표 현황]");
        for (int j = 0; j < widget.candidateColumns[i].length; j++) {
          String name = widget.candidateColumns[i][j].text;
          int vote = widget.voteResults[i][j];
          print("- $name : $vote표");
        }
        if (i < widget.columnCount - 1) {
          print("----------------------------------------");
        }
      }
      print("========================================\n");
    });

  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(delay: const Duration(milliseconds: 100));
      if (imageBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지 캡처에 실패했습니다.')));
        return;
      }

      final String timeStamp = DateFormat('yyMMdd_HHmmss').format(DateTime.now());
      final String fileName = '${widget.title}_$timeStamp.png';

      // [수정] 웹과 데스크톱 로직을 통합 함수 하나로 교체합니다.
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {

        // 통합된 함수 호출 (함수명이 saveImage인지 saveImageInDesktop인지 util 파일과 맞추세요)
        await saveImage(context, imageBytes, fileName);

      } else {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 권한이 거부되었습니다.')));
          return;
        }

        final result = await ImageGallerySaver.saveImage(imageBytes, name: fileName, quality: 95);
        if (result['isSuccess']) {
          setState(() {
            _savedImagePath = result['filePath'].toString().replaceFirst('file://', '');
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('결과가 갤러리에 저장되었습니다.'),
              action: SnackBarAction(label: '보기', onPressed: _openSavedImage),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지 저장에 실패했습니다.')));
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openSavedImage() async {
    if (kIsWeb || _savedImagePath == null) return;
    await OpenFile.open(_savedImagePath!);
  }

  @override
  Widget build(BuildContext context) {
    _totalVoteCount = widget.voteResults.expand((votes) => votes).fold(0, (sum, item) => sum + item);

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          // 자동 뒤로 가기 버튼 비활성화
          automaticallyImplyLeading: false,

          // [핵심 수정] ElevatedButton을 사용하여 아이콘과 텍스트가 포함된 버튼 생성
          leading: Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // main.dart를 제외한 모든 이전 페이지를 스택에서 제거하고, main.dart로 이동
                Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
              },
              icon: const Icon(Icons.arrow_back, size: 16), // 화살표 아이콘
              label: const Text(
                '처음으로',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6), // 버튼 배경색
                foregroundColor: Colors.black87, // 아이콘 및 텍스트 색상
                elevation: 2, // 살짝 떠 보이는 그림자 효과
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 버튼 모서리를 둥글게
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10), // 내부 여백
              ),
            ),
          ),
          // leadingWidth를 설정하여 버튼이 잘리지 않도록 공간을 충분히 확보합니다.
          leadingWidth: 120,

          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text("${widget.title} 최종 결과", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
          toolbarHeight: 70,
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildResultBottomBar(),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(widget.columnCount, (colIdx) {
          final int candidateCount = widget.candidateColumns[colIdx].length;

          // --- [추가] 해당 단(Column)에서 1위 찾기 로직 ---
          int maxVotes = -1;
          String winnerName = "";
          bool isTie = false;
          int winnerCount = 0;

          for (int j = 0; j < widget.voteResults[colIdx].length; j++) {
            int currentVotes = widget.voteResults[colIdx][j];
            if (currentVotes > maxVotes) {
              maxVotes = currentVotes;
              winnerName = widget.candidateColumns[colIdx][j].text;
              winnerCount = 1;
              isTie = false;
            } else if (currentVotes == maxVotes && maxVotes > 0) {
              winnerCount++;
              isTie = true;
            }
          }
          // ------------------------------------------

          return Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 0),
                    child: Stack(
                      clipBehavior: Clip.none, // 컨테이너 밖으로 나가도 잘리지
                      children: [
                        // 1. 부제목(설명) 텍스트 - 원래 위치 유지
                        Column(
                          children: [
                            Text(
                              widget.descriptionColumns[colIdx].map((e) => e.text).join(" "),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF134686)
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Divider(height: 30),
                          ],
                        ),
                        // --- [추가] 1위 정보 표시 영역 ---
                        // 2. 1위 정보 표시 영역 - Stack의 Positioned를 사용하여 절대 위치에 배치
                        if (maxVotes > 0)
                          Positioned(
                            top: -15, // 위로 살짝 띄움 (원하는 높이로 조절 가능)
                            right: 0,  // 우측 상단 끝에 배치
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF134686).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF134686).withOpacity(0.3)),
                              ),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: "최다득표자  ",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.normal
                                      ),
                                    ),
                                    TextSpan(
                                      text: isTie ? "$winnerCount명 공동" : winnerName,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF134686),
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                      ],
                    ),
                  ),
                  Expanded(
                    child: FractionallySizedBox(
                      // [핵심 수정] 1인 1표제일 경우에만 너비 조절 로직이 적용되도록 수정
                      widthFactor: widget.columnCount == 1 && candidateCount == 1 ? 0.5 : 1.0,
                      child: CandidateLayout(
                        columnIndex: colIdx,
                        columnCount: widget.columnCount,
                        candidates: widget.candidateColumns[colIdx],
                        backgroundColor: widget.candidateColors[colIdx],
                        fontColor: widget.fontColors[colIdx],
                        onTapCandidate: (index) {},
                        onDeleteCandidate: (index) {},
                        isVotingMode: false,
                        isResultMode: true,
                        voteResults: widget.voteResults[colIdx],
                        totalVoterCount: _totalVoteCount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResultBottomBar() {
    int voterCount = 0;
    if (widget.columnCount > 0) {
      voterCount = _totalVoteCount ~/ widget.columnCount;
    }

    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.columnCount > 1 ? '총 투표자' : '총 투표 수',
                style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              if (widget.columnCount > 1)
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold,fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily),
                    children: [
                      TextSpan(text: '$voterCount명, '),
                      TextSpan(
                        text: '각 ${widget.columnCount}표씩 ',
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                      TextSpan(text: '총 $_totalVoteCount표'),
                    ],
                  ),
                )
              else
                Text('$_totalVoteCount 표', style: const TextStyle(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('투표 상태', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text('투표 완료', style: TextStyle(fontSize: 32, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 20),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: (_isProcessing) ? null : ((kIsWeb || _savedImagePath == null) ? _captureAndProcess : _openSavedImage),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: (_savedImagePath != null && !kIsWeb) ? Colors.green : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: _isProcessing
                        ? const Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0)))
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon((kIsWeb) ? Icons.download : (_savedImagePath == null ? Icons.camera_alt : Icons.open_in_new), color: Colors.white, size: 30),
                        const SizedBox(height: 4),
                        Text((kIsWeb) ? '저장' : (_savedImagePath == null ? '저장' : '열기'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
