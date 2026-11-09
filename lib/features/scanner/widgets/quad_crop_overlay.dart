import 'dart:io';
import 'package:flutter/material.dart';

/// Draggable corner handles on top of a scanned image.
///
/// Converts between normalized/image coordinates and screen display coordinates.
class QuadCropOverlay extends StatefulWidget {
  const QuadCropOverlay({
    required this.imagePath,
    required this.corners,
    required this.imageWidth,
    required this.imageHeight,
    required this.onCornersChanged,
    super.key,
  });

  final String imagePath;

  /// Four points [[x, y], ...] in image coordinate space:
  /// 0: Top-Left, 1: Top-Right, 2: Bottom-Right, 3: Bottom-Left.
  final List<List<double>> corners;

  final double imageWidth;
  final double imageHeight;

  final ValueChanged<List<List<double>>> onCornersChanged;

  @override
  State<QuadCropOverlay> createState() => _QuadCropOverlayState();
}

class _QuadCropOverlayState extends State<QuadCropOverlay> {
  late List<List<double>> _currentCorners;
  int? _activeCornerIndex;

  @override
  void initState() {
    super.initState();
    _currentCorners = widget.corners.map(List<double>.from).toList();
  }

  @override
  void didUpdateWidget(covariant QuadCropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corners != widget.corners) {
      _currentCorners = widget.corners.map(List<double>.from).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        if (availableWidth <= 0 || availableHeight <= 0) {
          return const SizedBox.shrink();
        }

        final imgW = widget.imageWidth > 0 ? widget.imageWidth : 800.0;
        final imgH = widget.imageHeight > 0 ? widget.imageHeight : 1000.0;

        // Calculate fitted display rect maintaining aspect ratio
        final scaleX = availableWidth / imgW;
        final scaleY = availableHeight / imgH;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        final displayW = imgW * scale;
        final displayH = imgH * scale;

        final offsetX = (availableWidth - displayW) / 2;
        final offsetY = (availableHeight - displayH) / 2;

        // Transform corners to screen coordinates
        final screenPoints = _currentCorners.map((c) {
          final sx = offsetX + (c[0] * scale);
          final sy = offsetY + (c[1] * scale);
          return Offset(sx, sy);
        }).toList();

        return Stack(
          children: [
            // Centered Image
            Center(
              child: SizedBox(
                width: displayW,
                height: displayH,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
            ),

            // Polygon lines & shaded exterior
            CustomPaint(
              size: Size(availableWidth, availableHeight),
              painter: _QuadCropPainter(
                points: screenPoints,
                accentColor: primaryColor,
              ),
            ),

            // Draggable handles for each corner
            for (int i = 0; i < screenPoints.length; i++)
              Positioned(
                left: screenPoints[i].dx - 24,
                top: screenPoints[i].dy - 24,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    setState(() {
                      _activeCornerIndex = i;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      // Convert screen delta back to image coordinates
                      final deltaImgX = details.delta.dx / scale;
                      final deltaImgY = details.delta.dy / scale;

                      final newX =
                          (_currentCorners[i][0] + deltaImgX).clamp(0.0, imgW);
                      final newY =
                          (_currentCorners[i][1] + deltaImgY).clamp(0.0, imgH);

                      _currentCorners[i] = [newX, newY];
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _activeCornerIndex = null;
                    });
                    widget.onCornersChanged(_currentCorners);
                  },
                  child: Semantics(
                    label: 'Corner Handle ${i + 1}',
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _activeCornerIndex == i
                              ? primaryColor
                              : primaryColor.withOpacity(0.9),
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuadCropPainter extends CustomPainter {
  _QuadCropPainter({
    required this.points,
    required this.accentColor,
  });

  final List<Offset> points;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 4) return;

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = accentColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    canvas
      ..drawPath(path, fillPaint)
      ..drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _QuadCropPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.accentColor != accentColor;
  }
}
