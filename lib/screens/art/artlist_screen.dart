import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import dart:async for Timer
import '../../models/post.dart';

class ArtListScreen extends StatefulWidget {
  const ArtListScreen({super.key});

  @override
  State<ArtListScreen> createState() => _ArtListScreenState();
}

class _ArtListScreenState extends State<ArtListScreen> with TickerProviderStateMixin {
  static const String baseUrl = "http://10.100.204.189:8080/ourlog";
  static const int artworksPerPage = 16;

  List<Post> artworks = [];
  bool isLoading = true;
  String sortType = 'popular'; // 'popular' or 'latest'
  int currentPage = 1;
  String searchInput = "";
  String searchTerm = "";
  int totalPages = 1;
  int? loggedInUserId;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  Timer? _timer; // Add Timer instance
  OverlayEntry? _overlayEntry; // Add OverlayEntry instance
  Timer? _modalTimer; // 모달창 타이머
  late AnimationController _fadeController; // Change to late
  late Animation<double> _fadeAnimation; // Change to late

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedPage();
    fetchArtworks();
    _startTimer(); // Start the timer
    _initFadeController(); // Initialize the fade controller
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _timer?.cancel(); // Cancel the timer
    _fadeController.dispose(); // Dispose the fade controller
    _modalTimer?.cancel(); // 모달 타이머 해제
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Trigger a rebuild to update time display
      setState(() {});
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      try {
        final user = jsonDecode(userData);
        if (user['userId'] != null) {
          setState(() {
            loggedInUserId = user['userId'];
          });
        }
      } catch (e) {
        debugPrint("사용자 데이터 파싱 실패: $e");
      }
    }
  }

  Future<void> _loadSavedPage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getString('artworkListPage');
    if (savedPage != null) {
      final pageNumber = int.tryParse(savedPage);
      if (pageNumber != null && pageNumber >= 1) {
        setState(() {
          currentPage = pageNumber;
        });
      }
      await prefs.remove('artworkListPage');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchArtworks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final headers = await _getHeaders();
      final params = {
        'page': currentPage.toString(),
        'size': artworksPerPage.toString(),
        'boardNo': '5',
        'type': 't',
        'keyword': searchTerm,
      };

      final uri = Uri.parse('$baseUrl/post/list').replace(queryParameters: params);
      debugPrint('API 요청 URL: $uri');
      debugPrint('API 요청 헤더: $headers');

      final response = await http.get(uri, headers: headers);
      debugPrint('API 응답 상태 코드: ${response.statusCode}');
      debugPrint('API 응답 본문: ${response.body}');

      if (response.statusCode == 403) {
        // 토큰 제거 및 로그인 페이지로 이동
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      if (response.statusCode != 200) {
        throw Exception('서버 오류: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['pageResultDTO'] == null) {
        throw Exception('잘못된 응답 형식');
      }

      final pageResultDTO = data['pageResultDTO'];
      final List<dynamic> dtoList = pageResultDTO['dtoList'] ?? [];
      debugPrint('불러온 게시글 수: ${dtoList.length}');

      // 각 게시글의 최신 좋아요 수와 사용자의 좋아요 상태를 가져옵니다
      final updatedArtworks = await Future.wait(
        dtoList.map((item) async {
          final post = Post.fromJson(item);

          // 최신 좋아요 수 가져오기
          try {
            final countResponse = await http.get(
              Uri.parse('$baseUrl/favorites/count/${post.postId}'),
              headers: headers,
            );
            if (countResponse.statusCode == 200) {
              final countData = jsonDecode(countResponse.body);
              post.favoriteCnt = countData is num ? countData : countData['count'];
            }
          } catch (e) {
            debugPrint('좋아요 수 불러오기 실패: $e');
          }

          // 사용자의 좋아요 상태 가져오기
          if (loggedInUserId != null) {
            try {
              final likeStatusResponse = await http.get(
                Uri.parse('$baseUrl/favorites/$loggedInUserId/${post.postId}'),
                headers: headers,
              );
              if (likeStatusResponse.statusCode == 200) {
                post.liked = jsonDecode(likeStatusResponse.body) == true;
              }
            } catch (e) {
              debugPrint('좋아요 상태 불러오기 실패: $e');
            }
          }

          return post;
        }),
      );

      setState(() {
        if (currentPage == 1) {
          artworks = updatedArtworks;
        } else {
          artworks.addAll(updatedArtworks);
        }
        totalPages = pageResultDTO['totalPage'] ?? 1;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('작품을 불러오는 중 오류가 발생했습니다: $e');
      setState(() {
        if (currentPage == 1) {
          artworks = [];
        }
        totalPages = 1;
        isLoading = false;
      });
    }
  }

  Future<void> handleLikeToggle(int postId) async {
    if (loggedInUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    // Optimistic UI 업데이트
    setState(() {
      artworks = artworks.map((artwork) {
        if (artwork.postId == postId) {
          final newLiked = !artwork.liked;
          final newFavoriteCnt = (artwork.favoriteCnt ?? 0) + (newLiked ? 1 : -1);
          return Post(
            postId: artwork.postId,
            userId: artwork.userId,
            title: artwork.title,
            content: artwork.content,
            nickname: artwork.nickname,
            fileName: artwork.fileName,
            boardNo: artwork.boardNo,
            views: artwork.views,
            tag: artwork.tag,
            thumbnailImagePath: artwork.thumbnailImagePath,
            resizedImagePath: artwork.resizedImagePath,
            originImagePath: artwork.originImagePath,
            followers: artwork.followers,
            downloads: artwork.downloads,
            favoriteCnt: newFavoriteCnt,
            tradeDTO: artwork.tradeDTO,
            pictureDTOList: artwork.pictureDTOList,
            profileImage: artwork.profileImage,
            replyCnt: artwork.replyCnt,
            regDate: artwork.regDate,
            modDate: artwork.modDate,
            liked: newLiked,
          );
        }
        return artwork;
      }).toList();
    });

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/toggle'),
        headers: headers,
        body: jsonEncode({
          'userId': loggedInUserId,
          'postId': postId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('서버 응답 오류');
      }

      final data = jsonDecode(response.body);
      if (data['favoriteCount'] != null) {
        setState(() {
          artworks = artworks.map((artwork) {
            if (artwork.postId == postId) {
              return Post(
                postId: artwork.postId,
                userId: artwork.userId,
                title: artwork.title,
                content: artwork.content,
                nickname: artwork.nickname,
                fileName: artwork.fileName,
                boardNo: artwork.boardNo,
                views: artwork.views,
                tag: artwork.tag,
                thumbnailImagePath: artwork.thumbnailImagePath,
                resizedImagePath: artwork.resizedImagePath,
                originImagePath: artwork.originImagePath,
                followers: artwork.followers,
                downloads: artwork.downloads,
                favoriteCnt: data['favoriteCount'],
                tradeDTO: artwork.tradeDTO,
                pictureDTOList: artwork.pictureDTOList,
                profileImage: artwork.profileImage,
                replyCnt: artwork.replyCnt,
                regDate: artwork.regDate,
                modDate: artwork.modDate,
                liked: data['favorited'],
              );
            }
            return artwork;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('좋아요 처리 실패: $e');
      // 실패 시 optimistic rollback
      setState(() {
        artworks = artworks.map((artwork) {
          if (artwork.postId == postId) {
            final rolledBackLiked = !artwork.liked;
            final rolledBackFavoriteCnt = (artwork.favoriteCnt ?? 0) + (rolledBackLiked ? 1 : -1);
            return Post(
              postId: artwork.postId,
              userId: artwork.userId,
              title: artwork.title,
              content: artwork.content,
              nickname: artwork.nickname,
              fileName: artwork.fileName,
              boardNo: artwork.boardNo,
              views: artwork.views,
              tag: artwork.tag,
              thumbnailImagePath: artwork.thumbnailImagePath,
              resizedImagePath: artwork.resizedImagePath,
              originImagePath: artwork.originImagePath,
              followers: artwork.followers,
              downloads: artwork.downloads,
              favoriteCnt: rolledBackFavoriteCnt,
              tradeDTO: artwork.tradeDTO,
              pictureDTOList: artwork.pictureDTOList,
              profileImage: artwork.profileImage,
              replyCnt: artwork.replyCnt,
              regDate: artwork.regDate,
              modDate: artwork.modDate,
              liked: rolledBackLiked,
            );
          }
          return artwork;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요 처리에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  void handleSearchSubmit() {
    setState(() {
      searchTerm = searchInput;
      currentPage = 1;
    });
    fetchArtworks();
  }

  void handlePageClick(int page) {
    // Remove pagination logic
  }

  void handleRegisterClick() {
    Navigator.pushNamed(context, '/art/register');
  }

  void handleArtworkClick(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('artworkListPage', currentPage.toString());
    // This will now be handled by the detail button in the overlay
    // Navigator.pushNamed(context, '/Art/$postId');
  }

  void _initFadeController() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
  }

  void _showExpandedArtworkOverlay(BuildContext context, Post artwork, GlobalKey imageKey) {
    // Find the render box of the image to get its size and position
    final RenderBox? renderBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return; // Return if render box is not found

    // 모달 내 경매 남은 시간 실시간 갱신용 State 변수
    String timeLeft = artwork.getTimeLeft();
    bool isAuctionEnded = artwork.isEnded || (artwork.tradeDTO?.tradeStatus ?? true);

    _overlayEntry = OverlayEntry(
      builder: (context) => FadeTransition( // Add FadeTransition for the overlay
        opacity: _fadeAnimation, // Use the fade animation controller
        child: GestureDetector(
          onTap: () {
            // Dismiss overlay on tap outside info area
            _hideExpandedArtworkOverlay(); // Use a new hide function
          },
          child: Container(
            color: Colors.black.withOpacity(0.8), // Dark semi-transparent background
            child: Center(
              child: SingleChildScrollView( // Allow scrolling if content overflows
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Center content vertically
                  crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
                  children: [
                    // Expanded Image using Hero animation
                    Hero(
                      tag: 'artwork-${artwork.postId}',
                      child: Material(
                        color: Colors.transparent,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              artwork.getImageUrl(),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.width * 0.6,
                                color: Colors.grey[300],
                                child: const Center(child: Text('이미지 없음')),
                              ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  'OurLog',
                                  style: TextStyle(
                                    fontFamily: 'NanumSquareNeo',
                                    fontSize: 48,
                                    color: Colors.white.withOpacity(0.35),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // Spacing between image and info
                    // Artwork Info Board
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9, // Info board width
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800], // Dark background for info
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setStateInOverlay) {
                          // 모달 타이머 시작 (최초 1회만)
                          _modalTimer?.cancel();
                          _modalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                            if (_overlayEntry == null) {
                              _modalTimer?.cancel();
                              return;
                            }
                            // 경매 종료 조건: isEnded 또는 tradeStatus==true
                            final ended = artwork.isEnded || (artwork.tradeDTO?.tradeStatus ?? true);
                            if (!ended) {
                              setStateInOverlay(() {
                                timeLeft = artwork.getTimeLeft();
                                isAuctionEnded = ended;
                              });
                            } else {
                              setStateInOverlay(() {
                                isAuctionEnded = true;
                              });
                              _modalTimer?.cancel();
                            }
                          });
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(artwork.title ?? '제목 없음', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                              const SizedBox(height: 8),
                              Text('작가: ${artwork.nickname ?? '알 수 없음'}', style: TextStyle(color: Colors.white70, fontSize: 14, decoration: TextDecoration.none)),
                              const SizedBox(height: 8),
                              if (artwork.tradeDTO != null) ...[
                                Text(
                                  '현재가: ${(artwork.tradeDTO!.highestBid ?? artwork.tradeDTO!.startPrice)?.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                isAuctionEnded
                                  ? const Text(
                                      '경매 종료',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        decoration: TextDecoration.none,
                                      ),
                                    )
                                  : Text(
                                      '남은 시간: $timeLeft',
                                      style: TextStyle(
                                        color: artwork.isEndingSoon ? Colors.red : Colors.white,
                                        fontSize: 14,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                              ] else
                                const Text(
                                  '경매 정보 없음',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Center(
                                child: Row( // Row로 감싸서 버튼 두 개를 나란히 배치
                                  mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
                                  children: [
                                    ElevatedButton(
                                      child: const Text('상세보기', style: TextStyle(color: Colors.white)),
                                      onPressed: () {
                                        _modalTimer?.cancel();
                                        _fadeController.reverse().then((_) {
                                          _overlayEntry?.remove();
                                          _overlayEntry = null;
                                          Navigator.pushNamed(
                                            context,
                                            '/Art',
                                            arguments: artwork.postId.toString(),
                                          );
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 16), // 두 버튼 사이 간격 추가
                                    ElevatedButton( // 닫기 버튼 추가
                                      child: const Text('닫기', style: TextStyle(color: Colors.black87)),
                                      onPressed: () {
                                        _hideExpandedArtworkOverlay(); // 모달 닫는 함수 호출
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[300], // 회색 배경
                                        foregroundColor: Colors.black87, // 검정색 글씨
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Use an AnimationController for fade transition
    _fadeController.forward();

    // Insert the overlay when the image is tapped
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  void _hideExpandedArtworkOverlay() {
    _modalTimer?.cancel();
    _fadeController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  List<Post> getSortedArtworks() {
    if (sortType == 'popular') {
      return [...artworks]..sort((a, b) => (b.favoriteCnt ?? 0) - (a.favoriteCnt ?? 0));
    }
    return [...artworks]..sort((a, b) {
      final timeA = a.tradeDTO?.startBidTime?.millisecondsSinceEpoch ?? 0;
      final timeB = b.tradeDTO?.startBidTime?.millisecondsSinceEpoch ?? 0;
      return timeB - timeA;
    });
  }

  List<Post> getFilteredArtworks() {
    final sorted = getSortedArtworks();
    // Filter only boardNo 5. Null check for boardNo.
    final onlyArt = sorted.where((art) => art.boardNo == 5).toList();
    if (searchTerm.isEmpty) return onlyArt;
    return onlyArt.where((art) =>
    (art.title?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
        (art.nickname?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredArtworks = getFilteredArtworks();

    if (isLoading && artworks.isEmpty) { // Show loading only on initial load
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredArtworks.isEmpty && !isLoading) { // Show "no artworks" only if no artworks and not loading
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('등록된 작품이 없습니다.'),
              if (searchTerm.isNotEmpty) Text("'$searchTerm'에 대한 검색 결과가 없습니다."),
              ElevatedButton(
                onPressed: handleRegisterClick,
                child: const Text('새 작품 등록하기'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_overlayEntry != null) {
          _hideExpandedArtworkOverlay();
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '검색어를 입력하세요...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    searchInput = "";
                    searchTerm = "";
                  });
                  if (!_isSearching) {
                    fetchArtworks();
                  } else {
                    setState(() {
                      _isSearching = true;
                      searchTerm = "";
                      currentPage = 1;
                    });
                    fetchArtworks();
                  }
                },
              ),
            ),
            onSubmitted: (_) {
              setState(() {
                searchInput = _searchController.text;
                _isSearching = false;
              });
              handleSearchSubmit();
            },
          )
              : const Text('아트 게시판'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    searchInput = "";
                    searchTerm = "";
                    currentPage = 1;
                    fetchArtworks();
                  }
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              sortType = 'popular';
                              currentPage = 1;
                            });
                            fetchArtworks();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sortType == 'popular' ? Colors.orange : Colors.white,
                            foregroundColor: sortType == 'popular' ? Colors.white : Colors.black,
                          ),
                          child: const Text('인기순'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              sortType = 'latest';
                              currentPage = 1;
                            });
                            fetchArtworks();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sortType == 'latest' ? Colors.orange : Colors.white,
                            foregroundColor: sortType == 'latest' ? Colors.white : Colors.black,
                          ),
                          child: const Text('최신순'),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: handleRegisterClick,
                      child: const Text('아트 등록'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      currentPage = 1;
                    });
                    await fetchArtworks();
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // Changed from 3 to 2
                              childAspectRatio: 0.7, // Adjusted from 0.8 to 0.7 to reduce vertical space
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredArtworks.length,
                            itemBuilder: (context, index) {
                              final artwork = filteredArtworks[index];
                              final GlobalKey _imageKey = GlobalKey(); // Add GlobalKey for the image
                              return GestureDetector(
                                // Changed onTap to show overlay
                                onTap: () => _showExpandedArtworkOverlay(context, artwork, _imageKey),
                                child: Card(
                                  // Removed Column, directly using Stack for larger image area
                                  clipBehavior: Clip.antiAlias, // Clip content to card shape
                                  child: Stack(
                                    children: [
                                      Positioned.fill( // Make image fill the Card
                                        child: Hero(
                                          tag: 'artwork-${artwork.postId}', // Unique tag for Hero animation
                                          child: Image.network(
                                            artwork.getImageUrl(),
                                            key: _imageKey, // Assign the GlobalKey to the image
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[300],
                                              child: const Center(child: Text('이미지 없음')),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => handleLikeToggle(artwork.postId!),
                                          child: Text(
                                            artwork.liked ? '🧡' : '🤍',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 0),
                                                  blurRadius: 3.0,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          if (currentPage < totalPages)
                            ElevatedButton(
                              onPressed: isLoading
                                  ? null // Disable button while loading
                                  : () {
                                setState(() {
                                  currentPage++;
                                });
                                fetchArtworks();
                              },
                              child: isLoading
                                  ? const CircularProgressIndicator() // Show loading indicator on button
                                  : const Text('더보기'),
                            ),
                          if (isLoading && artworks.isNotEmpty) // Show loading indicator below button if loading more
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 