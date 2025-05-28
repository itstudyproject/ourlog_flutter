import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/post.dart';

class ArtListScreen extends StatefulWidget {
  const ArtListScreen({super.key});

  @override
  State<ArtListScreen> createState() => _ArtListScreenState();
}

class _ArtListScreenState extends State<ArtListScreen> {
  static const String baseUrl = "http://10.100.204.171:8080/ourlog";
  static const int artworksPerPage = 15;

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedPage();
    fetchArtworks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        artworks = updatedArtworks;
        totalPages = pageResultDTO['totalPage'] ?? 1;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('작품을 불러오는 중 오류가 발생했습니다: $e');
      setState(() {
        artworks = [];
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
    setState(() {
      currentPage = page;
    });
    fetchArtworks();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void handleRegisterClick() {
    Navigator.pushNamed(context, '/art/register');
  }

  void handleArtworkClick(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('artworkListPage', currentPage.toString());
    Navigator.pushNamed(context, '/Art/$postId');
  }

  List<Post> getSortedArtworks() {
    if (sortType == 'popular') {
      return [...artworks]..sort((a, b) => (b.favoriteCnt ?? 0) - (a.favoriteCnt ?? 0));
    }
    return [...artworks]..sort((a, b) {
      final timeA = a.tradeDTO?['startBidTime'] != null
          ? DateTime.parse(a.tradeDTO!['startBidTime']).millisecondsSinceEpoch
          : 0;
      final timeB = b.tradeDTO?['startBidTime'] != null
          ? DateTime.parse(b.tradeDTO!['startBidTime']).millisecondsSinceEpoch
          : 0;
      return timeB - timeA;
    });
  }

  List<Post> getFilteredArtworks() {
    final sorted = getSortedArtworks();
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
    final pageGroup = (currentPage - 1) ~/ 10;
    final startPage = pageGroup * 10 + 1;
    final endPage = (startPage + 9).clamp(1, totalPages);
    final pageNumbers = List.generate(endPage - startPage + 1, (i) => startPage + i);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredArtworks.isEmpty) {
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

    return Scaffold(
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
                          crossAxisCount: 3,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredArtworks.length,
                        itemBuilder: (context, index) {
                          final artwork = filteredArtworks[index];
                          return GestureDetector(
                            onTap: () => handleArtworkClick(artwork.postId!),
                            child: Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          artwork.getImageUrl(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.grey[300],
                                            child: const Center(child: Text('이미지 없음')),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => handleLikeToggle(artwork.postId!),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    artwork.liked ? '🧡' : '🤍',
                                                    style: const TextStyle(fontSize: 16),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${artwork.favoriteCnt ?? 0}',
                                                    style: const TextStyle(fontSize: 14),
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
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            artwork.title ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            artwork.nickname ?? '',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (artwork.tradeDTO != null) ...[
                                            Text(
                                              '현재가: ${(artwork.tradeDTO!['highestBid'] ?? artwork.tradeDTO!['startPrice'])?.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (artwork.tradeDTO!['tradeStatus'] == true)
                                              const Text(
                                                '경매 종료',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                ),
                                              )
                                            else if (artwork.tradeDTO!['lastBidTime'] != null)
                                              Text(
                                                artwork.getTimeLeft(),
                                                style: TextStyle(
                                                  color: artwork.isEndingSoon ? Colors.red : null,
                                                  fontSize: 14,
                                                ),
                                              ),
                                          ] else
                                            const Text(
                                              '경매 정보 없음',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: startPage > 1 ? () => handlePageClick(startPage - 10) : null,
                            icon: const Text('<<'),
                          ),
                          IconButton(
                            onPressed: currentPage > 1 ? () => handlePageClick(currentPage - 1) : null,
                            icon: const Text('<'),
                          ),
                          ...pageNumbers.map((number) => TextButton(
                            onPressed: () => handlePageClick(number),
                            style: TextButton.styleFrom(
                              backgroundColor: currentPage == number ? Colors.orange : null,
                              foregroundColor: currentPage == number ? Colors.white : null,
                            ),
                            child: Text(number.toString()),
                          )),
                          IconButton(
                            onPressed: currentPage < totalPages ? () => handlePageClick(currentPage + 1) : null,
                            icon: const Text('>'),
                          ),
                          IconButton(
                            onPressed: endPage < totalPages ? () => handlePageClick(endPage + 1) : null,
                            icon: const Text('>>'),
                          ),
                        ],
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
  }
} 