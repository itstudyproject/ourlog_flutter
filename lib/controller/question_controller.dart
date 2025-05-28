import 'package:ourlog/models/inquiry.dart';
import 'package:ourlog/services/auth_service.dart';
import 'package:ourlog/services/customer/question_service.dart';

class QuestionController {
  final QuestionService _questionService = QuestionService();
  final AuthService _authService = AuthService();

  Future<List<Inquiry>> getInquiriesByRole() async {
    final bool isAdmin = await _authService.checkIsAdmin(); // AuthService에서 관리자 여부 반환
    if (isAdmin) {
      return await _questionService.fetchAllInquiries();
    } else {
      return await _questionService.fetchInquiries();
    }
  }
}