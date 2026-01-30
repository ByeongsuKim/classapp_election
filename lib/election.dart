import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:classapp_election/widgets/candidate_layout.dart';
import 'package:classapp_election/result.dart';

class ElectionPage extends StatefulWidget {
  final String title;
  final int totalVoteCount;
  final int columnCount;
  final String voteDisplayOption;
  final List<List<TextEditingController>> descriptionColumns;
  final List<List<TextEditingController>> candidateColumns;
  final List<Color> candidateColors;
  final List<Color> fontColors;

  const ElectionPage({
    super.key,
    required this.title,
    required this.totalVoteCount,
    required this.columnCount,
    required this.voteDisplayOption,
    required this.descriptionColumns,
    required this.candidateColumns,
    required this.candidateColors,
    required this.fontColors,
  });

  @override
  State<ElectionPage> createState() => _ElectionPageState();
}

class _ElectionPageState extends State<ElectionPage> {
  final FocusNode _focusNode = FocusNode();
  int currentVoterIndex = 1;
  int currentColumnStep = 0;
  bool _isProcessing = false;
  bool _showOverlay = false;
  String _overlayMessage = "";
  List<bool> _columnCompleted = [];
  List<int?> _selectedCandidateIndices = [];
  List<List<int>> _accumulatedVotes = [];

  // 타이머 관련 변수
  Timer? _finalizeTimer;
  int _countdownSeconds = 3;

  @override
  void initState() {
    super.initState();
    _columnCompleted = List.generate(widget.columnCount, (_) => false);
    _selectedCandidateIndices = List.generate(widget.columnCount, (_) => null);
    _accumulatedVotes = List.generate(
      widget.columnCount,
          (i) => List.generate(widget.candidateColumns[i].length, (_) => 0),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("==============================");
      print("📢 election.dart 페이지로 전환됨");
      print("==============================");
      _focusNode.requestFocus();
      _startNewVoterProcess(currentVoterIndex);
    });
  }

  @override
  void dispose() {
    _finalizeTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startNewVoterProcess(int index) async {
    if (!mounted) return;
    setState(() {
      _overlayMessage = "$index번째 투표를 시작하세요";
      _showOverlay = true;
      _isProcessing = true;
      _columnCompleted = List.generate(widget.columnCount, (_) => false);
      _selectedCandidateIndices = List.generate(widget.columnCount, (_) => null);
      currentColumnStep = 0;
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _showOverlay = false;
        _isProcessing = false;
      });
    }
  }

  // ESC 키를 통한 직전 투표 취소 로직
  void _undoLastStep() async {
    // 0단이거나 전체 오버레이 중이면 무시 (단, 마지막 단 완료 후 대기 상태일 때는 허용해야 함)
    if (currentColumnStep <= 0) return;

    // 만약 마지막 확정 대기 타이머가 돌고 있었다면 중단
    if (_finalizeTimer != null) {
      _finalizeTimer!.cancel();
      _finalizeTimer = null;
    }

    setState(() {
      _isProcessing = true;
      currentColumnStep--; // 이전 단으로 후퇴

      // 누적 투표수에서 차감 (아직 확정 전이지만 로직상 선차감)
      int? lastSelectedIdx = _selectedCandidateIndices[currentColumnStep];
      if (lastSelectedIdx != null) {
        _accumulatedVotes[currentColumnStep][lastSelectedIdx]--;
      }

      _columnCompleted[currentColumnStep] = false;
      _selectedCandidateIndices[currentColumnStep] = null;
      _overlayMessage = "이전 투표를 다시 하세요.";
      _showOverlay = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _showOverlay = false;
        _isProcessing = false;
      });
    }
  }

  void _processVote(int colIdx, int candiIdx) {
    if (_isProcessing || _showOverlay || _columnCompleted[colIdx] || colIdx != currentColumnStep) return;

    setState(() {
      _isProcessing = true;
      _selectedCandidateIndices[colIdx] = candiIdx;
    });

    if (widget.voteDisplayOption.contains('선택 보이게')) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _finalizeStep(colIdx);
      });
    } else {
      _finalizeStep(colIdx);
    }
  }

  void _finalizeStep(int colIdx) async {
    if (!mounted) return;

    int? selectedIdx = _selectedCandidateIndices[colIdx];
    if (selectedIdx != null) {
      _accumulatedVotes[colIdx][selectedIdx]++;
    }

    setState(() {
      _columnCompleted[colIdx] = true;
      currentColumnStep++;
      _isProcessing = false;
    });

    // 모든 단의 투표가 완료된 경우 -> 3초 대기 애니메이션 시작
    if (currentColumnStep >= widget.columnCount) {
      _startFinalizeCountdown();
    }
  }

  // 마지막 투표 확정 전 3초 카운트다운 시작
  void _startFinalizeCountdown() {
    _countdownSeconds = 3;
    _finalizeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          timer.cancel();
          _finalizeTimer = null;
          _moveToNextVoter(); // 3초 경과 시 다음 투표자로 이동
        }
      });
    });
  }

  // 실제로 투표를 마감하고 다음 투표자로 넘어가는 로직
  void _moveToNextVoter() async {
    _printCurrentVoteResults();

    setState(() {
      _overlayMessage = "$currentVoterIndex번째 투표가 모두 확정되었습니다";
      _showOverlay = true;
      _isProcessing = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (currentVoterIndex < widget.totalVoteCount) {
      setState(() => currentVoterIndex++);
      _startNewVoterProcess(currentVoterIndex);
    } else {
      setState(() => _overlayMessage = "모든 투표가 완료되었습니다.\n투표결과를 보시겠습니까?");
    }
  }

  void _printCurrentVoteResults() {
    print("\n========================================");
    print("📊 [제 $currentVoterIndex회차 확정] 누적 투표 현황");
    print("========================================");

    for (int i = 0; i < widget.columnCount; i++) {
      print("[${i + 1}단 후보자 현황]");
      for (int j = 0; j < widget.candidateColumns[i].length; j++) {
        String name = widget.candidateColumns[i][j].text;
        int voteCount = _accumulatedVotes[i][j];
        print("- $name : $voteCount표");
      }
      print("----------------------------------------");
    }
    print("========================================\n");
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          // ESC 키 감지 시 재투표 실행
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _undoLastStep();
            return;
          }

          // 숫자키 입력
          if (!_isProcessing && !_showOverlay && widget.voteDisplayOption.contains('키보드')) {
            final key = event.logicalKey;
            int? pressedNum;

            if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) pressedNum = 0;
            else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) pressedNum = 1;
            else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) pressedNum = 2;
            else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) pressedNum = 3;
            else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) pressedNum = 4;
            else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) pressedNum = 5;
            else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) pressedNum = 6;
            else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) pressedNum = 7;
            else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) pressedNum = 8;

            if (pressedNum != null &&
                currentColumnStep < widget.candidateColumns.length &&
                pressedNum < widget.candidateColumns[currentColumnStep].length) {
              _processVote(currentColumnStep, pressedNum);
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
          toolbarHeight: 70,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(widget.columnCount, (colIdx) {
                      bool isActive = colIdx == currentColumnStep;
                      bool isCompleted = _columnCompleted[colIdx];

                      return Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildColumnWidget(colIdx, isActive),
                            if (isActive)
                              Positioned(
                                top: 20,
                                left: 0,
                                right: 0,
                                child: const Center(
                                  child: Text(
                                    "▼ 투표를 해주세요",
                                    style: TextStyle(
                                      color: Colors.lightBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            if (!isActive && !isCompleted) _buildInactiveOverlay(),
                            if (isCompleted) _buildColumnCompleteOverlay(colIdx),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
            if (_showOverlay) _buildFullOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnWidget(int colIdx, bool isActive) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: Colors.lightBlueAccent, width: 6.0)
            : Border.all(color: Colors.transparent, width: 6.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 25),
          Text(
            widget.descriptionColumns[colIdx].map((e) => e.text).join(" "),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF134686)),
          ),
          const Divider(height: 30),
          Expanded(
            child: CandidateLayout(
              columnIndex: colIdx,
              columnCount: widget.columnCount,
              candidates: widget.candidateColumns[colIdx],
              backgroundColor: widget.candidateColors[colIdx],
              fontColor: widget.fontColors[colIdx],
              isVotingMode: true,
              selectedCandidateIndex: _selectedCandidateIndices[colIdx],
              showSelectionBorder: widget.voteDisplayOption.contains('선택 보이게'),
              onTapCandidate: (candiIdx) {
                if (widget.voteDisplayOption.contains('터치')) {
                  _processVote(colIdx, candiIdx);
                }
              },
              onDeleteCandidate: (index) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveOverlay() {
    return Positioned.fill(
      child: Container(
        margin: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildColumnCompleteOverlay(int colIdx) {
    // 마지막 단인 경우 카운트다운 메시지 표시 여부 결정
    bool isLastStep = colIdx == widget.columnCount - 1;

    return Positioned.fill(
      child: Container(
        margin: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "투표를 완료하였습니다",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "다시 투표하려면 ESC키를 누르세요",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),
              if (isLastStep && _finalizeTimer != null)
                Text(
                  "$_countdownSeconds초 후 자동 확정됩니다.",
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullOverlay() {
    // "투표결과" 라는 키워드가 포함되어 있는지 확인하여 버튼 표시 여부를 결정합니다.
    bool showResultButton = _overlayMessage.contains("투표결과");

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF134686).withOpacity(0.95),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. 아이콘 표시 로직: "투표결과" 메시지가 아닐 때만 아이콘을 표시합니다.
              if (!showResultButton)
                const Icon(Icons.how_to_vote, size: 100, color: Colors.white),

              if (!showResultButton) const SizedBox(height: 20),

              // 2. 메시지 텍스트: 항상 표시됩니다.
              Text(
                _overlayMessage,
                textAlign: TextAlign.center, // 텍스트를 중앙 정렬합니다.
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                  height: 1.4, // 줄 간격을 조절합니다.
                ),
              ),

              const SizedBox(height: 40), // 메시지와 버튼/인디케이터 사이 간격

              // 3. 버튼 또는 로딩 인디케이터 표시 로직
              if (showResultButton)
              // "투표결과" 메시지일 때 [투표 결과 보기] 버튼을 표시합니다.
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // 버튼 배경색
                    foregroundColor: const Color(0xFF134686), // 버튼 글자색
                    padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    print("결과 보기 버튼 클릭됨! Result 페이지로 이동");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultPage(
                          // ResultPage에 필요한 모든 정보를 전달합니다.
                          title: widget.title,
                          columnCount: widget.columnCount,
                          descriptionColumns: widget.descriptionColumns,
                          candidateColumns: widget.candidateColumns,
                          candidateColors: widget.candidateColors,
                          fontColors: widget.fontColors,
                          voteResults: _accumulatedVotes, // 최종 투표 결과를 전달
                        ),
                      ),
                    );
                  },
                  child: const Text("투표 결과 보기"),
                )
              else if (_isProcessing)
              // "투표결과" 메시지가 아니고, 처리 중일 때 로딩 인디케이터를 표시합니다.
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBottomBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("현재 $currentVoterIndex번째 투표",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF134686))),
          const SizedBox(width: 20),
          Text("/ 전체 ${widget.totalVoteCount}명",
              style: const TextStyle(fontSize: 22, color: Colors.grey)),
        ],
      ),
    );
  }
}
