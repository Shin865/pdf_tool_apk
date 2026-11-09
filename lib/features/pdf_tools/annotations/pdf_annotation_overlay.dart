import 'dart:io';

import 'package:document_reviewer/core/engine/pdf_annotation_engine.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_annotation_controller.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_tool_mode.dart';
import 'package:flutter/material.dart';

/// Overlay widget placed over a PDF page view to display and draw annotations.
class PdfAnnotationOverlay extends StatefulWidget {
  const PdfAnnotationOverlay({
    required this.pageIndex,
    required this.controller,
    required this.toolMode,
    this.primaryColor = Colors.amber,
    this.strokeWidth = 3.0,
    this.activeSignaturePath,
    this.onAnnotationAdded,
    super.key,
  });

  final int pageIndex;
  final PdfAnnotationController controller;
  final PdfToolMode toolMode;
  final Color primaryColor;
  final double strokeWidth;
  final String? activeSignaturePath;
  final VoidCallback? onAnnotationAdded;

  @override
  State<PdfAnnotationOverlay> createState() => _PdfAnnotationOverlayState();
}

class _PdfAnnotationOverlayState extends State<PdfAnnotationOverlay> {
  final List<Offset> _currentInkStroke = [];
  Offset? _dragStart;
  Offset? _dragCurrent;

  void _onPanStart(DragStartDetails details) {
    if (widget.toolMode == PdfToolMode.view) return;

    final pos = details.localPosition;
    setState(() {
      if (widget.toolMode == PdfToolMode.pen) {
        _currentInkStroke
          ..clear()
          ..add(pos);
      } else if (widget.toolMode == PdfToolMode.highlight ||
          widget.toolMode == PdfToolMode.underline) {
        _dragStart = pos;
        _dragCurrent = pos;
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.toolMode == PdfToolMode.view) return;

    final pos = details.localPosition;
    setState(() {
      if (widget.toolMode == PdfToolMode.pen) {
        _currentInkStroke.add(pos);
      } else if (widget.toolMode == PdfToolMode.highlight ||
          widget.toolMode == PdfToolMode.underline) {
        _dragCurrent = pos;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.toolMode == PdfToolMode.view) return;

    if (widget.toolMode == PdfToolMode.pen && _currentInkStroke.length > 1) {
      final points =
          _currentInkStroke.map((pt) => [pt.dx, pt.dy]).toList(growable: false);

      final annotation = PdfAnnotation(
        id: 'ink_${DateTime.now().microsecondsSinceEpoch}',
        type: AnnotationType.freehandDrawing,
        pageIndex: widget.pageIndex,
        rect: const [0, 0, 0, 0],
        points: points,
        strokeWidth: widget.strokeWidth,
        color: widget.primaryColor,
        createdAt: DateTime.now(),
      );

      widget.controller.addAnnotation(annotation);
      widget.onAnnotationAdded?.call();
    } else if ((widget.toolMode == PdfToolMode.highlight ||
            widget.toolMode == PdfToolMode.underline) &&
        _dragStart != null &&
        _dragCurrent != null) {
      final left =
          _dragStart!.dx < _dragCurrent!.dx ? _dragStart!.dx : _dragCurrent!.dx;
      final top =
          _dragStart!.dy < _dragCurrent!.dy ? _dragStart!.dy : _dragCurrent!.dy;
      final right =
          _dragStart!.dx > _dragCurrent!.dx ? _dragStart!.dx : _dragCurrent!.dx;
      final bottom =
          _dragStart!.dy > _dragCurrent!.dy ? _dragStart!.dy : _dragCurrent!.dy;

      if ((right - left).abs() > 4 && (bottom - top).abs() > 4) {
        final isHighlight = widget.toolMode == PdfToolMode.highlight;
        final annotation = PdfAnnotation(
          id: '${isHighlight ? "hl" : "ul"}_${DateTime.now().microsecondsSinceEpoch}',
          type:
              isHighlight ? AnnotationType.highlight : AnnotationType.underline,
          pageIndex: widget.pageIndex,
          rect: [left, top, right, bottom],
          color: widget.primaryColor,
          createdAt: DateTime.now(),
        );

        widget.controller.addAnnotation(annotation);
        widget.onAnnotationAdded?.call();
      }
    }

    setState(() {
      _currentInkStroke.clear();
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.toolMode == PdfToolMode.text) {
      _showTextInputDialog(details.localPosition);
    } else if (widget.toolMode == PdfToolMode.signature &&
        widget.activeSignaturePath != null) {
      _placeSignature(details.localPosition);
    }
  }

  Future<void> _showTextInputDialog(Offset pos) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Catatan Teks / Add Text Note'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ketik teks catatan...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
            child: const Text('Tambahkan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final annotation = PdfAnnotation(
        id: 'txt_${DateTime.now().microsecondsSinceEpoch}',
        type: AnnotationType.textNote,
        pageIndex: widget.pageIndex,
        rect: [pos.dx, pos.dy, pos.dx + 150, pos.dy + 30],
        content: result,
        color: widget.primaryColor,
        strokeWidth: 14,
        createdAt: DateTime.now(),
      );
      widget.controller.addAnnotation(annotation);
      widget.onAnnotationAdded?.call();
    }
  }

  void _placeSignature(Offset pos) {
    final sigPath = widget.activeSignaturePath;
    if (sigPath == null) return;

    final annotation = PdfAnnotation(
      id: 'sig_${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.signature,
      pageIndex: widget.pageIndex,
      rect: [pos.dx, pos.dy, pos.dx + 160, pos.dy + 70],
      imagePath: sigPath,
      createdAt: DateTime.now(),
    );

    widget.controller.addAnnotation(annotation);
    widget.onAnnotationAdded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final annotations =
        widget.controller.getAnnotationsForPage(widget.pageIndex);

    return Positioned.fill(
      child: GestureDetector(
        behavior: widget.toolMode == PdfToolMode.view
            ? HitTestBehavior.deferToChild
            : HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapUp: _onTapUp,
        child: CustomPaint(
          painter: _AnnotationPainter(
            annotations: annotations,
            currentInkStroke: _currentInkStroke,
            dragStart: _dragStart,
            dragCurrent: _dragCurrent,
            toolMode: widget.toolMode,
            activeColor: widget.primaryColor,
            strokeWidth: widget.strokeWidth,
          ),
          child: Stack(
            children: [
              for (final a in annotations)
                if (a.type == AnnotationType.signature &&
                    a.imagePath != null &&
                    a.rect.length >= 4)
                  Positioned(
                    left: a.rect[0],
                    top: a.rect[1],
                    width: (a.rect[2] - a.rect[0]).abs(),
                    height: (a.rect[3] - a.rect[1]).abs(),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue.withAlpha(128),
                        ),
                      ),
                      child: Image.file(
                        File(a.imagePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  const _AnnotationPainter({
    required this.annotations,
    required this.currentInkStroke,
    required this.dragStart,
    required this.dragCurrent,
    required this.toolMode,
    required this.activeColor,
    required this.strokeWidth,
  });

  final List<PdfAnnotation> annotations;
  final List<Offset> currentInkStroke;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final PdfToolMode toolMode;
  final Color activeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint confirmed annotations
    for (final a in annotations) {
      final color = a.color ?? Colors.amber;
      switch (a.type) {
        case AnnotationType.highlight:
          if (a.rect.length >= 4) {
            final paint = Paint()
              ..color = color.withAlpha(100)
              ..style = PaintingStyle.fill;
            canvas.drawRect(
              Rect.fromLTRB(a.rect[0], a.rect[1], a.rect[2], a.rect[3]),
              paint,
            );
          }

        case AnnotationType.underline:
          if (a.rect.length >= 4) {
            final paint = Paint()
              ..color = color
              ..strokeWidth = 2.0
              ..style = PaintingStyle.stroke;
            canvas.drawLine(
              Offset(a.rect[0], a.rect[3]),
              Offset(a.rect[2], a.rect[3]),
              paint,
            );
          }

        case AnnotationType.freehandDrawing:
          if (a.points != null && a.points!.length > 1) {
            final paint = Paint()
              ..color = color
              ..strokeWidth = a.strokeWidth ?? 3.0
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke;

            final path = Path()..moveTo(a.points![0][0], a.points![0][1]);
            for (var i = 1; i < a.points!.length; i++) {
              path.lineTo(a.points![i][0], a.points![i][1]);
            }
            canvas.drawPath(path, paint);
          }

        case AnnotationType.textNote:
          if (a.content != null && a.rect.isNotEmpty) {
            TextPainter(
              text: TextSpan(
                text: a.content,
                style: TextStyle(
                  color: color,
                  fontSize: a.strokeWidth ?? 14.0,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.white70,
                ),
              ),
              textDirection: TextDirection.ltr,
            )
              ..layout(maxWidth: size.width - a.rect[0])
              ..paint(canvas, Offset(a.rect[0], a.rect[1]));
          }

        case AnnotationType.signature:
        case AnnotationType.stamp:
        case AnnotationType.strikethrough:
      }
    }

    // 2. Paint active/in-progress drawing
    if (toolMode == PdfToolMode.pen && currentInkStroke.length > 1) {
      final paint = Paint()
        ..color = activeColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(currentInkStroke[0].dx, currentInkStroke[0].dy);
      for (var i = 1; i < currentInkStroke.length; i++) {
        path.lineTo(currentInkStroke[i].dx, currentInkStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    } else if (dragStart != null && dragCurrent != null) {
      final rect = Rect.fromPoints(dragStart!, dragCurrent!);
      if (toolMode == PdfToolMode.highlight) {
        final paint = Paint()
          ..color = activeColor.withAlpha(90)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);
      } else if (toolMode == PdfToolMode.underline) {
        final paint = Paint()
          ..color = activeColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(rect.bottomLeft, rect.bottomRight, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}
