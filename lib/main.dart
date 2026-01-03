import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:classapp_election/widgets/candidate_card.dart';
import 'package:classapp_election/widgets/candidate_layout.dart';
import 'package:classapp_election/widgets/vote_setting_bar.dart';

// auto_size_text 패키지 import

// 사용자 기기 판별
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위함


import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'election.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '우리반 반장 선거',
      theme: ThemeData(
        fontFamily: 'NanumSquareNeo',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _columnCount = 1;
  String _voteDisplayOption = '(터치) 선택 보이게';
  String _votePolicyOption = '미투표 시 기권 처리';
  int _voteCount = 20;
  bool _isVotingMode = false;
  bool _isAnimating = false;
  int _currentVoterIndex = 1; // 현재 투표 중인 학생 순서(1번부터 시작)
  bool _showVoteAnimation = false; //1

  final TextEditingController _electionTitleController = TextEditingController();
  String _electionTitle = '';
  final TextEditingController _numberController = TextEditingController(text: '20');
  final List<TextEditingController> _candidateControllers = [];
  final List<FocusNode> _candidateFocusNodes = [];

  List<List<TextEditingController>> _descriptionColumns = [];
  List<List<TextEditingController>> _candidateColumns = [];

  final List<Color> _fixedButtonColors = const [
    Color(0xFFF7ED79),
    Color(0xFF8BA7F7),
    Color(0xFFD6F5B9),
    Color(0xFFDC8FD3),
  ];

  final List<Color> _fixedFontColors = const [
    Colors.black,
    Colors.white,
    Colors.black,
    Colors.white,
  ];

  List<Color> _candidateButtonColors = [];

  @override
  void initState() {
    super.initState();
    _electionTitleController.addListener(_updateBrowserTabTitle);
    _updateTitleForColumnCount(_columnCount);
    _updateColumns(_columnCount);
    _numberController.text = _voteCount.toString();
  }

  void _updateBrowserTabTitle() {
    setState(() {
      _electionTitle = _electionTitleController.text;
    });
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: _electionTitleController.text,
        primaryColor: Colors.deepPurple.value,
      ),
    );
  }

  void _updateTitleForColumnCount(int count) {
    String newTitle;
    if (count == 1) {
      newTitle = '우리반 반장 선거';
    } else if (count == 2) {
      newTitle = '우리반 부반장 선거';
    } else {
      newTitle = '우리반 부장 선거';
    }
    setState(() {
      _electionTitle = newTitle;
      _electionTitleController.text = newTitle;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBrowserTabTitle();
    });
  }

  @override
  void dispose() {
    _electionTitleController.removeListener(_updateBrowserTabTitle);
    _electionTitleController.dispose();
    _numberController.dispose();
    for (var controller in _candidateControllers) {
      controller.dispose();
    }
    for (var node in _candidateFocusNodes) {
      node.dispose();
    }
    for (var col in _descriptionColumns) {
      for (var controller in col) {
        controller.dispose();
      }
    }
    for (var col in _candidateColumns) {
      for (var controller in col) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _updateColumns(int count, {bool confirm = false}) {
    if (!confirm && _hasData()) {
      _showConfirmChangeDialog(count);
    } else {
      setState(() {
        _columnCount = count;
        if (confirm) {
          _updateTitleForColumnCount(count);
        }

        _descriptionColumns = List.generate(
            _columnCount,
                (index) => index < _descriptionColumns.length
                ? _descriptionColumns[index]
                : [TextEditingController()]);

        _candidateColumns = List.generate(
            _columnCount,
                (index) => index < _candidateColumns.length ? _candidateColumns[index] : []);

        _candidateButtonColors = List.generate(_columnCount, (index) => _fixedButtonColors[index]);
      });
    }
  }

  bool _hasData() {
    for (var col in _descriptionColumns) {
      for (var controller in col) {
        if (controller.text.isNotEmpty) return true;
      }
    }
    for (var col in _candidateColumns) {
      for (var controller in col) {
        if (controller.text.isNotEmpty) return true;
      }
    }
    return false;
  }

  bool _hasCandidateData() {
    return _candidateColumns.any((col) => col.any((c) => c.text.isNotEmpty));
  }

  void _showConfirmChangeDialog(int newCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        contentTextStyle: const TextStyle(fontSize: 16),
        title: const Text('투표제 변경'),
        content: const Text('입력된 설명과 후보자 정보가 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
              _updateColumns(newCount, confirm: true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showVoteDisplayChangeDialog(String selectedOption) {
    String message;
    if (selectedOption.contains('보이게')) {
      message = "투표자가 후보자 이름을 터치(클릭)할 때 누구를 선택했는지 화면에 표시됩니다.";
    } else {
      message = "투표자가 후보자 이름을 터치(클릭)할 때 누구를 선택했는지 화면에 표시되지 않습니다.";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        contentTextStyle: const TextStyle(fontSize: 16),
        title: Text('\'$selectedOption\' 안내'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    for (var col in _descriptionColumns) {
      for (var controller in col) {
        controller.clear();
      }
    }
    for (var col in _candidateColumns) {
      for (var controller in col) {
        controller.dispose();
      }
    }
    setState(() {
      _descriptionColumns = [];
      _candidateColumns = [];
      _candidateButtonColors = [];
    });
  }

  void _addCandidate(int columnIndex) {
    setState(() {
      _candidateColumns[columnIndex].add(TextEditingController());
    });
  }

  void _removeCandidate(int columnIndex, int candidateIndex) {
    setState(() {
      _candidateColumns[columnIndex][candidateIndex].dispose();
      _candidateColumns[columnIndex].removeAt(candidateIndex);
    });
  }

  void _showAddCandidateDialog(int columnIndex) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        title: const Text('후보 등록'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '후보 이름을 입력하세요'),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _candidateColumns[columnIndex].add(TextEditingController(text: value));
              });
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final value = controller.text;
              if (value.isNotEmpty) {
                setState(() {
                  _candidateColumns[columnIndex].add(TextEditingController(text: value));
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showEditCandidateDialog(int columnIndex, int candidateIndex) {
    final controller = TextEditingController(text: _candidateColumns[columnIndex][candidateIndex].text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        title: const Text('후보 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '후보 이름을 입력하세요'),
          onSubmitted: (value) {
            setState(() {
              _candidateColumns[columnIndex][candidateIndex].text = value;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _removeCandidate(columnIndex, candidateIndex);
              Navigator.of(context).pop();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _candidateColumns[columnIndex][candidateIndex].text = controller.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionItem(int columnIndex) {
    final Map<int, List<String>> exampleTexts = {
      1: ['설명 등록 (예: 1분기 반장)'],
      2: ['설명 등록 (예: 여자 부반장)', '설명 등록 (예: 남자 부반장)'],
      3: ['(예: 총무부장)', '(예: 환경부장)', '(예: 예능부장)'],
      4: ['(예: 총무부장)', '(예: 환경부장)', '(예: 예능부장)', '(예: 체육부장)'],
    };

    String currentText = _descriptionColumns[columnIndex].first.text;

    // --- [추가] 투표 모드일 때의 UI 처리 ---
    if (_isVotingMode) {
      return Container(
        width: double.infinity,
        height: 48, // 기존 버튼의 높이와 일관성 유지
        alignment: Alignment.center,
        child: Text(
          currentText, // 텍스트가 없으면 자동으로 빈 여백이 됨
          style: const TextStyle(
            fontSize: 18, // 투표 모드에서는 가독성을 위해 폰트를 키움
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    // ------------------------------------

    // 편집 모드 (기존 로직 유지)
    String exampleText = (exampleTexts[_columnCount] ?? ['설명 등록'])[columnIndex % (exampleTexts[_columnCount]?.length ?? 1)];
    String buttonText = currentText.isNotEmpty ? currentText : exampleText;

    if (_columnCount >= 3 && currentText.isEmpty) {
      buttonText = '설명 등록 $exampleText';
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        InkWell(
          onTap: () {
            _showEditDescriptionDialog(columnIndex);
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!)),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (currentText.isNotEmpty)
          Positioned(
            right: 20,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _descriptionColumns[columnIndex].first.clear();
                  });
                },
              ),
            ),
          ),
      ],
    );
  }


  void _showEditDescriptionDialog(int columnIndex) {
    final controller = TextEditingController(text: _descriptionColumns[columnIndex].first.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        title: const Text('설명 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '설명을 입력하세요'),
          onSubmitted: (value) {
            setState(() {
              _descriptionColumns[columnIndex].first.text = value;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _descriptionColumns[columnIndex].first.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _descriptionColumns[columnIndex].first.text = controller.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 후보자 버튼 빌드 함수
  Widget _buildCandidateButtonForMain(int columnIndex, int candidateIndex) {
    return CandidateCard(
      index: candidateIndex,
      name: _candidateColumns[columnIndex][candidateIndex].text,
      backgroundColor: _candidateButtonColors[columnIndex], // 기존 컬러 리스트 사용
      fontColor: _fixedFontColors[columnIndex],             // 기존 폰트 컬러 사용
      onTap: () => _showEditCandidateDialog(columnIndex, candidateIndex),
      onDelete: () => _removeCandidate(columnIndex, candidateIndex),
    );
  }


  // 여러 선거가 있을 때 후보를 추가할 위치를 선택하는 다이얼로그
  void _showSelectColumnToAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('어느 선거에 후보를 추가할까요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_columnCount, (i) {
            String desc = _descriptionColumns[i].first.text;
            return ListTile(
              title: Text(desc.isEmpty ? '${i + 1}번 선거' : desc),
              onTap: () {
                Navigator.pop(context);
                _showAddCandidateDialog(i);
              },
            );
          }),
        ),
      ),
    );
  }


  Widget _buildCandidateLayout(int columnIndex) {
    return CandidateLayout(
      // 중요: 리스트의 길이나 특정 값을 key로 주면 데이터 변경 시 즉각 반응합니다.
      key: ValueKey('layout_${columnIndex}_${_candidateColumns[columnIndex].length}'),
      columnIndex: columnIndex,
      columnCount: _columnCount,
      candidates: _candidateColumns[columnIndex],
      backgroundColor: _candidateButtonColors[columnIndex],
      fontColor: _fixedFontColors[columnIndex],
      isVotingMode: _isVotingMode,
      onTapCandidate: (index) {
        if (_isVotingMode) {
          // TODO: 투표 카운트 증가 로직 (예: _candidateScores[columnIndex][index]++)
          print("[$columnIndex단] ${index+1}번 후보 투표됨");
        } else {
          _showEditCandidateDialog(columnIndex, index);
        }
      },
      onDeleteCandidate: _isVotingMode
          ? (idx) {} // 투표 중엔 아무일도 안함
          : (index) => _removeCandidate(columnIndex, index),
    );
  }





  Widget _buildColumnSection(int columnIndex) {
    // 1. 현재 모든 단의 총 후보자 수 미리 계산
    int totalCandidates = _candidateColumns.fold(0, (sum, col) => sum + col.length);

    // 2. 특수 레이아웃 조건 판별
    bool isSpecialSingleLayout = (_columnCount == 1 && totalCandidates == 1);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            _buildDescriptionItem(columnIndex),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              // Row 구조를 고정하여 엔진 충돌 방지
              child: Row(
                children: [
                  // 조건에 따라 왼쪽 Spacer 활성화
                  if (isSpecialSingleLayout) const Spacer(flex: 25),

                  Expanded(
                    flex: isSpecialSingleLayout ? 50 : 100,
                    child: _buildCandidateLayout(columnIndex),
                  ),

                  // 조건에 따라 오른쪽 Spacer 활성화
                  if (isSpecialSingleLayout) const Spacer(flex: 25),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 기기 종류 판별 (웹이거나 데스크탑 OS인 경우 데스크탑으로 간주)
    final bool isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      // Stack을 사용하여 기존 UI 위에 애니메이션 레이어를 겹침
      body: Stack(
        children: [
          // 1. 메인 UI 레이어 (기존 Column 구조)
          Column(
            children: [
              // --- [1번째 줄] 설정 메뉴 영역 (투표제 & 투표 방식) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                color: Colors.white,
                height: 60,
                child: Center(
                  child: _isVotingMode
                      ? Text(
                    _electionTitleController.text,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  )
                      : IntrinsicWidth(
                    child: TextField(
                      controller: _electionTitleController,
                      textAlign: TextAlign.center,
                      cursorWidth: 0,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // --- [3번째 줄 이하] 후보자 영역 ---
              Expanded(
                child: Row(
                  children: List.generate(_columnCount, (index) {
                    return _buildColumnSection(index);
                  }),
                ),
              ),
            ],
          ),

          // 2. 투표 시작 애니메이션 레이어 (오버레이)
          if (_isAnimating)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isAnimating ? 1.0 : 0.0,
                child: Container(
                  color: const Color(0xFF134686).withOpacity(0.95), // 배경색
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.how_to_vote, size: 100, color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          "투표가 시작됩니다",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 20),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Floating 후보추가 버튼 영역 (투표 중에는 null)
      // Floating 후보추가 버튼 영역 (투표 중에는 null)
      floatingActionButton: _isVotingMode
          ? null
          : Container(
        height: 60,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: () {
            // 1. 상태 계산
            int totalCandidates = _candidateColumns.fold(0, (sum, column) => sum + column.length);
            // 조건: 1인 1투표제(_columnCount == 1)이면서 총 후보자가 1명일 때
            bool isSpecialLayout = (_columnCount == 1 && totalCandidates == 1);

            if (isSpecialLayout) {
              // 2. 특수 레이아웃: 25% (빈공간) : 50% (버튼) : 25% (빈공간)
              double screenWidth = MediaQuery.of(context).size.width - 32; // 패딩 제외
              return [
                SizedBox(width: screenWidth * 0.25), // 왼쪽 빈 공간 (25%)
                SizedBox(
                  width: screenWidth * 0.5, // 중앙 버튼 영역 (50%)
                  child: Center(
                    child: SizedBox(
                      width: 150, // 실제 버튼 크기는 고정
                      height: 52,
                      child: FloatingActionButton.extended(
                        heroTag: 'fab_column_0',
                        elevation: 4,
                        backgroundColor: const Color(0xFF134686),
                        onPressed: () => _showAddCandidateDialog(0),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('후보 추가',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.25), // 오른쪽 빈 공간 (25%)
              ];
            } else {
              // 3. 기존 레이아웃: 단 수에 맞춰 배분
              return List.generate(_columnCount, (index) {
                double sectionWidth = (MediaQuery.of(context).size.width - 32) / _columnCount;
                return SizedBox(
                  width: sectionWidth,
                  child: Center(
                    child: SizedBox(
                      width: 150,
                      height: 52,
                      child: FloatingActionButton.extended(
                        heroTag: 'fab_column_$index',
                        elevation: 4,
                        backgroundColor: const Color(0xFF134686),
                        onPressed: () => _showAddCandidateDialog(index),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('후보 추가',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                );
              });
            }
          }(), // 즉시 실행 함수로 리스트 반환
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 하단 설정 BAR 호출
      bottomNavigationBar: VoteSettingsBar(
        isDesktop: isDesktop,
        isVotingMode: _isVotingMode,
        candidateCount: _candidateColumns.fold(0, (p, c) => p + c.length),
        columnCount: _columnCount,
        voteDisplayOption: _voteDisplayOption, // 1. 현재 부모의 상태를 전달
        voteCount: _voteCount,
        numberController: _numberController,
        onColumnCountChanged: (v) => _updateColumns(v),
        onVoteDisplayChanged: (v) {
          setState(() {
            _voteDisplayOption = v; // 2. 자식(Bar)에서 바뀔 때마다 부모 상태 동기화
            print("방식 변경됨: $_voteDisplayOption"); // 디버깅용
          });
        },
        onIncrementVote: () {
          setState(() {
            _voteCount++;
            _numberController.text = _voteCount.toString();
          });
        },
        onDecrementVote: () {
          setState(() {
            if (_voteCount > 0) _voteCount--;
            _numberController.text = _voteCount.toString();
          });
        },
        onVoteCountInput: (v) => setState(() => _voteCount = int.tryParse(v) ?? 0),
        onStartVote: _candidateColumns.any((col) => col.isNotEmpty)
            ? () {
          // 1. 현재 선택된 옵션 명칭 및 설명 설정
          String methodTitle = _voteDisplayOption;
          String methodDescription = "";

          if (methodTitle.contains('(터치)') && methodTitle.contains('안보이게')) {
            methodDescription = "손으로 후보자 이름을 터치하세요. 하지만 누구를 선택했는지 표시되지는 않습니다.";
          } else if (methodTitle.contains('(터치)') && methodTitle.contains('보이게')) {
            methodDescription = "손으로 후보자 이름을 터치하세요. 선택한 후보자가 표시됩니다.";
          } else if (methodTitle.contains('(키보드)') && methodTitle.contains('안보이게')) {
            methodDescription = "키보드의 숫자키로 후보자 번호를 눌러주세요. 누구를 선택했는지 표시되지는 않습니다.";
          } else if (methodTitle.contains('(키보드)') && methodTitle.contains('보이게')) {
            methodDescription = "키보드의 숫자키로 후보자 번호를 눌러주세요. 선택한 후보자가 표시됩니다.";
          } else {
            methodDescription = "선택하신 방식에 따라 투표를 진행합니다.";
          }

          // 2. 투표 시작 전 안내 다이얼로그 표시
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) { // 다이얼로그 전용 context 이름을 dialogContext로 변경
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF134686)),
                    SizedBox(width: 10),
                    Text('투표 설정 안내', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('투표제: 1인 $_columnCount투표제', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 4),
                      child: Text('- 투표자 1명이 $_columnCount번의 투표를 실시합니다.', style: const TextStyle(color: Colors.black54)),
                    ),
                    Text('방식: $methodTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 4),
                      child: Text('- $methodDescription', style: const TextStyle(color: Colors.black54)),
                    ),
                    Text('총원: $_voteCount명', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text('- 전체 투표자는 $_voteCount명입니다.', style: const TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    // 다이얼로그를 닫을 때는 dialogContext를 사용
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('취소', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF134686),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      // [해결] 다이얼로그를 먼저 닫고
                      Navigator.of(dialogContext).pop();

                      // [중요] 다이얼로그가 닫힌 후 본체(context)가 여전히 유효한지 확인
                      if (!mounted) return;

                      // 키보드 닫기
                      FocusScope.of(context).unfocus();

                      // 애니메이션 시작
                      setState(() { _isAnimating = true; });

                      // 애니메이션 대기 (1.5초)
                      await Future.delayed(const Duration(milliseconds: 1500));

                      // [중요] 비동기 작업 후 다시 한 번 mounted 체크
                      if (!mounted) return;

                      // 상태 업데이트
                      setState(() {
                        _isVotingMode = true;
                        _isAnimating = false;
                      });

                      // 콘솔 출력
                      print("==============================");
                      print("📢 투표를 시작합니다!");
                      print("▶ 투표제 설정: 1인 $_columnCount표제");
                      print("▶ 방식 설정: $_voteDisplayOption");
                      print("▶ 후보자 수: ${_candidateColumns.fold(0, (p, c) => p + c.length)}명");
                      print("▶ 투표 참여 인원: $_voteCount");
                      print("==============================");

                      // [해결] 최종 페이지 이동 시 Scaffold의 context를 사용
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ElectionPage(
                            title: _electionTitleController.text,
                            columnCount: _columnCount,
                            totalVoteCount: _voteCount,
                            candidateColumns: _candidateColumns,
                            descriptionColumns: _descriptionColumns,
                            candidateColors: _candidateButtonColors,
                            fontColors: _fixedFontColors,
                          ),
                        ),
                      );
                    },
                    child: const Text('투표 시작'),
                  ),
                ],
              );
            },
          );
        }

            : null,
      ),
    );
  }

}

// 점선 테두리를 그리는 CustomPainter (import 'dart:ui' 필요)
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8.0),
      ));

    // PathMetric 에러를 방지하기 위해 var를 사용하거나
    // computeMetrics()가 반환하는 Iterable을 순회합니다.
    for (final measure in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measure.length) {
        canvas.drawPath(
          measure.extractPath(distance, distance + gap),
          paint,
        );
        distance += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
