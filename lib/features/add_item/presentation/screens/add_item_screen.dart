import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_routes.dart';

const _kPrimary = Color(0xFF1A1A2E);
const _kAccent = Color(0xFF4A90D9);

/// Entry point for the add-item flow.
///
/// Offers two paths: take a new photo with the camera or pick an existing
/// image from the gallery. After a photo is selected or captured the user is
/// forwarded to [ItemTaggingScreen].
class AddItemScreen extends ConsumerWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Icon(
                Icons.checkroom,
                size: 64,
                color: _kAccent,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Add to Wardrobe',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Scan or upload a clothing item',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 48),
            _ActionCard(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Scan your clothing item',
              onTap: () => context.push(AppRoutes.addItemCameraPath),
            ),
            const SizedBox(height: 16),
            _ActionCard(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Pick from your photos',
              onTap: () => _pickFromGallery(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: _kPrimary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
      ],
    );

    if (cropped != null && context.mounted) {
      context.push(AppRoutes.addItemTaggingPath, extra: cropped.path);
    }
  }
}

/// Tappable action card used to represent a single add-item option.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kAccent.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _kAccent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

