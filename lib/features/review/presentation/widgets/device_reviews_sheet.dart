import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../device/data/models/device_model.dart';
import '../controllers/review_controller.dart';
import '../../data/models/review_model.dart';

class DeviceReviewsSheet extends StatefulWidget {
  final Device device;
  final AuthController authController;

  const DeviceReviewsSheet({
    super.key,
    required this.device,
    required this.authController,
  });

  static void show({
    required BuildContext context,
    required Device device,
    required AuthController authController,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => DeviceReviewsSheet(
        device: device,
        authController: authController,
      ),
    );
  }

  @override
  State<DeviceReviewsSheet> createState() => _DeviceReviewsSheetState();
}

class _DeviceReviewsSheetState extends State<DeviceReviewsSheet> {
  final ReviewController _reviewController = ReviewController();
  final TextEditingController _commentCtrl = TextEditingController();
  int _selectedRating = 5;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _reviewController.loadReviewsForDevice(widget.device.id);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text('Vui lòng nhập nhận xét của bạn'),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    final ok = await _reviewController.addReview(
      deviceId: widget.device.id,
      rating: _selectedRating,
      comment: comment,
    );

    if (!mounted) return;
    setState(() => _isPosting = false);

    if (ok) {
      _commentCtrl.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text('Cảm ơn bạn đã gửi đánh giá thiết bị!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(_reviewController.errorMessage ?? 'Không thể gửi đánh giá'),
        ),
      );
    }
  }

  Future<void> _editReviewDialog(ReviewModel review) async {
    int editRating = review.rating;
    final editCommentCtrl = TextEditingController(text: review.comment ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Chỉnh Sửa Đánh Giá', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  final star = idx + 1;
                  return IconButton(
                    icon: Icon(
                      star <= editRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 28,
                    ),
                    onPressed: () => setDialogState(() => editRating = star),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: editCommentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Nhập nội dung nhận xét mới...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
              onPressed: () async {
                final txt = editCommentCtrl.text.trim();
                Navigator.pop(ctx);
                final ok = await _reviewController.updateReview(
                  id: review.id,
                  rating: editRating,
                  comment: txt,
                );
                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.success,
                      content: Text('Đã cập nhật đánh giá thành công!'),
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Xóa Đánh Giá',
      content: 'Bạn có chắc chắn muốn xóa nhận xét này?',
      confirmText: 'Xóa',
    );
    if (!ok || !mounted) return;

    final success = await _reviewController.deleteReview(review.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryDark,
          content: Text('Đã xóa đánh giá.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.authController.currentUser;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đánh Giá & Phản Hồi',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        widget.device.name,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Reviews List
          Expanded(
            child: ListenableBuilder(
              listenable: _reviewController,
              builder: (context, _) {
                if (_reviewController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_reviewController.reviews.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có đánh giá nào cho thiết bị này',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Hãy là phụ huynh đầu tiên chia sẻ cảm nhận về sản phẩm!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviewController.reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final review = _reviewController.reviews[idx];
                    final canManage = widget.authController.isAdmin ||
                        (currentUser != null && review.userId == currentUser.id);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primarySoft,
                                    child: Text(
                                      review.userName.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    review.userName,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ...List.generate(5, (i) {
                                    return Icon(
                                      i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: const Color(0xFFF59E0B),
                                      size: 16,
                                    );
                                  }),
                                  if (canManage) ...[
                                    const SizedBox(width: 6),
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      iconSize: 18,
                                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _editReviewDialog(review);
                                        } else if (val == 'delete') {
                                          _deleteReview(review);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 16),
                                              SizedBox(width: 8),
                                              Text('Sửa'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                              SizedBox(width: 8),
                                              Text('Xóa', style: TextStyle(color: AppColors.error)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (review.comment != null && review.comment!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              review.comment!,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Add Review Form at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Đánh giá của bạn:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Row(
                      children: List.generate(5, (idx) {
                        final star = idx + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRating = star),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              star <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 24,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nhận xét trải nghiệm của bé khi dùng...',
                          hintStyle: const TextStyle(fontSize: 12.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _isPosting ? null : _submitReview,
                      child: _isPosting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
