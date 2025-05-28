import 'dart:math';
import '../models/artwork.dart';

class ArtworkService {
  static final Random _random = Random();
  static final List<Artwork> _artworks = [];

  // 샘플 아트워크 데이터 가져오기
  static List<Artwork> getArtworks() {
    if (_artworks.isEmpty) {
      // 초기 데이터가 없으면 샘플 데이터 생성
      _generateSampleArtworks();
    }
    return _artworks;
  }

  // 샘플 아트워크 데이터 생성
  static void _generateSampleArtworks() {
    final List<String> sampleTitles = [
      '바다의 꿈',
      '도시의 야경',
      '봄의 숲',
      '별이 빛나는 밤',
      '산 위의 일출',
      '가을 풍경',
      '추상화: 감정',
      '꽃 정원',
    ];

    final List<String> sampleDescriptions = [
      '푸른 바다와 하늘이 만나는 지점을 표현한 작품입니다. 물감의 다양한 푸른 색조가 평온함을 전달합니다.',
      '빌딩의 불빛이 밤하늘에 반사되는 아름다운 도시의 야경을 표현했습니다.',
      '봄에 피어나는 신록과 꽃들로 가득한 숲의 아름다움을 담았습니다.',
      '밤하늘의 별들과 달빛이 어우러진 풍경화입니다. 반 고흐에게서 영감을 받았습니다.',
      '이른 아침, 산 위로 떠오르는 태양의 장엄한 모습을 표현했습니다.',
      '붉고 노란 단풍이 물든 가을 풍경을 담은 작품입니다.',
      '다양한 색상과 형태로 인간의 복잡한 감정을 표현한 추상화입니다.',
      '다양한 색상의 꽃들로 가득한 정원을 담은 밝고 화사한 작품입니다.',
    ];

    final List<String> sampleArtists = [
      '김민수',
      '이지영',
      '박준호',
      '최수진',
      '정태영',
      '한미영',
      '송재현',
      '윤지원',
    ];

    final List<List<String>> sampleCategories = [
      ['풍경화', '바다'],
      ['풍경화', '도시'],
      ['풍경화', '자연'],
      ['풍경화', '밤'],
      ['풍경화', '일출'],
      ['풍경화', '가을'],
      ['추상화', '현대미술'],
      ['정물화', '꽃'],
    ];

    final List<String> sampleImageUrls = [
      'assets/images/11.jpg',
      'assets/images/22.jpg',
      'assets/images/33.jpg',
      'assets/images/post1.jpg',
      'assets/images/낙엽사진.jpeg',
      'assets/images/파스타.jpg',
      'assets/images/11.jpg', // 이미지 부족으로 일부 반복
      'assets/images/22.jpg',
    ];

    // 현재 시간부터 30일 후까지의 랜덤 경매 종료일 설정
    for (int i = 0; i < 8; i++) {
      final DateTime createdAt = DateTime.now().subtract(Duration(days: _random.nextInt(10)));
      final DateTime auctionEndDate = DateTime.now().add(Duration(days: _random.nextInt(30) + 1));
      final int index = i % sampleTitles.length;
      
      final artwork = Artwork(
        id: 'artwork_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: sampleTitles[index],
        description: sampleDescriptions[index],
        imageUrl: sampleImageUrls[index],
        startingPrice: 50.0 + _random.nextDouble() * 950.0,
        artist: sampleArtists[index],
        createdAt: createdAt,
        auctionEndDate: auctionEndDate,
        categories: sampleCategories[index],
        ownerUserId: 'user_${_random.nextInt(100)}',
      );
      
      // 일부 아트워크에만 입찰 내역 추가
      if (_random.nextBool()) {
        final numBids = _random.nextInt(5) + 1;
        double currentBid = artwork.startingPrice;
        
        for (int j = 0; j < numBids; j++) {
          // 이전 입찰가보다 5~20% 높게 설정
          currentBid += currentBid * (0.05 + _random.nextDouble() * 0.15);
          
          final bid = Bid(
            userId: 'user_${_random.nextInt(100)}',
            userName: '입찰자_${_random.nextInt(1000)}',
            amount: currentBid,
            bidTime: createdAt.add(Duration(hours: _random.nextInt(24 * 10))),
          );
          
          // 입찰 추가
          _artworks.add(artwork.addBid(bid));
        }
      } else {
        _artworks.add(artwork);
      }
    }
    
    // 경매 종료일 기준 정렬 (가까운 종료일 순)
    _artworks.sort((a, b) => a.auctionEndDate.compareTo(b.auctionEndDate));
  }

  // 새 아트워크 추가
  static void addArtwork(Artwork artwork) {
    _artworks.add(artwork);
    // 경매 종료일 기준 정렬
    _artworks.sort((a, b) => a.auctionEndDate.compareTo(b.auctionEndDate));
  }

  // 아트워크 수정
  static void updateArtwork(Artwork updatedArtwork) {
    final index = _artworks.indexWhere((artwork) => artwork.id == updatedArtwork.id);
    if (index != -1) {
      _artworks[index] = updatedArtwork;
    }
  }

  // 아트워크에 입찰
  static bool placeBid(String artworkId, Bid newBid) {
    try {
      final index = _artworks.indexWhere((artwork) => artwork.id == artworkId);
      if (index != -1) {
        final updatedArtwork = _artworks[index].addBid(newBid);
        _artworks[index] = updatedArtwork;
        return true;
      }
      return false;
    } catch (e) {
      print('입찰 오류: ${e.toString()}');
      return false;
    }
  }

  // 아트워크 삭제
  static void deleteArtwork(String id) {
    _artworks.removeWhere((artwork) => artwork.id == id);
  }
} 