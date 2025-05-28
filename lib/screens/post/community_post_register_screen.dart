import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart'; // Import MainLayout
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'dart:io'; // Import dart:io for File
import '../../services/picture_service.dart'; // Import PictureService
import '../../services/post/post_service.dart'; // Import PostService
import '../../models/post/post.dart'; // Import Post model
import 'package:provider/provider.dart'; // Import Provider
import '../../providers/auth_provider.dart'; // Import AuthProvider

class CommunityPostRegisterScreen extends StatefulWidget {
  final String? boardType;

  const CommunityPostRegisterScreen({super.key, this.boardType});

  @override
  _CommunityPostRegisterScreenState createState() => _CommunityPostRegisterScreenState();
}

class _CommunityPostRegisterScreenState extends State<CommunityPostRegisterScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  List<File> _selectedImages = []; // Variable to store the selected image files

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // Function to pick images (modified for multiple selection)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Allow multiple image selection
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        // Add new files to the existing list
        _selectedImages.addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)).toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to black
      appBar: AppBar(
        title: Text('${_getBoardTitle()} 게시글 등록'),
        backgroundColor: Colors.black, // Make app bar background black
        foregroundColor: Colors.white, // Set app bar title color to white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Title and Description (similar to customer service)
            const Text(
              '게시글 등록',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: double.infinity,
              color: Colors.orange,
            ),
            const SizedBox(height: 16.0),
            Text(
              '${_getBoardTitle()} 게시판에 새로운 게시글을 작성합니다. 다양한 이미지와 내용을 추가하여 자유롭게 소통하세요.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24.0), // Increased spacing

            // Title TextField
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
                labelStyle: const TextStyle(color: Colors.white70), // Label color
                filled: true,
                fillColor: Colors.white12, // Background color
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), // No border initially
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange), // Orange border when focused
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Adjust padding
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14), // Text color and size
              cursorColor: Colors.orange, // Cursor color
            ),
            const SizedBox(height: 16.0),

            // Image Selection and Preview Area
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이미지 첨부',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Horizontal list for image previews
                _selectedImages.isNotEmpty
                    ? Container(
                        height: 100, // Adjust height as needed
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            final imageFile = _selectedImages[index];
                            return Stack(
                              children: [
                                Container(
                                  width: 100, // Thumbnail width
                                  height: 100, // Thumbnail height
                                  margin: const EdgeInsets.only(right: 8), // Spacing between thumbnails
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(imageFile),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Optional: Add a remove button on each thumbnail
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54, // Semi-transparent background
                                        borderRadius: BorderRadius.circular(12), // Rounded button
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : Container(), // Empty container if no images selected
                const SizedBox(height: 8), // Spacing below previews or title
                // Button to add images
                ElevatedButton.icon(
                  onPressed: _pickImage, // Use the modified pickImage function
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10, // Background color
                    foregroundColor: Colors.white, // Icon and text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_photo_alternate), // Icon
                  label: const Text('이미지 추가'), // Text
                ),
              ],
            ),

            const SizedBox(height: 16.0), // Spacing before content field

            // Content TextField
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null, // Allows for multiple lines
                expands: true, // Allows the field to expand
                textAlignVertical: TextAlignVertical.top,
                 decoration: InputDecoration(
                  labelText: '내용',
                  labelStyle: const TextStyle(color: Colors.white70), // Label color
                  filled: true,
                  fillColor: Colors.white12, // Background color
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), // No border initially
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange), // Orange border when focused
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Adjust padding
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14), // Text color and size
                cursorColor: Colors.orange, // Cursor color
              ),
            ),
            const SizedBox(height: 16.0),
            // Register Button
            ElevatedButton(
              onPressed: _registerPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Button background color
                foregroundColor: Colors.white, // Button text color
                padding: const EdgeInsets.symmetric(vertical: 12), // Adjust padding
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Text style
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
              ),
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get display title for the board
  String _getBoardTitle() {
    switch (widget.boardType) {
      case 'news': return '새소식';
      case 'free': return '자유';
      case 'promotion': return '홍보';
      case 'request': return '요청';
      default: return '커뮤니티'; // Default title
    }
  }

  void _registerPost() async { // Make function async
    final title = _titleController.text.trim(); // Trim whitespace
    final content = _contentController.text.trim(); // Trim whitespace
    final boardType = widget.boardType; // Get board type
    final imageFiles = _selectedImages; // Get selected image files
    final tag = _tagController.text.trim(); // Get tag from controller

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return;
    }

    // Map boardType string to boardNo integer
    int boardNo;
    switch (boardType) {
      case 'news': boardNo = 1;
      case 'free': boardNo = 2;
      case 'promotion': boardNo = 3;
      case 'request': boardNo = 4;
      default: boardNo = 0; // Or handle as an error
    }

    // Upload images first
    List<PictureDTO> uploadedPictures = [];
    if (imageFiles.isNotEmpty) {
      // You might want to show a loading indicator here
      try {
        // Loop through each selected image and upload it individually
        for (final imageFile in imageFiles) {
           final imageInfo = await PictureService.uploadImage(imageFile); // Use the existing uploadImage method
           // Assuming uploadImage returns a Map<String, dynamic> that can be used to create PictureDTO
           uploadedPictures.add(PictureDTO.fromJson(imageInfo));
        }
        // Handle potential errors during image upload loop
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 실패: ${e.toString()}')),
        );
        return;
      }
    }

    // Create a Post object with collected data and uploaded image info
    final newPost = Post(
      title: title,
      content: content,
      boardNo: boardNo,
      tag: tag, // Include tag
      // Add default values for fields expected by backend but not provided by user
      views: 0,
      followers: 0, // Explicitly setting default value
      downloads: 0, // Explicitly setting default value
      favoriteCnt: 0, // Explicitly setting default value
      pictureDTOList: uploadedPictures.isNotEmpty ? uploadedPictures : null, // Add uploaded picture info
      // userId and nickname will be handled by the backend based on the auth token
    );

    try {
      // Call the createPost service
      final dynamic responseData = await PostService.createPost(newPost);

      // Check the type of the responseData to extract the post ID
      int? postId;
      if (responseData is int) {
        // Backend returned just the post ID (int)
        postId = responseData;
      } else if (responseData is Post) {
        // Backend returned the full Post object
        postId = responseData.postId;
      } else {
         // Handle unexpected response type
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글 등록 성공. 하지만 응답 형식이 예상과 다릅니다.')),
        );
         return; // Stop here if we can't get a postId
      }

      if (postId != null) {
        // Navigate to the post detail page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 성공적으로 등록되었습니다!')),
        );
        // Navigate to the detail screen, passing the postId
        // Assuming the detail route is '/post/detail' and takes postId
        Navigator.pushReplacementNamed( // Use pushReplacementNamed to prevent going back to register page
          context,
          '/post/detail', // Replace with your actual post detail route name
          arguments: postId, // Pass the post ID
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글 등록 성공. 하지만 게시글 ID를 가져올 수 없습니다.')),
        );
      }

    } catch (e) {
      // Handle errors during post creation API call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 등록 실패: ${e.toString()}')),
      );
    }
  }
} 