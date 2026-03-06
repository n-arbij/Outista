import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Wraps a [CameraPreview] in a full-size clip so it fills its parent.
///
/// Handles the case where the controller is not yet initialized by showing an
/// empty [SizedBox] instead of throwing.
class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) return const SizedBox.expand();

    return SizedBox.expand(
      child: ClipRRect(
        child: CameraPreview(controller),
      ),
    );
  }
}
