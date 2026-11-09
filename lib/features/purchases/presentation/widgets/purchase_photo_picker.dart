import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/uuid.dart';

/// Reusable photo picker for purchase items that supports 1 or more images
/// scaled by the purchased item quantity.
final class PurchasePhotoPicker extends StatelessWidget {
  const PurchasePhotoPicker({
    super.key,
    required this.photoPaths,
    required this.maxPhotos,
    required this.onPhotosChanged,
    this.title,
  });

  final List<String> photoPaths;
  final int maxPhotos;
  final ValueChanged<List<String>> onPhotosChanged;
  final String? title;

  int get _effectiveMax => maxPhotos < 1 ? 1 : maxPhotos;

  Future<String?> _copyToAppStorage(String sourcePath) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(docsDir.path, 'photos'));
      if (!photosDir.existsSync()) {
        await photosDir.create(recursive: true);
      }
      final ext = p.extension(sourcePath);
      final destPath = p.join(photosDir.path, '${newUuid()}$ext');
      final saved = await File(sourcePath).copy(destPath);
      return saved.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    if (photoPaths.length >= _effectiveMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum $_effectiveMax photo${_effectiveMax > 1 ? 's' : ''} allowed for this item',
          ),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      final saved = await _copyToAppStorage(picked.path);
      if (saved != null) {
        onPhotosChanged([...photoPaths, saved]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
      }
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final remaining = _effectiveMax - photoPaths.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum $_effectiveMax photo${_effectiveMax > 1 ? 's' : ''} allowed for this item',
          ),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      if (remaining == 1) {
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        if (picked == null) return;
        final saved = await _copyToAppStorage(picked.path);
        if (saved != null) {
          onPhotosChanged([...photoPaths, saved]);
        }
      } else {
        final pickedList = await picker.pickMultiImage(
          limit: remaining,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        if (pickedList.isEmpty) return;

        final newPaths = <String>[];
        for (final picked in pickedList.take(remaining)) {
          final saved = await _copyToAppStorage(picked.path);
          if (saved != null) newPaths.add(saved);
        }
        if (newPaths.isNotEmpty) {
          onPhotosChanged([...photoPaths, ...newPaths]);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to select photos: $e')));
      }
    }
  }

  void _showAddPhotoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromCamera(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                _effectiveMax - photoPaths.length > 1
                    ? 'Choose from gallery (multiple)'
                    : 'Choose from gallery',
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromGallery(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFullPreview(BuildContext context, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final controller = PageController(initialPage: initialIndex);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpacing.m),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Container(
                  color: Colors.black,
                  height: 420,
                  child: PageView.builder(
                    controller: controller,
                    itemCount: photoPaths.length,
                    itemBuilder: (context, idx) {
                      final path = photoPaths[idx];
                      return InteractiveViewer(
                        child: File(path).existsSync()
                            ? Image.file(File(path), fit: BoxFit.contain)
                            : const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white54,
                                  size: 48,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canAddMore = photoPaths.length < _effectiveMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title header with counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title ??
                  (_effectiveMax > 1
                      ? 'Photos (optional, up to $_effectiveMax)'
                      : 'Photo (optional)'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (photoPaths.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '${photoPaths.length} / $_effectiveMax',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: canAddMore ? colors.primary : colors.textMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),

        // Photo thumbnails list if any attached
        if (photoPaths.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoPaths.length + (canAddMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
              itemBuilder: (context, index) {
                // "Add more" slot at the end
                if (index == photoPaths.length) {
                  return InkWell(
                    onTap: () => _showAddPhotoSheet(context),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Container(
                      width: 110,
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.4),
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: colors.primary,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add more',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final path = photoPaths[index];
                final exists = File(path).existsSync();

                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    GestureDetector(
                      onTap: () => _showFullPreview(context, index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: exists
                            ? Image.file(
                                File(path),
                                width: 110,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 110,
                                height: 120,
                                color: colors.surfaceVariant,
                                child: const Icon(Icons.broken_image, size: 28),
                              ),
                      ),
                    ),
                    // Delete button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          final updated = List<String>.from(photoPaths)
                            ..removeAt(index);
                          onPhotosChanged(updated);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
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
                    // Index label
                    if (_effectiveMax > 1)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ] else ...[
          // Empty state: Take photo & From gallery buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFromCamera(context),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take photo'),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFromGallery(context),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_effectiveMax > 1 ? 'From gallery' : 'Gallery'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
