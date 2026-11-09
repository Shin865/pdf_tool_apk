import 'dart:io';

import 'package:document_reviewer/core/engine/pdf_page_engine.dart';
import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:flutter/services.dart';

/// Native implementation of [PdfPageEngine] using PdfBox and PdfRenderer.
class NativePdfPageEngine implements PdfPageEngine {
  NativePdfPageEngine({
    MethodChannel? engineChannel,
  }) : _channel = engineChannel ??
            const MethodChannel('com.example.documentreviewer/engine');

  final MethodChannel _channel;

  @override
  Future<bool> rotatePage({
    required String filePath,
    required int pageIndex,
    required int degrees,
    required String outputPath,
  }) async {
    if (!File(filePath).existsSync()) {
      throw DocumentNotFoundException(filePath);
    }
    final res = await _channel.invokeMethod<bool>('pdf_rotatePage', {
      'filePath': filePath,
      'pageIndex': pageIndex,
      'degrees': degrees,
      'outputPath': outputPath,
    });
    return res ?? false;
  }

  @override
  Future<bool> deletePages({
    required String filePath,
    required List<int> pageIndices,
    required String outputPath,
  }) async {
    if (!File(filePath).existsSync()) {
      throw DocumentNotFoundException(filePath);
    }
    final res = await _channel.invokeMethod<bool>('pdf_deletePages', {
      'filePath': filePath,
      'pageIndices': pageIndices,
      'outputPath': outputPath,
    });
    return res ?? false;
  }

  @override
  Future<bool> reorderPages({
    required String filePath,
    required List<int> newOrder,
    required String outputPath,
  }) async {
    if (!File(filePath).existsSync()) {
      throw DocumentNotFoundException(filePath);
    }
    final res = await _channel.invokeMethod<bool>('pdf_reorderPages', {
      'filePath': filePath,
      'newOrder': newOrder,
      'outputPath': outputPath,
    });
    return res ?? false;
  }

  @override
  Future<bool> mergePdfs({
    required List<String> filePaths,
    required String outputPath,
  }) async {
    for (final path in filePaths) {
      if (!File(path).existsSync()) {
        throw DocumentNotFoundException(path);
      }
    }
    final res = await _channel.invokeMethod<bool>('pdf_mergePdfs', {
      'filePaths': filePaths,
      'outputPath': outputPath,
    });
    return res ?? false;
  }

  @override
  Future<bool> splitPdf({
    required String filePath,
    required int startPage,
    required int endPage,
    required String outputPath,
  }) async {
    if (!File(filePath).existsSync()) {
      throw DocumentNotFoundException(filePath);
    }
    final res = await _channel.invokeMethod<bool>('pdf_splitPdf', {
      'filePath': filePath,
      'startPage': startPage,
      'endPage': endPage,
      'outputPath': outputPath,
    });
    return res ?? false;
  }

  @override
  Future<bool> exportPageToImage({
    required String filePath,
    required int pageIndex,
    required String outputPath,
    double scale = 2.0,
  }) async {
    if (!File(filePath).existsSync()) {
      throw DocumentNotFoundException(filePath);
    }
    final res = await _channel.invokeMethod<bool>('pdf_renderPage', {
      'filePath': filePath,
      'pageIndex': pageIndex,
      'scale': scale,
      'outputPath': outputPath,
    });
    return res ?? false;
  }
}
