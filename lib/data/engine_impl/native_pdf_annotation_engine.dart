import 'dart:io';

import 'package:document_reviewer/core/engine/pdf_annotation_engine.dart';
import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:flutter/services.dart';

/// Implementation of [PdfAnnotationEngine] using PdfBox-Android on native Android.
class NativePdfAnnotationEngine implements PdfAnnotationEngine {
  NativePdfAnnotationEngine({
    MethodChannel? engineChannel,
  }) : _channel = engineChannel ??
            const MethodChannel('com.example.documentreviewer/engine');

  final MethodChannel _channel;
  String? _workingFilePath;
  final List<PdfAnnotation> _stagedAnnotations = [];

  @override
  Future<void> openForAnnotation({required String filePath}) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentNotFoundException(filePath);
    }
    _workingFilePath = filePath;
    _stagedAnnotations.clear();
  }

  @override
  Future<String> addAnnotation(PdfAnnotation annotation) async {
    final path = _workingFilePath;
    if (path == null) {
      throw StateError('No document is open for annotation');
    }

    _stagedAnnotations.add(annotation);

    switch (annotation.type) {
      case AnnotationType.highlight:
        if (annotation.rect.length >= 4) {
          final x = annotation.rect[0];
          final y = annotation.rect[1];
          final w = annotation.rect[2] - annotation.rect[0];
          final h = annotation.rect[3] - annotation.rect[1];
          final color = annotation.color;

          await _channel.invokeMethod<bool>('pdf_addHighlight', {
            'filePath': path,
            'pageIndex': annotation.pageIndex,
            'x': x,
            'y': y,
            'width': w,
            'height': h,
            if (color != null) ...{
              'r': color.red / 255.0,
              'g': color.green / 255.0,
              'b': color.blue / 255.0,
            },
            'outputPath': path,
          });
        }

      case AnnotationType.underline:
        if (annotation.rect.length >= 4) {
          final x = annotation.rect[0];
          final y = annotation.rect[1];
          final w = annotation.rect[2] - annotation.rect[0];
          final h = annotation.rect[3] - annotation.rect[1];
          final color = annotation.color;

          await _channel.invokeMethod<bool>('pdf_addUnderline', {
            'filePath': path,
            'pageIndex': annotation.pageIndex,
            'x': x,
            'y': y,
            'width': w,
            'height': h,
            if (color != null) ...{
              'r': color.red / 255.0,
              'g': color.green / 255.0,
              'b': color.blue / 255.0,
            },
            'outputPath': path,
          });
        }

      case AnnotationType.freehandDrawing:
        if (annotation.points != null && annotation.points!.isNotEmpty) {
          final color = annotation.color;
          await _channel.invokeMethod<bool>('pdf_addInk', {
            'filePath': path,
            'pageIndex': annotation.pageIndex,
            'points': annotation.points,
            'strokeWidth': annotation.strokeWidth ?? 2.0,
            if (color != null) ...{
              'r': color.red / 255.0,
              'g': color.green / 255.0,
              'b': color.blue / 255.0,
            },
            'outputPath': path,
          });
        }

      case AnnotationType.textNote:
        if (annotation.content != null && annotation.content!.isNotEmpty) {
          final x = annotation.rect.isNotEmpty ? annotation.rect[0] : 50.0;
          final y = annotation.rect.length > 1 ? annotation.rect[1] : 50.0;
          final color = annotation.color;

          await _channel.invokeMethod<bool>('pdf_addText', {
            'filePath': path,
            'pageIndex': annotation.pageIndex,
            'text': annotation.content!,
            'x': x,
            'y': y,
            'fontSize': annotation.strokeWidth ?? 12.0,
            if (color != null) ...{
              'r': color.red / 255.0,
              'g': color.green / 255.0,
              'b': color.blue / 255.0,
            },
            'outputPath': path,
          });
        }

      case AnnotationType.signature:
      case AnnotationType.stamp:
        var imgPath = annotation.imagePath;
        if (imgPath == null && annotation.imageData != null) {
          final tempImg = File(
            '${File(path).parent.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png',
          )..writeAsBytesSync(annotation.imageData!);
          imgPath = tempImg.path;
        }

        if (imgPath != null && File(imgPath).existsSync()) {
          final x = annotation.rect.isNotEmpty ? annotation.rect[0] : 50.0;
          final y = annotation.rect.length > 1 ? annotation.rect[1] : 50.0;
          final w = annotation.rect.length >= 4
              ? (annotation.rect[2] - annotation.rect[0]).abs()
              : 150.0;
          final h = annotation.rect.length >= 4
              ? (annotation.rect[3] - annotation.rect[1]).abs()
              : 50.0;

          await _channel.invokeMethod<bool>('pdf_addImage', {
            'filePath': path,
            'pageIndex': annotation.pageIndex,
            'imagePath': imgPath,
            'x': x,
            'y': y,
            'width': w,
            'height': h,
            'outputPath': path,
          });
        }

      case AnnotationType.strikethrough:
      // Future expansion
    }

    return annotation.id;
  }

  @override
  Future<void> updateAnnotation(PdfAnnotation annotation) async {
    final idx = _stagedAnnotations.indexWhere((a) => a.id == annotation.id);
    if (idx >= 0) {
      _stagedAnnotations[idx] = annotation;
    }
  }

  @override
  Future<void> removeAnnotation({required String annotationId}) async {
    _stagedAnnotations.removeWhere((a) => a.id == annotationId);
  }

  @override
  Future<List<PdfAnnotation>> getAnnotations({required int pageIndex}) async {
    return _stagedAnnotations
        .where((a) => a.pageIndex == pageIndex)
        .toList(growable: false);
  }

  @override
  Future<List<PdfAnnotation>> getAllAnnotations() async {
    return List.unmodifiable(_stagedAnnotations);
  }

  @override
  Future<bool> saveAnnotatedDocument({required String outputPath}) async {
    final path = _workingFilePath;
    if (path == null) return false;

    if (path != outputPath) {
      final src = File(path);
      final dest = File(outputPath);
      dest.parent.createSync(recursive: true);
      src.copySync(dest.path);
    }
    return true;
  }

  @override
  Future<bool> flattenAnnotations({required String outputPath}) async {
    return saveAnnotatedDocument(outputPath: outputPath);
  }

  @override
  Future<void> close() async {
    _workingFilePath = null;
    _stagedAnnotations.clear();
  }
}
