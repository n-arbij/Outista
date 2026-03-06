import 'dart:io';
import 'package:flutter/material.dart';

/// Displays a cropped clothing item image with a 'Retake' overlay button.
///
/// Tapping 'Retake' calls [onRetake], allowing the parent to navigate back
/// to [CameraCaptureScreen].
class ImagePreviewCard extends StatelessWidget {
  final String imagePath;

  /// Called when the user taps the 'Retake' button.
  final VoidCallback? onRetake;

  const ImagePreviewCard({
    super.key,
    required this.imagePath,
    this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, _) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, size: 48),
              ),
            ),
            if (onRetake != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: TextButton(
                  onPressed: onRetake,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Retake'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
