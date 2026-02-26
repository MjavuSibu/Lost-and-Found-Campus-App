import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../router/app_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/services/photo_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/item_provider.dart';

class PostItemScreen extends ConsumerStatefulWidget {
  final String initialType;
  const PostItemScreen({super.key, required this.initialType});

  @override
  ConsumerState<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends ConsumerState<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationDetailCtrl = TextEditingController();

  late String _type;
  String _category = 'other';
  String _locationZone = '';
  String _locationName = '';
  DateTime _dateOfIncident = DateTime.now();
  bool _loading = false;

  final List<XFile> _selectedImages = [];
  List<String> _uploadedUrls = [];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _locationZone = AppConstants.campusLocations.keys.first;
    _locationName = AppConstants.campusLocations[_locationZone]!.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationDetailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = AppConstants.maxPhotos - _selectedImages.length;
    if (remaining <= 0) {
      _showError('Maximum ${AppConstants.maxPhotos} photos allowed.');
      return;
    }
    final picked = await PhotoService.pickImages(max: remaining);
    if (picked.isNotEmpty) {
      setState(() => _selectedImages.addAll(picked));
    }
  }

  Future<void> _pickFromCamera() async {
    if (_selectedImages.length >= AppConstants.maxPhotos) {
      _showError('Maximum ${AppConstants.maxPhotos} photos allowed.');
      return;
    }
    final picked = await PhotoService.pickFromCamera();
    if (picked != null) {
      setState(() => _selectedImages.add(picked));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfIncident,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.cutSage,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfIncident = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw Exception('Not logged in');

      final itemId = await ref.read(itemNotifierProvider.notifier).submitItem(
            type: _type,
            title: _titleCtrl.text,
            description: _descCtrl.text,
            category: _category,
            locationZone: _locationZone,
            locationName: _locationName,
            locationDetails: _locationDetailCtrl.text,
            dateOfIncident: _dateOfIncident,
          );

      if (_selectedImages.isNotEmpty) {
        _uploadedUrls = await PhotoService.filesToBase64(_selectedImages);
        await ref
            .read(itemNotifierProvider.notifier)
            .updatePhotos(itemId, _uploadedUrls);
      }

      if (!mounted) return;
      context.pushReplacement(AppRoutes.toItemDetail(itemId));
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
        backgroundColor: AppColors.lostRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Photo', style: AppTextStyles.h2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromCamera();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cutSagePale,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                size: 28, color: AppColors.cutSage),
                            const SizedBox(height: 8),
                            Text('Camera',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.cutSage,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImages();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cutSagePale,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_rounded,
                                size: 28, color: AppColors.cutSage),
                            const SizedBox(height: 8),
                            Text('Gallery',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.cutSage,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Item'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _sectionTitle('Item Type'),
            _buildTypeToggle(),
            const SizedBox(height: 24),
            _sectionTitle('Category'),
            _buildCategoryGrid(),
            const SizedBox(height: 24),
            _sectionTitle('Photos'),
            _buildPhotoSection(),
            const SizedBox(height: 24),
            _sectionTitle('Details'),
            _fieldLabel('TITLE'),
            TextFormField(
              controller: _titleCtrl,
              maxLength: AppConstants.maxTitleLength,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'e.g. Set of keys with blue keychain',
                counterText: '',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _fieldLabel('DESCRIPTION'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              maxLength: AppConstants.maxDescLength,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText:
                    'Describe the item in detail — colour, size, brand, any unique features...',
                counterText: '',
                alignLabelWithHint: true,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Description is required';
                }
                if (val.trim().length < 20) {
                  return 'Please provide more detail (at least 20 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _sectionTitle('Location'),
            _fieldLabel('CAMPUS ZONE'),
            DropdownButtonFormField<String>(
              value: _locationZone,
              decoration: const InputDecoration(),
              style: AppTextStyles.bodyLarge,
              items: AppConstants.campusLocations.keys
                  .map((zone) => DropdownMenuItem(
                        value: zone,
                        child: Text(zone, style: AppTextStyles.bodyMedium),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _locationZone = val;
                  _locationName = AppConstants.campusLocations[val]!.first;
                });
              },
            ),
            const SizedBox(height: 14),
            _fieldLabel('SPECIFIC LOCATION'),
            DropdownButtonFormField<String>(
              value: _locationName,
              decoration: const InputDecoration(),
              style: AppTextStyles.bodyLarge,
              items: (AppConstants.campusLocations[_locationZone] ?? [])
                  .map((loc) => DropdownMenuItem(
                        value: loc,
                        child: Text(loc, style: AppTextStyles.bodyMedium),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _locationName = val);
              },
            ),
            const SizedBox(height: 14),
            _fieldLabel('ADDITIONAL LOCATION DETAILS (OPTIONAL)'),
            TextFormField(
              controller: _locationDetailCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'e.g. Near the entrance, Room 204...',
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Date'),
            _fieldLabel(_type == 'lost' ? 'DATE LOST' : 'DATE FOUND'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(_dateOfIncident),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            _loading
                ? Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.cutSage.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.cutSage),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedImages.isNotEmpty
                                ? 'Uploading photos...'
                                : 'Submitting...',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.cutSage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : AppPrimaryButton(
                    label: _type == 'lost'
                        ? 'Submit Lost Item Report'
                        : 'Submit Found Item Report',
                    isLoading: false,
                    onTap: _submit,
                    icon: Icons.upload_rounded,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImages[i].path),
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(i),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_selectedImages.length < AppConstants.maxPhotos)
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.cutSagePale,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cutSage.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 22, color: AppColors.cutSage),
                  const SizedBox(width: 10),
                  Text(
                    _selectedImages.isEmpty
                        ? 'Add Photos (optional, up to ${AppConstants.maxPhotos})'
                        : 'Add More (${_selectedImages.length}/${AppConstants.maxPhotos})',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.cutSage,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _type = 'lost'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                color:
                    _type == 'lost' ? AppColors.lostRedBg : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _type == 'lost' ? AppColors.lostRed : AppColors.border,
                  width: _type == 'lost' ? 2 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  'I Lost This',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: _type == 'lost'
                        ? AppColors.lostRed
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _type = 'found'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                color: _type == 'found'
                    ? AppColors.foundGreenBg
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _type == 'found'
                      ? AppColors.foundGreen
                      : AppColors.border,
                  width: _type == 'found' ? 2 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  'I Found This',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: _type == 'found'
                        ? AppColors.foundGreen
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.categories.map((cat) {
        final isActive = _category == cat.id;
        return GestureDetector(
          onTap: () => setState(() => _category = cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.cutSage : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? AppColors.cutSage : AppColors.border,
                width: isActive ? 2 : 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat.icon,
                  size: 14,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  cat.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(text,
              style: AppTextStyles.h3.copyWith(color: AppColors.cutSage)),
          const SizedBox(width: 10),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTextStyles.overline.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
