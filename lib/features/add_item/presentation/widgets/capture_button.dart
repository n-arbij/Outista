import 'package:flutter/material.dart';

const _kAccent = Color(0xFF4A90D9);

/// Large circular shutter button with a press-scale animation.
///
/// Shows a [CircularProgressIndicator] in place of the inner fill while
/// [isLoading] is `true`.
class CaptureButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const CaptureButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    if (widget.isLoading) return;
    setState(() => _scale = 0.9);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
    if (!widget.isLoading) widget.onPressed?.call();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: _kAccent,
                      strokeWidth: 2.5,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
