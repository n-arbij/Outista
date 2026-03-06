import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

/// Handles saving, compressing and deleting clothing item images on disk.
///
/// All images are stored in `<documents>/wardrobe_images/` with a UUID
/// filename so paths remain stable even if the item is edited.
class ImageStorageService {
  static const _uuid = Uuid();
  static const _subdir = 'wardrobe_images';

  /// Compresses the image at [sourcePath] and copies it into the
  /// app's private documents directory.
  ///
  /// Returns the absolute path of the newly saved file.
  Future<String> saveImage(String sourcePath) async {
    final dir = await _getStorageDirectory();
    final ext = p.extension(sourcePath).toLowerCase();
    final filename = '${_uuid.v4()}$ext';
    final destPath = p.join(dir.path, filename);

    final quality = (AppConstants.imageCaptureQuality * 100).toInt();

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      destPath,
      quality: quality,
      minWidth: AppConstants.imageMaxWidth,
      minHeight: AppConstants.imageMaxHeight,
      keepExif: false,
    );

    if (result == null) {
      // Fallback: plain copy if compression fails (e.g. unsupported format).
      await File(sourcePath).copy(destPath);
    }

    return destPath;
  }

  /// Deletes the image file at [imagePath].
  ///
  /// Silently ignores the call if the file does not exist.
  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Returns `true` if the file at [imagePath] exists on disk.
  bool imageExists(String imagePath) => File(imagePath).existsSync();

  /// Returns (and creates if necessary) the `wardrobe_images/` subdirectory
  /// inside the app's documents directory.
  Future<Directory> _getStorageDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _subdir));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
