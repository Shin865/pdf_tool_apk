import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Interactive drawing dialog to capture a handwritten signature as an image.
///
/// Complies with strict legal disclosure requirements: prominently displays
/// that this is NOT a certified digital signature.
class SignatureDialog extends StatefulWidget {
  const SignatureDialog({
    super.key,
    this.strokeColor = Colors.black,
    this.strokeWidth = 3.0,
    this.signaturesDir,
  });

  final Color strokeColor;
  final double strokeWidth;
  final Directory? signaturesDir;

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SignatureDialog(),
    );
  }

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
      _strokes.add(_currentStroke);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = [];
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    // Render signature strokes onto a transparent canvas
    const size = Size(400, 200);
    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..color = widget.strokeColor
      ..strokeWidth = widget.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final bytes = byteData.buffer.asUint8List();

    // Save in private sandboxed directory
    final baseDir = widget.signaturesDir ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/signatures',
        );
    if (!baseDir.existsSync()) {
      baseDir.createSync(recursive: true);
    }

    final sigFile = File(
      '${baseDir.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await sigFile.writeAsBytes(bytes);

    if (mounted) {
      Navigator.of(context).pop(sigFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.draw, size: 24),
          SizedBox(width: 8),
          Expanded(child: Text('Tanda Tangan / Signature')),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mandatory Disclaimer
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade900,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PERHATIAN: Ini BUKAN tanda tangan elektronik tersertifikasi.\n'
                      'NOTICE: This is NOT a certified digital signature.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Drawing Canvas Area
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  key: const Key('signature_canvas_gesture'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: _SignaturePainter(
                      strokes: _strokes,
                      strokeColor: widget.strokeColor,
                      strokeWidth: widget.strokeWidth,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Goreskan tanda tangan Anda pada bidang di atas.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _clear,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Gambar Ulang / Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal / Cancel'),
        ),
        FilledButton(
          onPressed: _strokes.isEmpty ? null : _save,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 18),
              SizedBox(width: 6),
              Text('Gunakan / Use'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({
    required this.strokes,
    required this.strokeColor,
    required this.strokeWidth,
  });

  final List<List<Offset>> strokes;
  final Color strokeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
