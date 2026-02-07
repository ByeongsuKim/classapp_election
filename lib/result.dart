import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb을 사용하기 위해 추가
import 'package:flutter/material.dart';

// 위젯 및 유틸리티
import 'package:classapp_election/widgets/candidate_layout.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

// 라이브러리
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file_plus/open_file_plus.dart';

// 웹 전용 다운로드 기능을 위해 dart:html을 import (모바일에서는 무시됨)
import 'dart:html' as html;

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
  bool _isProcessing = false; // [핵심 수정] 중복 클릭 방지를 위한 상태 변수

  // [핵심 수정] 웹과 모바일 로직을 통합하고, 웹에서는 캡처와 다운로드를 한번에 처리
  Future<void> _captureAndProcess() async {
    // 중복 실행 방지
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
          delay: const Duration(milliseconds: 100));

      if (imageBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 캡처에 실패했습니다.')),
        );
        return;
      }

      final String timeStamp = DateFormat('yyMMdd_HHmmss').format(DateTime.now());
      final String fileName = '${widget.title}_$timeStamp.png';

      if (kIsWeb) {
        // 웹: 캡처 후 즉시 다운로드 실행
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

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 다운로드가 시작되었습니다.')),
        );
      } else {
        // 모바일: 갤러리에 저장
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('저장 권한이 거부되었습니다.')),
          );
          return;
        }

        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name: fileName,
          quality: 95,
        );

        if (result['isSuccess']) {
          setState(() {
            _savedImagePath =
                result['filePath'].toString().replaceFirst('file://', '');
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('결과가 갤러리에 저장되었습니다.'),
              action: SnackBarAction(
                label: '보기',
                onPressed: _openSavedImage,
              ),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 저장에 실패했습니다.')),
          );
        }
      }
    } finally {
      // 성공/실패 여부와 관계없이 처리 상태를 false로 변경
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 모바일에서만 사용하는 파일 열기 함수
  Future<void> _openSavedImage() async {
    // 웹에서는 이 함수를 직접 호출하지 않음
    if (kIsWeb || _savedImagePath == null) return;

    await OpenFile.open(_savedImagePath!);
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text("${widget.title} 최종 결과",
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
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
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: List.generate(widget.columnCount, (colIdx) {
                return Expanded(child: _buildResultColumnWidget(colIdx));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultColumnWidget(int colIdx) {
    int voterCountDenominator = 0;
    if (widget.voteResults.isNotEmpty) {
      final int totalVoteSum =
      widget.voteResults.expand((votes) => votes).fold(0, (sum, item) => sum + item);
      if (widget.columnCount > 1) {
        voterCountDenominator = totalVoteSum ~/ widget.columnCount;
      } else {
        voterCountDenominator = totalVoteSum;
      }
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 25),
          Text(
            widget.descriptionColumns[colIdx].map((e) => e.text).join(" "),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF134686)),
          ),
          const Divider(height: 30),
          Expanded(
            child: CandidateLayout(
              columnIndex: colIdx,
              columnCount: widget.columnCount,
              candidates: widget.candidateColumns[colIdx],
              backgroundColor: widget.candidateColors[colIdx],
              fontColor: widget.fontColors[colIdx],
              voteResults: widget.voteResults[colIdx],
              isResultMode: true,
              isVotingMode: false,
              totalVoterCount: voterCountDenominator,
              onTapCandidate: (candiIdx) {},
              onDeleteCandidate: (index) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBottomBar() {
    int totalVoteCount = widget.voteResults.expand((votes) => votes).fold(0, (sum, item) => sum + item);

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
              const Text('총 투표 수',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              Text('$totalVoteCount 표',
                  style: const TextStyle(
                      fontSize: 32,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('투표 상태',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  Text('투표 완료',
                      style: TextStyle(
                          fontSize: 32,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 20),
              // [핵심 수정] MouseRegion으로 GestureDetector를 감싸서 커서 변경
              MouseRegion(
                cursor: SystemMouseCursors.click, // 손가락 모양 커서 지정
                child: GestureDetector(
                  // 모바일: 저장 전/후 기능 변경, 웹: 항상 캡처&다운로드
                  onTap: (kIsWeb || _savedImagePath == null)
                      ? _captureAndProcess
                      : _openSavedImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      // 모바일에서는 저장 후 색상이 바뀌지만, 웹에서는 항상 파란색
                      color: (_savedImagePath != null && !kIsWeb)
                          ? Colors.green
                          : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isProcessing // 처리 중일 때 로딩 인디케이터 표시
                        ? const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3.0,
                          ),
                        ))
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (kIsWeb)
                              ? Icons.download
                              : (_savedImagePath == null
                              ? Icons.camera_alt
                              : Icons.open_in_new),
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (kIsWeb)
                              ? '저장'
                              : (_savedImagePath == null ? '저장' : '열기'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
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
