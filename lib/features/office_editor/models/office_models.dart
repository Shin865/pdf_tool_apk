/// Block types supported in DOCX editing.
enum DocxBlockType {
  paragraph,
  heading,
  table,
  pageBreak,
  image,
}

/// Representation of an editable block in a DOCX document.
class DocxBlock {
  DocxBlock({
    required this.id,
    required this.type,
    this.text = '',
    this.headingLevel = 1,
    this.tableData,
    this.imagePath,
  });

  factory DocxBlock.fromJson(Map<String, dynamic> json) {
    return DocxBlock(
      id: json['id'] as String,
      type: DocxBlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DocxBlockType.paragraph,
      ),
      text: json['text'] as String? ?? '',
      headingLevel: json['headingLevel'] as int? ?? 1,
      tableData: (json['tableData'] as List<dynamic>?)
          ?.map((r) => (r as List<dynamic>).map((c) => c.toString()).toList())
          .toList(),
      imagePath: json['imagePath'] as String?,
    );
  }

  final String id;
  final DocxBlockType type;
  String text;
  int headingLevel;
  List<List<String>>? tableData;
  String? imagePath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'text': text,
        'headingLevel': headingLevel,
        if (tableData != null) 'tableData': tableData,
        if (imagePath != null) 'imagePath': imagePath,
      };

  DocxBlock copyWith({
    String? text,
    int? headingLevel,
    List<List<String>>? tableData,
    String? imagePath,
  }) {
    return DocxBlock(
      id: id,
      type: type,
      text: text ?? this.text,
      headingLevel: headingLevel ?? this.headingLevel,
      tableData: tableData ?? this.tableData,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

/// Representation of an editable cell in an XLSX spreadsheet.
class XlsxCell {
  XlsxCell({
    this.value = '',
    this.formula,
    this.bold = false,
    this.italic = false,
  });

  factory XlsxCell.fromJson(Map<String, dynamic> json) {
    return XlsxCell(
      value: json['value'] as String? ?? '',
      formula: json['formula'] as String?,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
    );
  }

  String value;
  String? formula;
  bool bold;
  bool italic;

  Map<String, dynamic> toJson() => {
        'value': value,
        if (formula != null) 'formula': formula,
        'bold': bold,
        'italic': italic,
      };

  XlsxCell copy() {
    return XlsxCell(
      value: value,
      formula: formula,
      bold: bold,
      italic: italic,
    );
  }
}

/// Action for undo/redo stack in office editor.
class OfficeEditAction {
  OfficeEditAction({
    required this.description,
    required this.undo,
    required this.redo,
  });

  final String description;
  final void Function() undo;
  final void Function() redo;
}
