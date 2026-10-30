import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/review_model.dart';

class ReviewService {
  final ApiClient apiClient;

  ReviewService({ApiClient? apiClient}) : apiClient = apiClient ?? ApiClient();

  /// Lấy danh sách đánh giá của thiết bị hoặc người dùng
  Future<List<ReviewModel>> getReviews({
    int pageNumber = 1,
    int pageSize = 20,
    int? deviceId,
    int? userId,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };
    if (deviceId != null) {
      queryParams['deviceId'] = deviceId.toString();
    }
    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }

    final query = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final path = '${ApiEndpoints.reviews}?$query';

    final response = await apiClient.get(path, auth: false);
    final data = response['data'];
    if (data is Map<String, dynamic> && data['items'] is List) {
      final list = data['items'] as List;
      return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Gửi đánh giá cho thiết bị
  Future<ReviewModel> createReview({
    required int deviceId,
    required int rating,
    String? comment,
  }) async {
    final body = {
      'deviceId': deviceId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };

    final response = await apiClient.post(ApiEndpoints.reviews, body: body, auth: true);
    final data = response['data'];
    return ReviewModel.fromJson(data as Map<String, dynamic>);
  }

  /// Cập nhật đánh giá
  Future<ReviewModel> updateReview({
    required int id,
    required int rating,
    String? comment,
  }) async {
    final body = {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };

    final response = await apiClient.put(ApiEndpoints.reviewDetail(id), body: body, auth: true);
    final data = response['data'];
    return ReviewModel.fromJson(data as Map<String, dynamic>);
  }

  /// Xóa đánh giá
  Future<bool> deleteReview(int id) async {
    await apiClient.delete(ApiEndpoints.reviewDetail(id), auth: true);
    return true;
  }
}
