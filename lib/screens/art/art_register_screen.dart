import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/post.dart';
import '../../models/trade.dart';
import '../../models/picture.dart';
import 'art_detail_screen.dart';

class ArtRegisterScreen extends StatefulWidget {
  final Post? postData;
  final bool isReregister;

  const ArtRegisterScreen({
    super.key,
    this.postData,
    this.isReregister = false,
  });

  @override
  State<ArtRegisterScreen> createState() => _ArtRegisterScreenState();
}

class _ArtRegisterScreenState extends State<ArtRegisterScreen> {
  static const String baseUrl = "http://10.100.204.171:8080/ourlog";
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _startPriceController = TextEditingController();
  final _nowBuyController = TextEditingController();
  final _tagController = TextEditingController();

  final List<File> _imageFiles = [];
  List<String> _tags = [];
  String? _selectedThumbnailId;
  DateTime? _startTime;
  DateTime? _endTime;
  int? _userId;
  String? _nickname;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    if (widget.isReregister && widget.postData != null) {
      _initializeReregisterData();
    } else {
      _startTime = DateTime.now();
      _endTime = _startTime!.add(const Duration(days: 7));
    }
  }

  void _initializeReregisterData() {
    final post = widget.postData!;
    _titleController.text = post.title ?? '';
    _contentController.text = post.content ?? '';
    _startPriceController.text = post.tradeDTO?.startPrice?.toString() ?? '';
    _nowBuyController.text = post.tradeDTO?.nowBuy?.toString() ?? '';
    _tags = post.tag?.split(',') ?? [];
    _selectedThumbnailId = post.fileName;
    _startTime = DateTime.now();
    _endTime = _startTime!.add(const Duration(days: 7));
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      setState(() {
        _userId = prefs.getInt('userId');
        _nickname = prefs.getString('userNickname') ?? prefs.getString('userEmail') ?? '익명';
        debugPrint("[_loadUserInfo] extracted userId: $_userId, nickname: $_nickname");
      });
    } catch (e) {
      debugPrint("[_loadUserInfo] 사용자 데이터 파싱 실패: $e");
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(images.map((image) => File(image.path)));
        if (_selectedThumbnailId == null && _imageFiles.isNotEmpty) {
          _selectedThumbnailId = _imageFiles.first.path;
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (_imageFiles[index].path == _selectedThumbnailId) {
        _selectedThumbnailId = _imageFiles.length > 1 ? _imageFiles[1].path : null;
      }
      _imageFiles.removeAt(index);
    });
  }

  void _setThumbnail(String path) {
    setState(() {
      _selectedThumbnailId = path;
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // 재등록 모드일 때의 유효성 검사
    if (widget.isReregister) {
      if (widget.postData?.postId == null || widget.postData!.postId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('재등록할 게시글 정보가 없습니다.')),
        );
        return;
      }
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보가 로딩되지 않았습니다.')),
        );
        return;
      }

      final startPrice = int.tryParse(_startPriceController.text);
      final nowBuy = int.tryParse(_nowBuyController.text);

      if (startPrice == null || startPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경매 시작가를 0보다 큰 값으로 입력해주세요.')),
        );
        return;
      }
      if (nowBuy == null || nowBuy <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('즉시 구매가를 0보다 큰 값으로 입력해주세요.')),
        );
        return;
      }
      if (startPrice % 1000 != 0 || nowBuy % 1000 != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시작가와 즉시구매가는 1,000원 단위로 입력해야 합니다.')),
        );
        return;
      }
      if (startPrice > 100000000 || nowBuy > 100000000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시작가와 즉시구매가는 1억원(100,000,000) 이하로 입력해야 합니다.')),
        );
        return;
      }
      if (nowBuy < startPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('즉시구매가는 시작가보다 크거나 같아야 합니다.')),
        );
        return;
      }
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경매 시작 및 종료 시간을 설정해주세요.')),
        );
        return;
      }

      final maxEndTime = _startTime!.add(const Duration(days: 7));
      if (_endTime!.isAfter(maxEndTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경매 종료시간은 시작일로부터 최대 7일 이내여야 합니다.')),
        );
        return;
      }

      // 재등록 로직 실행
      await _handleReregister();
      return;
    }

    // 일반 등록 모드일 때의 유효성 검사
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 한 개의 이미지를 업로드해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if user info is loaded, if not, load it first
      if (_userId == null || _nickname == null) {
         await _loadUserInfo(); // Wait for user info to load
      }
      // Re-check after loading, just in case loading failed
      if (_userId == null || _nickname == null) {
         throw Exception("사용자 정보를 불러오는데 실패했습니다.");
      }

      if (widget.isReregister) {
        await _handleReregister();
      } else {
        await _handleNewRegister();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReregister() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final tradeData = {
        'postId': widget.postData!.postId,
        'sellerId': _userId,
        'startPrice': int.parse(_startPriceController.text),
        'nowBuy': int.parse(_nowBuyController.text),
        'startBidTime': _startTime!.toIso8601String(),
        'lastBidTime': _endTime!.toIso8601String(),
        'tradeStatus': false,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/trades/register'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(tradeData),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('경매가 성공적으로 재등록되었습니다!')),
          );
          Navigator.pushReplacementNamed(context, '/artWork');
        }
      } else {
        throw Exception('경매 재등록 실패: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('경매 재등록 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleNewRegister() async {
    // 새 작품 등록 로직 구현
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // 경매 시간 설정 확인
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('경매 시작/종료 시간이 설정되지 않았습니다.')),
      );
      return;
    }

    // 경매 시간 유효성 검사
    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('경매 종료 시간은 시작 시간보다 이후여야 합니다.')),
      );
      return;
    }

    print('경매 시작 시간: ${_startTime!.toIso8601String()}');
    print('경매 종료 시간: ${_endTime!.toIso8601String()}');

    // 1. 이미지 업로드
    final List<Map<String, dynamic>> uploadedImages = [];
    if (!widget.isReregister && _imageFiles.isNotEmpty) {
      for (var file in _imageFiles) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/picture/upload'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(await http.MultipartFile.fromPath('files', file.path));

        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final imageData = jsonDecode(responseData)[0];
          uploadedImages.add(imageData);
        } else {
          throw Exception('이미지 업로드 실패: ${response.statusCode}');
        }
      }
    }

    // 2. 게시글 등록
    final postData = {
      'userId': _userId,
      'title': _titleController.text,
      'content': _contentController.text,
      'nickname': _nickname,
      'boardNo': 5,
      'views': 0,
      'tag': _tags.join(','),
      'thumbnailImagePath': uploadedImages.isNotEmpty ? uploadedImages.firstWhere(
            (img) => img['uuid'] == _selectedThumbnailId,
            orElse: () => uploadedImages.first,
          )['thumbnailImagePath'] : null,
      'followers': 0,
      'downloads': 0,
      'favoriteCnt': 0,
      'replyCnt': 0,
      'fileName': uploadedImages.isNotEmpty ? uploadedImages.firstWhere(
            (img) => img['uuid'] == _selectedThumbnailId,
            orElse: () => uploadedImages.first,
          )['uuid'] : null,
      'pictureDTOList': uploadedImages,
    };

    print('게시글 등록 요청 데이터: $postData');

    final postResponse = await http.post(
      Uri.parse('$baseUrl/post/register'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(postData),
    );

    print('[_handleNewRegister] 게시글 등록 응답 상태 코드: ${postResponse.statusCode}');
    print('[_handleNewRegister] 게시글 등록 응답 본문: ${postResponse.body}');

    // 200 또는 201 상태 코드를 성공으로 간주
    if (postResponse.statusCode >= 200 && postResponse.statusCode < 300) { // 2xx 코드는 성공으로 간주
      final postId = int.parse(postResponse.body);
      print('작품 등록 성공, postId: $postId');

      // 3. 경매 등록
      final tradeData = {
        'postId': postId,
        'sellerId': _userId,
        'startPrice': int.parse(_startPriceController.text),
        'nowBuy': int.parse(_nowBuyController.text),
        'startBidTime': _startTime!.toIso8601String(),
        'lastBidTime': _endTime!.toIso8601String(),
        'tradeStatus': false,
      };

      print('[_handleNewRegister] 경매 등록 요청 데이터: $tradeData');

      try {
        final tradeResponse = await http.post(
          Uri.parse('$baseUrl/trades/register'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(tradeData),
        );

        print('[_handleNewRegister] 경매 등록 응답 상태 코드: ${tradeResponse.statusCode}');
        print('[_handleNewRegister] 경매 등록 응답 본문: ${tradeResponse.body}');

        if (tradeResponse.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('작품이 성공적으로 등록되었습니다!')),
            );
            Navigator.pushReplacementNamed(context, '/artWork');
          }
        } else {
          // 경매 등록 API에서 200 OK가 아닌 다른 상태 코드를 반환한 경우
          print('[_handleNewRegister] 경매 등록 API 오류: ${tradeResponse.statusCode} - ${tradeResponse.body}');
          throw Exception('경매 등록 실패: ${tradeResponse.statusCode} - ${tradeResponse.body}');
        }
      } catch (e) {
        // 경매 등록 요청 자체에서 예외가 발생한 경우 (네트워크 오류 등)
        print('[_handleNewRegister] 경매 등록 요청 중 예외 발생: $e');
        // 사용자에게 오류 메시지를 표시할 수 있습니다.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('경매 등록 중 오류가 발생했습니다: ${e.toString()}')),
        );
        // 여기서 throw e; 를 사용하여 상위 catch 블록으로 예외를 전파하거나,
        // 또는 여기서 예외 처리를 완료하고 함수를 종료할 수 있습니다.
        // 사용자가 게시글은 등록되었지만 경매 정보는 없는 상태를 인지해야 하므로,
        // 게시글 등록은 성공했음을 알리고 경매 등록 실패를 별도로 알리는 것이 좋습니다.
        print('게시글은 등록되었지만 경매 등록에 실패했습니다.');
        // throw e; // 예외 전파 (선택 사항)
      }
    } else {
      // 게시글 등록 API에서 200 OK가 아닌 다른 상태 코드를 반환한 경우
      print('[_handleNewRegister] 게시글 등록 API 오류: ${postResponse.statusCode} - ${postResponse.body}');
      throw Exception('게시글 등록 실패: ${postResponse.statusCode} - ${postResponse.body}');
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now().add(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[800],
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.orange,
                onPrimary: Colors.white,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: Colors.grey[800],
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final minimumEndTime = DateTime.now().add(const Duration(hours: 1));
        final maximumEndTime = DateTime.now().add(const Duration(days: 7));

        if (selectedDateTime.isAfter(minimumEndTime) && 
            selectedDateTime.isBefore(maximumEndTime.add(const Duration(minutes: 1)))) {
          setState(() {
            _endTime = selectedDateTime;
            print('경매 종료 시간이 설정되었습니다: ${_endTime!.toIso8601String()}');
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('경매 종료 시간은 현재 시간으로부터 최소 1시간, 최대 7일까지 설정할 수 있습니다.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.isReregister ? '경매 재등록' : '아트 등록',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTitleField(),
                    const SizedBox(height: 24),
                    _buildImageUploadSection(),
                    const SizedBox(height: 24),
                    _buildContentField(),
                    const SizedBox(height: 24),
                    _buildPriceFields(),
                    const SizedBox(height: 24),
                    _buildAuctionTimeSection(),
                    const SizedBox(height: 24),
                    _buildTagSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitForm,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildImageUploadSection() {
    // 재등록 모드에서는 이미지 업로드/삭제/썸네일 변경 불가, 기존 이미지만 보여줌
    if (widget.isReregister && widget.postData != null && widget.postData!.pictureDTOList != null) {
      final List<dynamic> pics = widget.postData!.pictureDTOList!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white54),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('작품 이미지 (수정 불가)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pics.length,
                itemBuilder: (context, index) {
                  final pic = pics[index];
                  final imageUrl = pic['originImagePath'] != null
                      ? 'http://10.100.204.171:8080/ourlog/picture/display/${pic['originImagePath']}'
                      : null;
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(color: Colors.grey[300], child: const Center(child: Text('이미지 없음'))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text('이미지는 수정할 수 없습니다.', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
    }
    // ... 기존 코드 (신규 등록 모드)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white54),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '작품 이미지',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_imageFiles.isNotEmpty) ...[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedThumbnailId == _imageFiles[0].path
                        ? Colors.orange
                        : Colors.white54,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        _imageFiles[0],
                        fit: BoxFit.cover,
                      ),
                      if (_selectedThumbnailId == _imageFiles[0].path)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '대표 이미지',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageFiles.length + 1,
                itemBuilder: (context, index) {
                  if (index == _imageFiles.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white54,
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                color: Colors.white70,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '이미지 추가',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: () => _setThumbnail(_imageFiles[index].path),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedThumbnailId == _imageFiles[index].path
                                      ? Colors.orange
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Image.file(
                                _imageFiles[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF0000),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
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
            ),
          ] else
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        color: Colors.white70,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '이미지를 추가해주세요',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
     // 이 메서드는 더 이상 사용되지 않습니다. 각 필드는 build 메서드에서 직접 호출됩니다.
     return Container(); // Placeholder
  }


  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white54),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeTag(tag),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                   // Removed border from the container
                ),
                child: TextFormField(
                  controller: _tagController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '태그 입력',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.black,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onFieldSubmitted: (_) => _addTag(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '추가',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '작품 제목',
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '제목을 입력해주세요';
        }
        return null;
      },
      readOnly: widget.isReregister, // 재등록 시 제목 수정 불가
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '작품 설명',
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      maxLines: 5,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '내용을 입력해주세요';
        }
        return null;
      },
      readOnly: false, // 재등록 시 설명은 수정 가능
    );
  }

  Widget _buildPriceFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _startPriceController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '시작가',
              labelStyle: const TextStyle(color: Colors.white),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
              suffixText: '원',
              suffixStyle: const TextStyle(color: Colors.white),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '시작가를 입력해주세요';
              }
              final price = int.tryParse(value);
              if (price == null || price <= 0) {
                return '0보다 큰 값을 입력해주세요';
              }
              if (price % 1000 != 0) {
                return '1,000원 단위로 입력해주세요';
              }
              if (price > 100000000) {
                return '1억원 이하로 입력해주세요';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _nowBuyController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '즉시 구매가',
              labelStyle: const TextStyle(color: Colors.white),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
              suffixText: '원',
              suffixStyle: const TextStyle(color: Colors.white),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '즉시 구매가를 입력해주세요';
              }
              final price = int.tryParse(value);
              if (price == null || price <= 0) {
                return '0보다 큰 값을 입력해주세요';
              }
              if (price % 1000 != 0) {
                return '1,000원 단위로 입력해주세요';
              }
              if (price > 100000000) {
                return '1억원 이하로 입력해주세요';
              }
              if (_startPriceController.text.isNotEmpty) {
                final startPrice = int.tryParse(_startPriceController.text);
                if (startPrice != null && price < startPrice) {
                  return '시작가보다 커야 합니다';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAuctionTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '경매 시간',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // 경매 시작 시간
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '경매 시작 시간',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('yyyy.MM.dd HH:mm').format(_startTime!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // 간격 추가
          // 경매 종료 시간
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    '경매 종료 시간',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 13,
                    ),
                  ),
                  InkWell(
                    onTap: () => _selectEndTime(context),
                    child: const Icon(Icons.calendar_today, color: Colors.orange, size: 18), // 아이콘 추가
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('yyyy.MM.dd HH:mm').format(_endTime!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons() {
     // 이 메서드는 더 이상 사용되지 않습니다.
     return Container(); // Placeholder
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _startPriceController.dispose();
    _nowBuyController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
