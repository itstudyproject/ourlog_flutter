import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> filteredFaqs = [];

  final List<Map<String, String>> allFaqs = [
    {
      'question': '로그인이 안 돼요.',
      'answer': '로그인이 안 되는 경우, 아이디와 비밀번호를 다시 한 번 확인해주세요. 계속해서 로그인이 안 되는 경우 고객센터로 문의해주시기 바랍니다.'
    },
    {
      'question': '비밀번호를 잊어버렸어요.',
      'answer': '로그인 페이지에서 [비밀번호 찾기]를 클릭하시면 가입하신 이메일로 임시 비밀번호를 발송해드립니다.'
    },
    {
      'question': '회원가입은 어떻게 하나요?',
      'answer': '메인 페이지에서 [회원가입] 버튼을 클릭하시면 회원가입 페이지로 이동합니다. 필요한 정보를 입력하시고 [가입하기] 버튼을 클릭하시면 회원가입이 완료됩니다.'
    },
    {
      'question': '회원탈퇴는 어떻게 하나요?',
      'answer': '회원탈퇴는 로그인 후 [마이페이지]-[회원탈퇴]에서 할 수 있습니다. 탈퇴와 동시에 회원님의 개인정보 및 모든 이용정보가 즉시 삭제되며 절대 복구할 수 없으니 탈퇴시 유의해주시기 바랍니다.'
    },
  ];

  // 각 FAQ가 펼쳐져 있는지 여부를 관리하는 리스트
  List<bool> expandedList = [];

  @override
  void initState() {
    super.initState();
    filteredFaqs = List.from(allFaqs);
    expandedList = List.filled(filteredFaqs.length, false);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      filteredFaqs = allFaqs
          .where((faq) =>
      faq['question']!.toLowerCase().contains(keyword) ||
          faq['answer']!.toLowerCase().contains(keyword))
          .toList();

      // 검색 결과에 맞춰 expandedList도 다시 생성
      expandedList = List.filled(filteredFaqs.length, false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _searchController.text.trim();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 검색창
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '검색어를 입력하세요',
                  hintStyle: const TextStyle(color: Colors.white54),
                  suffixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 검색창 밑에 "자주 묻는 질문" 텍스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '자주 묻는 질문',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10), // 텍스트와 선 사이 간격 조절용
              Container(
                height: 2,
                width: double.infinity,
                color: Colors.orange,

                  ),
                ],
              ),
            ),

            // 검색어 텍스트 (검색어가 있을 때만 표시)
            if (keyword.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '“$keyword”에 대한 검색 결과',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

            // FAQ 목록 또는 검색 결과 없음
            Expanded(
              child: filteredFaqs.isEmpty
                  ? const Center(
                child: Text(
                  '검색 결과가 없습니다.',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredFaqs.length,
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  final isExpanded = expandedList[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white54, width: 1.2),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          expandedList[index] = !expandedList[index];
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    faq['question']!,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            AnimatedCrossFade(
                              firstChild: Container(),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  faq['answer']!,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              crossFadeState: isExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
