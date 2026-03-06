import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_routes.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/capture_button.dart';

const _kPrimary = Color(0xFF1A1A2E);

/// Full-screen camera preview with capture, flip and crop controls.
///
/// Requests camera permission on init. After capture, immediately opens the
/// image cropper before forwarding the path to [ItemTaggingScreen].
class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  ConsumerState<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isInitialized = false;
  bool _permissionGranted = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initCamera();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  /// Requests camera permission then initialises the controller.
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _permissionGranted = false);
      return;
    }

    setState(() => _permissionGranted = true);

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    await _startController(_cameras[_cameraIndex]);
  }

  Future<void> _startController(CameraDescription camera) async {
    await _controller?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;
    try {
      await controller.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (_) {
      // Swallow initialisation errors — screen shows loading indicator.
    }
  }

  /// Captures a photo, opens the cropper and navigates to the tagging screen.
  Future<void> _captureImage() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      final file = await controller.takePicture();

      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
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

      if (cropped != null && mounted) {
        context.push(AppRoutes.addItemTaggingPath, extra: cropped.path);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Switches between front and back cameras.
  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _isInitialized = false);
    await _startController(_cameras[_cameraIndex]);
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) return _buildPermissionDenied();
    if (!_isInitialized || _controller == null) return _buildLoading();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreviewWidget(controller: _controller!),
          _buildTopOverlay(),
          _buildBottomOverlay(),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Camera permission required',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: openAppSettings,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: const Center(
        child: Text(
          'Position clothing item in frame',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 32,
          right: 32,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            CaptureButton(
              onPressed: _captureImage,
              isLoading: _isBusy,
            ),
            IconButton(
              onPressed: _cameras.length < 2 ? null : _flipCamera,
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
