import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/device_model.dart';
import '../controllers/device_controller.dart';
import '../widgets/device_age_range_field.dart';
import '../widgets/device_category_dropdown.dart';

class DeviceFormScreen extends StatefulWidget {
  final DeviceController deviceController;
  final Device? initialDevice;

  const DeviceFormScreen({
    super.key,
    required this.deviceController,
    this.initialDevice,
  });

  @override
  State<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minAgeController;
  late final TextEditingController _maxAgeController;
  late final TextEditingController _imageUrlController;

  late String _selectedCategory;
  bool _isAvailable = true;
  bool _loading = false;

  bool get _isEditMode => widget.initialDevice != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDevice;
    _nameController = TextEditingController(text: d?.name ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _brandController = TextEditingController(text: d?.brand ?? '');
    _modelController = TextEditingController(text: d?.modelNumber ?? '');
    _priceController = TextEditingController(
      text: d != null ? d.price.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(
      text: d != null ? d.stockQuantity.toString() : '',
    );
    _minAgeController = TextEditingController(
      text: d != null ? d.minAge.toString() : '3',
    );
    _maxAgeController = TextEditingController(
      text: d != null ? d.maxAge.toString() : '12',
    );
    _imageUrlController = TextEditingController(text: d?.imageUrl ?? '');

    if (d != null && Device.defaultCategories.contains(d.category)) {
      _selectedCategory = d.category;
    } else {
      _selectedCategory = Device.defaultCategories.first;
    }
    _isAvailable = d?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      final brand = _brandController.text.trim();
      final modelNumber = _modelController.text.trim();
      final stockQuantity = int.tryParse(_stockController.text.trim()) ?? 0;
      final minAge = int.tryParse(_minAgeController.text.trim()) ?? 0;
      final maxAge = int.tryParse(_maxAgeController.text.trim()) ?? 0;
      final imageUrl = _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim();

      final bool success;
      if (_isEditMode) {
        success = await widget.deviceController.updateDevice(
          id: widget.initialDevice!.id,
          name: name,
          description: description,
          category: _selectedCategory,
          price: price,
          brand: brand,
          modelNumber: modelNumber,
          stockQuantity: stockQuantity,
          minAge: minAge,
          maxAge: maxAge,
          imageUrl: imageUrl,
          isAvailable: _isAvailable,
        );
      } else {
        success = await widget.deviceController.createDevice(
          name: name,
          description: description,
          category: _selectedCategory,
          price: price,
          brand: brand,
          modelNumber: modelNumber,
          stockQuantity: stockQuantity,
          minAge: minAge,
          maxAge: maxAge,
          imageUrl: imageUrl,
        );
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              _isEditMode
                  ? 'Đã cập nhật thiết bị "$name" thành công'
                  : 'Đã thêm thiết bị "$name" thành công',
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              widget.deviceController.errorMessage ??
                  (_isEditMode
                      ? 'Cập nhật thiết bị thất bại'
                      : 'Tạo thiết bị thất bại'),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Chỉnh sửa thiết bị' : 'Thêm thiết bị mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Tên thiết bị',
                icon: Icons.devices_rounded,
                validator: (val) => Validators.required(val, 'tên thiết bị'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _descriptionController,
                label: 'Mô tả chi tiết',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DeviceCategoryDropdown(
                selectedCategory: _selectedCategory,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _priceController,
                label: 'Giá bán (VNĐ)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (val) => Validators.nonNegativeNumber(val, 'Giá'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _brandController,
                label: 'Thương hiệu',
                icon: Icons.branding_watermark_outlined,
                validator: (val) => Validators.required(val, 'thương hiệu'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _modelController,
                label: 'Mã Model',
                icon: Icons.model_training_outlined,
                validator: (val) => Validators.required(val, 'model'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _stockController,
                label: 'Số lượng tồn kho',
                icon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
                validator: (val) =>
                    Validators.nonNegativeNumber(val, 'Số lượng tồn kho'),
              ),
              const SizedBox(height: 12),
              DeviceAgeRangeField(
                minAgeController: _minAgeController,
                maxAgeController: _maxAgeController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _imageUrlController,
                label: 'URL hình ảnh (Tùy chọn)',
                icon: Icons.image_outlined,
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SwitchListTile(
                    value: _isAvailable,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Trạng thái kinh doanh (Hiển thị bán)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      _isAvailable
                          ? 'Đang mở bán trên hệ thống'
                          : 'Tạm ngừng kinh doanh / Ẩn',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isAvailable ? AppColors.success : AppColors.error,
                      ),
                    ),
                    onChanged: (val) => setState(() => _isAvailable = val),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                text: _isEditMode ? 'Lưu thay đổi' : 'Tạo thiết bị',
                loading: _loading,
                icon: _isEditMode ? Icons.check_circle_rounded : Icons.save_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
