/// Abstract interface for PDF annotation operations.
///
/// Supports highlight, underline, freehand drawing, text notes, and signature overlays.
/// Implementations must ensure annotations survive the save/reload cycle.
library;

import 'dart:typed_data';
import 'dart:ui';

/// Types of PDF annotations supported.
enum AnnotationType {
  highlight,
  underline,
  strikethrough,
  freehandDrawing,
  textNote,
  signature,
  stamp,
}

/// A single annotation on a PDF page.
class PdfAnnotation {
  const PdfAnnotation({
    required this.id,
    required this.type,
    required this.pageIndex,
    required this.rect,
    this.color,
    this.content,
    this.strokeWidth,
    this.points,
    this.imageData,
    this.imagePath,
    this.createdAt,
    this.modifiedAt,
  });

  factory PdfAnnotation.fromJson(Map<String, dynamic> json) {
    return PdfAnnotation(
      id: json['id'] as String,
      type: AnnotationType.values.byName(json['type'] as String),
      pageIndex: json['pageIndex'] as int,
      rect: (json['rect'] as List).map((e) => (e as num).toDouble()).toList(),
      color: json['color'] != null ? Color(json['color'] as int) : null,
      content: json['content'] as String?,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble(),
      points: (json['points'] as List?)
          ?.map(
            (pt) => (pt as List).map((e) => (e as num).toDouble()).toList(),
          )
          .toList(),
      imagePath: json['imagePath'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.tryParse(json['modifiedAt'] as String)
          : null,
    );
  }

  final String id;
  final AnnotationType type;
  final int pageIndex;

  /// Bounding rectangle [left, top, right, bottom] in page coordinates.
  final List<double> rect;

  final Color? color;

  /// Text content for text notes.
  final String? content;

  /// Stroke width for drawing annotations.
  final double? strokeWidth;

  /// Points for freehand drawing [[x,y], ...] in page coordinates.
  final List<List<double>>? points;

  /// Raw image data for signature/stamp.
  final Uint8List? imageData;

  /// Sandboxed file path for signature/stamp.
  final String? imagePath;

  final DateTime? createdAt;
  final DateTime? modifiedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'pageIndex': pageIndex,
        'rect': rect,
        if (color != null) 'color': color!.value,
        if (content != null) 'content': content,
        if (strokeWidth != null) 'strokeWidth': strokeWidth,
        if (points != null) 'points': points,
        if (imagePath != null) 'imagePath': imagePath,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (modifiedAt != null) 'modifiedAt': modifiedAt!.toIso8601String(),
      };

  PdfAnnotation copyWith({
    String? id,
    AnnotationType? type,
    int? pageIndex,
    List<double>? rect,
    Color? color,
    String? content,
    double? strokeWidth,
    List<List<double>>? points,
    Uint8List? imageData,
    String? imagePath,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return PdfAnnotation(
      id: id ?? this.id,
      type: type ?? this.type,
      pageIndex: pageIndex ?? this.pageIndex,
      rect: rect ?? this.rect,
      color: color ?? this.color,
      content: content ?? this.content,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      points: points ?? this.points,
      imageData: imageData ?? this.imageData,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}

/// Abstract engine for PDF annotation operations.
///
/// All modifications operate on a working copy. The original file
/// is never modified directly.
abstract class PdfAnnotationEngine {
  /// Opens a PDF for annotation from the given [filePath] (working copy).
  Future<void> openForAnnotation({required String filePath});

  /// Adds an annotation to the document.
  ///
  /// Returns the assigned annotation ID.
  Future<String> addAnnotation(PdfAnnotation annotation);

  /// Updates an existing annotation.
  Future<void> updateAnnotation(PdfAnnotation annotation);

  /// Removes the annotation with the given [annotationId].
  Future<void> removeAnnotation({required String annotationId});

  /// Returns all annotations on the given [pageIndex].
  Future<List<PdfAnnotation>> getAnnotations({required int pageIndex});

  /// Returns all annotations across the entire document.
  Future<List<PdfAnnotation>> getAllAnnotations();

  /// Saves the annotated document to [outputPath].
  ///
  /// The original file at the source path is NOT modified.
  /// Returns `true` if the save was successful.
  Future<bool> saveAnnotatedDocument({required String outputPath});

  /// Flattens all annotations into the page content (makes them non-editable).
  Future<bool> flattenAnnotations({required String outputPath});

  /// Releases native resources.
  Future<void> close();
}
