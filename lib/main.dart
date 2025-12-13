import 'dart:async';
import 'dart:math';

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
        // 앱의 기본 폰트를 나눔스퀘어 Neo로 설정
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
  String _voteDisplayOption = '선택 보이게'; // 사용자 요청에 따라 값 변경
  String _votePolicyOption = '미투표 시 기권 처리';
  int _voteCount = 20;

  final TextEditingController _electionTitleController =
  TextEditingController();
  String _electionTitle = '';
  final TextEditingController _numberController =
  TextEditingController(text: '20');
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
                (index) => index < _candidateColumns.length
                ? _candidateColumns[index]
                : []);

        _candidateButtonColors =
            List.generate(_columnCount, (index) => _fixedButtonColors[index]);
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
        titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        contentTextStyle: const TextStyle(fontSize: 16),
        title: const Text('투표제 변경'),
        content: const Text('입력된 설명과 후보자 정보가 삭제될 수 있습니다. 계속하시겠습니까?'),
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
    if (selectedOption == '선택 보이게') {
      message = "투표자가 후보자 이름을 터치(클릭)할 때 누구를 선택했는지 화면에 표시됩니다.";
    } else {
      message = "투표자가 후보자 이름을 터치(클릭)할 때 누구를 선택했는지 화면에 표시되지 않습니다.";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
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
        titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        title: const Text('후보 등록'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '후보 이름을 입력하세요'),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _candidateColumns[columnIndex]
                    .add(TextEditingController(text: value));
              });
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소')),
          TextButton(
            onPressed: () {
              final value = controller.text;
              if (value.isNotEmpty) {
                setState(() {
                  _candidateColumns[columnIndex]
                      .add(TextEditingController(text: value));
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

  Widget _buildDescriptionItem(int columnIndex) {
    final Map<int, List<String>> exampleTexts = {
      1: ['설명 등록 (예: 1분기 반장)'],
      2: ['설명 등록 (예: 여자 부반장)', '설명 등록 (예: 남자 부반장)'],
      3: ['(예: 총무부장)', '(예: 환경부장)', '(예: 예능부장)'],
      4: ['(예: 총무부장)', '(예: 환경부장)', '(예: 예능부장)', '(예: 체육부장)'],
    };

    String currentText = _descriptionColumns[columnIndex].first.text;
    String exampleText = (exampleTexts[_columnCount] ?? ['설명 등록'])[
    columnIndex % (exampleTexts[_columnCount]?.length ?? 1)];
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
            padding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 28), // X 버튼 공간 확보
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!)),
            child: Text(
              buttonText,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.normal),
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
    final controller =
    TextEditingController(text: _descriptionColumns[columnIndex].first.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
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
                _descriptionColumns[columnIndex].first.clear(); // 텍스트 초기화
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
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateButton(
      TextEditingController controller, int columnIndex, int candidateIndex) {
    final isEditing = ValueNotifier<bool>(false);
    final focusNode = FocusNode();
    final fontColor = _fixedFontColors[columnIndex];

    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        isEditing.value = false;
      }
    });

    final buttonContent = Container(
      margin: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: _candidateButtonColors[columnIndex],
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          isEditing.value = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            focusNode.requestFocus();
            controller.selection = TextSelection(
                baseOffset: 0, extentOffset: controller.text.length);
          });
        },
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                double fontSize = constraints.maxHeight * 0.4;

                // 폰트 크기 조절 로직 (사용자 요청 반영)
                if (_columnCount == 1) {
                  if (fontSize < 35) fontSize = 35;
                } else if (_columnCount == 2) {
                  if (fontSize < 30) fontSize = 30;
                } else if (_columnCount == 3) {
                  fontSize = 25;
                } else if (_columnCount == 4) {
                  fontSize = 22;
                }

                return Center(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isEditing,
                    builder: (context, editing, child) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: editing
                            ? TextField(
                          controller: controller,
                          focusNode: focusNode,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: fontColor),
                          decoration: const InputDecoration(
                              border: InputBorder.none),
                          onSubmitted: (_) => isEditing.value = false,
                        )
                            : Text(
                          controller.text.isEmpty
                              ? '후보'
                              : controller.text,
                          style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: fontColor),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              top: 4,
              right: 4,
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
                  onPressed: () =>
                      _removeCandidate(columnIndex, candidateIndex),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (_columnCount != 1) {
      return AspectRatio(
        aspectRatio: 1 / 1,
        child: buttonContent,
      );
    }

    return buttonContent;
  }

  Widget _buildCandidateLayout(int columnIndex, BoxConstraints constraints) {
    final candidates = _candidateColumns[columnIndex];
    final totalCandidates = candidates.length;

    if (totalCandidates == 0) {
      return const SizedBox.shrink();
    }

    if (_columnCount == 1) {
      if (totalCandidates <= 2) {
        if (totalCandidates == 1) {
          return Center(
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 0.5,
              child: _buildCandidateButton(candidates.first, columnIndex, 0),
            ),
          );
        } else {
          return Center(
            child: FractionallySizedBox(
              heightFactor: 0.5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child:
                    _buildCandidateButton(candidates[0], columnIndex, 0),
                  ),
                  Expanded(
                    child:
                    _buildCandidateButton(candidates[1], columnIndex, 1),
                  ),
                ],
              ),
            ),
          );
        }
      }

      List<Widget> rows = [];
      List<int> candidatesPerRow;
      int maxItemsInRow;

      if (totalCandidates == 3) {
        return Center(
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(
                  totalCandidates,
                      (index) => Expanded(
                    child: _buildCandidateButton(
                        candidates[index], columnIndex, index),
                  )),
            ),
          ),
        );
      } else if (totalCandidates == 4) {
        candidatesPerRow = [2, 2];
        maxItemsInRow = 2;
      } else if (totalCandidates == 5) {
        candidatesPerRow = [2, 3];
        maxItemsInRow = 3;
      } else if (totalCandidates == 6) {
        candidatesPerRow = [3, 3];
        maxItemsInRow = 3;
      } else if (totalCandidates == 7) {
        candidatesPerRow = [3, 4];
        maxItemsInRow = 4;
      } else if (totalCandidates == 8) {
        candidatesPerRow = [4, 4];
        maxItemsInRow = 4;
      } else {
        int baseCount = (totalCandidates / 3).ceil();
        maxItemsInRow = baseCount;
        candidatesPerRow = [];
        int remaining = totalCandidates;
        while (remaining > 0) {
          int count = remaining >= baseCount ? baseCount : remaining;
          candidatesPerRow.add(count);
          remaining -= count;
        }
      }

      int candidateIndex = 0;
      for (int count in candidatesPerRow) {
        List<Widget> buttonsInRow = [];
        for (int i = 0; i < count; i++) {
          if (candidateIndex < totalCandidates) {
            buttonsInRow.add(Expanded(
              child: _buildCandidateButton(
                  candidates[candidateIndex], columnIndex, candidateIndex),
            ));
            candidateIndex++;
          }
        }

        if (count < maxItemsInRow) {
          int diff = maxItemsInRow - count;
          for (int i = 0; i < diff; i++) {
            if (i.isEven) {
              buttonsInRow.add(Expanded(child: Container()));
            } else {
              buttonsInRow.insert(0, Expanded(child: Container()));
            }
          }
        }
        rows.add(
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: buttonsInRow,
            ),
          ),
        );
      }
      return Column(children: rows);
    }
    // 1인 2, 3, 4투표제일 때의 레이아웃 로직 (정사각형 버튼 유지)
    else {
      List<Widget> children = [];
      for (int i = 0; i < totalCandidates; i += 2) {
        List<Widget> buttonsInRow = [];
        buttonsInRow.add(
          Expanded(
            child: _buildCandidateButton(candidates[i], columnIndex, i),
          ),
        );

        if (i + 1 < totalCandidates) {
          buttonsInRow.add(
            Expanded(
              child: _buildCandidateButton(
                  candidates[i + 1], columnIndex, i + 1),
            ),
          );
        } else {
          buttonsInRow.add(Expanded(child: Container()));
        }
        children.add(Expanded(child: Row(children: buttonsInRow)));
      }
      int rowCount = (totalCandidates / 2).ceil();
      if (rowCount < 4) {
        for (int i = 0; i < (4 - rowCount); i++) {
          children.add(Expanded(child: Container()));
        }
      }
      return Column(children: children);
    }
  }

  Widget _buildMainContent() {
    return Expanded(
      child: Row(
        children: List.generate(_columnCount, (columnIndex) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDescriptionItem(columnIndex),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add,
                              color: Colors.white, size: 16),
                          label:
                          const Text("후보 등록", style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            textStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => _showAddCandidateDialog(columnIndex),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildCandidateLayout(columnIndex, constraints);
                      },
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFD740),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFFFD740),
                padding:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: SizedBox(
                  height: 64,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 16.0),
                        Container(
                          height: 48,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButton<int>(
                            value: _columnCount,
                            underline: Container(),
                            items: {
                              1: '1인 1투표제',
                              2: '1인 2투표제',
                              3: '1인 3투표제',
                              4: '1인 4투표제',
                            }
                                .entries
                                .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _updateColumns(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 48,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButton<String>(
                            value: _voteDisplayOption,
                            underline: Container(),
                            items: ['선택 보이게', '선택 안보이게']
                                .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _voteDisplayOption = value);
                                _showVoteDisplayChangeDialog(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 48,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButton<String>(
                            value: _votePolicyOption,
                            underline: Container(),
                            items: ['미투표 시 기권 처리', '꼭 투표해야 함']
                                .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _votePolicyOption = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Text("총 투표권자 수",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove,
                                      color: Colors.white, size: 16),
                                  onPressed: () => setState(() {
                                    if (_voteCount > 1) {
                                      _voteCount--;
                                      _numberController.text =
                                          _voteCount.toString();
                                    }
                                  }),
                                ),
                                SizedBox(
                                  width: 30,
                                  child: TextField(
                                    controller: _numberController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero),
                                    onChanged: (value) => _voteCount =
                                        int.tryParse(value) ?? _voteCount,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add,
                                      color: Colors.white, size: 16),
                                  onPressed: () => setState(() {
                                    _voteCount++;
                                    _numberController.text =
                                        _voteCount.toString();
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF134686),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (!_hasCandidateData()) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    titleTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 20),
                                    contentTextStyle:
                                    const TextStyle(fontSize: 16),
                                    title: const Text('알림'),
                                    content:
                                    const Text('후보자가 등록되지 않았습니다.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('확인'))
                                    ],
                                  ),
                                );
                                return;
                              }
                              final List<List<String>> descriptions =
                              _descriptionColumns
                                  .map((col) => col
                                  .map((item) => item.text)
                                  .where((t) => t.isNotEmpty)
                                  .toList())
                                  .toList();
                              final List<List<String>> candi =
                              _candidateColumns
                                  .map((col) => col
                                  .map((item) => item.text)
                                  .where((t) => t.isNotEmpty)
                                  .toList())
                                  .toList();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ElectionPage(
                                    electionTitle: _electionTitle,
                                    voterCount: _voteCount,
                                    descriptions: descriptions,
                                    candi: candi,
                                    candidateButtonColors:
                                    _candidateButtonColors,
                                    voteDisplayOption: _voteDisplayOption, // 수정된 부분
                                  ),
                                ),
                              );
                            },
                            child: const Text('투표 시작'),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 8.0),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _electionTitleController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24.0, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration.collapsed(
                        hintText: '선거 제목을 입력하세요',
                      ),
                    ),
                  ),
                ),
              ),
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }
}
