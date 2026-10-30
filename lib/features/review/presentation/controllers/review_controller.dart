import 'package:flutter/foundation.dart';
import '../../data/models/review_model.dart';
import '../../data/services/review_service.dart';

class ReviewController extends ChangeNotifier {
  final ReviewService reviewService;

  ReviewController({ReviewService? reviewService})
      : reviewService = reviewService ?? ReviewService();

  List<ReviewModel> reviews = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadReviewsForDevice(int deviceId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      reviews = await reviewService.getReviews(deviceId: deviceId);
    } catch (e) {
      errorMessage = _cleanError(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReview({
    required int deviceId,
    required int rating,
    String? comment,
  }) async {
    errorMessage = null;
    try {
      final newReview = await reviewService.createReview(
        deviceId: deviceId,
        rating: rating,
        comment: comment,
      );
      reviews.insert(0, newReview);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _cleanError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReview({
    required int id,
    required int rating,
    String? comment,
  }) async {
    errorMessage = null;
    try {
      final updated = await reviewService.updateReview(
        id: id,
        rating: rating,
        comment: comment,
      );
      final idx = reviews.indexWhere((r) => r.id == id);
      if (idx != -1) {
        reviews[idx] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _cleanError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReview(int id) async {
    errorMessage = null;
    try {
      await reviewService.deleteReview(id);
      reviews.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _cleanError(e.toString());
      notifyListeners();
      return false;
    }
  }

  String _cleanError(String raw) {
    return raw
        .replaceAll('ApiException: ', '')
        .replaceAll('Exception: ', '');
  }
}
