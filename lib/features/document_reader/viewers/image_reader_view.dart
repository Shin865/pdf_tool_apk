import 'dart:io';
import 'package:flutter/material.dart';

/// Image viewer supporting JPG, PNG, WEBP, and BMP with pinch-zoom,
/// manual 90-degree rotation, and image dimension display.
class ImageReaderView extends StatefulWidget {
  const ImageReaderView({
    required this.filePath,
    this.initialZoom = 1.0,
    super.key,
  });

  final String filePath;
  final double initialZoom;

  @override
  State<ImageReaderView> createState() => _ImageReaderViewState();
}

class _ImageReaderViewState extends State<ImageReaderView> {
  final TransformationController _transformationController =
      TransformationController();
  int _rotationQuarterTurns = 0;
  int _fileSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadFileMetadata();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _loadFileMetadata() {
    try {
      final file = File(widget.filePath);
      if (file.existsSync()) {
        _fileSizeBytes = file.lengthSync();
      }
    } on Exception {
      // Ignored
    }
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _transformationController.value = Matrix4.identity();
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Main zoomable image view
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 5,
          child: Center(
            child: RotatedBox(
              quarterTurns: _rotationQuarterTurns,
              child: Image.file(
                File(widget.filePath),
                fit: BoxFit.contain,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  return child;
                },
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        // Info chip overlay
        Positioned(
          top: 16,
          left: 16,
          child: Chip(
            avatar: const Icon(Icons.info_outline, size: 18),
            label: Text(
              _fileSizeBytes > 0 ? _formatBytes(_fileSizeBytes) : 'Image',
              style: theme.textTheme.bodySmall,
            ),
            backgroundColor: theme.colorScheme.surface.withAlpha(200),
          ),
        ),

        // Rotate button
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.small(
            heroTag: 'rotate_image_btn',
            tooltip: 'Rotate 90°',
            onPressed: _rotateClockwise,
            child: const Icon(Icons.rotate_right),
          ),
        ),
      ],
    );
  }
}
