/// Abstract interface for office document editing (DOCX, XLSX, etc.).
///
/// WARNING: Do not claim a format is "edit-supported" until it passes
/// the full verification cycle:
///   open → modify → save new → force-close → reopen → validate in
///   another app → original file unchanged.
///
/// Do NOT build a simple XML manipulation editor and call it a full editor.
library;

/// Supported office document types.
enum OfficeDocumentType {
  docx,
  xlsx,
  pptx,
  odt,
  ods,
  odp,
}

/// Information about an open office document.
class OfficeDocumentInfo {
  const OfficeDocumentInfo({
    required this.documentType,
    required this.title,
    required this.pageCount,
    this.sheetNames,
    this.isReadOnly = false,
    this.hasUnsupportedFeatures = false,
    this.unsupportedFeaturesList = const [],
  });

  final OfficeDocumentType documentType;
  final String title;
  final int pageCount;

  /// Sheet names for spreadsheet documents.
  final List<String>? sheetNames;

  final bool isReadOnly;

  /// True if the document uses features this engine cannot preserve.
  final bool hasUnsupportedFeatures;

  /// List of specific unsupported features detected.
  final List<String> unsupportedFeaturesList;
}

/// Result of saving an office document.
class OfficeSaveResult {
  const OfficeSaveResult({
    required this.success,
    required this.outputPath,
    this.validationPassed,
    this.warnings = const [],
    this.errors = const [],
  });

  final bool success;
  final String outputPath;

  /// Whether the saved file passed internal validation.
  /// null = validation not run.
  final bool? validationPassed;

  final List<String> warnings;
  final List<String> errors;
}

/// Abstract engine for editing office documents.
///
/// Implementations might use native libraries (Apache POI, Collabora, etc.)
/// via platform channels. All operations work on a temporary copy.
abstract class OfficeEditorEngine {
  /// Opens an office document from [filePath] (working copy).
  ///
  /// Returns information about the document and its capabilities.
  Future<OfficeDocumentInfo> openDocument({required String filePath});

  /// Returns whether this engine supports editing (not just viewing)
  /// for the given [documentType].
  bool supportsEditing(OfficeDocumentType documentType);

  /// Returns a rendered preview of the given page/sheet as pixel data.
  Future<List<int>> renderPreview({
    required int pageIndex,
    required int width,
  });

  /// Saves the modified document to [outputPath].
  ///
  /// The original file is NEVER modified. The save operation must be
  /// atomic — either fully succeeds or leaves no partial file.
  Future<OfficeSaveResult> saveDocument({required String outputPath});

  /// Validates that a saved file is well-formed and opens correctly.
  ///
  /// This is part of the mandatory verification cycle.
  Future<bool> validateSavedDocument({required String filePath});

  /// Closes the document and releases native resources.
  Future<void> closeDocument();

  /// Returns the list of [OfficeDocumentType]s this engine supports.
  List<OfficeDocumentType> get supportedTypes;

  // ─────────────────────────────────────────────────────────────────────────
  // Structured DOCX Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Retrieves structured representation of DOCX (paragraphs, headings, tables, headers).
  Future<Map<String, dynamic>> getDocxStructure({required String filePath});

  /// Updates text of paragraph at [index].
  Future<bool> updateDocxParagraph({
    required int index,
    required String text,
    String? outputPath,
  });

  /// Appends paragraph to DOCX document.
  Future<bool> appendDocxParagraph({
    required String text,
    String? outputPath,
  });

  /// Adds a heading with [level] (1, 2, 3).
  Future<bool> addDocxHeading({
    required String text,
    int level = 1,
    String? outputPath,
  });

  /// Inserts a table with [rows] and [cols] and optional [data].
  Future<bool> addDocxTable({
    required int rows,
    required int cols,
    List<List<String>>? data,
    String? outputPath,
  });

  /// Updates text in cell at [tableIndex], [row], [col].
  Future<bool> updateDocxTableCell({
    required int tableIndex,
    required int row,
    required int col,
    required String text,
    String? outputPath,
  });

  /// Inserts a page break.
  Future<bool> addDocxPageBreak({String? outputPath});

  /// Sets header text for the document.
  Future<bool> setDocxHeader({required String text, String? outputPath});

  /// Sets footer text for the document.
  Future<bool> setDocxFooter({required String text, String? outputPath});

  /// Inserts an image into the document from [imagePath].
  Future<bool> insertDocxImage({
    required String imagePath,
    int width = 300,
    int height = 200,
    String? outputPath,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Structured XLSX Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Gets sheet names in XLSX document.
  Future<List<String>> getXlsxSheetNames({required String filePath});

  /// Gets structured sheet cells with formulas, formats and values.
  Future<List<List<Map<String, dynamic>>>> getXlsxSheetData({
    required String filePath,
    int sheetIndex = 0,
  });

  /// Updates cell value, optional [formula], and text styling.
  Future<bool> updateXlsxCell({
    required int sheetIndex,
    required int row,
    required int col,
    required String value,
    String? formula,
    bool bold = false,
    bool italic = false,
    String? outputPath,
  });

  /// Adds a new sheet named [sheetName].
  Future<bool> addXlsxSheet({required String sheetName, String? outputPath});

  /// Renames sheet at [sheetIndex] to [newName].
  Future<bool> renameXlsxSheet({
    required int sheetIndex,
    required String newName,
    String? outputPath,
  });

  /// Appends a new row of [values] to sheet.
  Future<bool> addXlsxRow({
    required int sheetIndex,
    required List<String> values,
    String? outputPath,
  });

  /// Deletes row at [rowIndex] from sheet.
  Future<bool> deleteXlsxRow({
    required int sheetIndex,
    required int rowIndex,
    String? outputPath,
  });
}
