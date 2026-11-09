/// Application-wide constants.
library;

/// MIME types recognized by the application.
abstract final class SupportedMimeTypes {
  // PDF
  static const String pdf = 'application/pdf';

  // Office - Microsoft
  static const String docx =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  static const String xlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const String pptx = 'application/vnd.openxmlformats-officedocument'
      '.presentationml.presentation';

  // Office - OpenDocument
  static const String odt = 'application/vnd.oasis.opendocument.text';
  static const String ods = 'application/vnd.oasis.opendocument.spreadsheet';
  static const String odp = 'application/vnd.oasis.opendocument.presentation';

  // Text
  static const String txt = 'text/plain';
  static const String rtf = 'application/rtf';
  static const String csv = 'text/csv';

  // Images
  static const String jpeg = 'image/jpeg';
  static const String png = 'image/png';
  static const String tiff = 'image/tiff';
  static const String bmp = 'image/bmp';
  static const String webp = 'image/webp';

  /// All supported MIME types for SAF file picker.
  static const List<String> all = [
    pdf,
    docx,
    xlsx,
    pptx,
    odt,
    ods,
    odp,
    txt,
    rtf,
    csv,
    jpeg,
    png,
    tiff,
    bmp,
    webp,
  ];

  /// Document types (non-image).
  static const List<String> documents = [
    pdf,
    docx,
    xlsx,
    pptx,
    odt,
    ods,
    odp,
    txt,
    rtf,
    csv,
  ];

  /// Image types.
  static const List<String> images = [jpeg, png, tiff, bmp, webp];
}

/// Database constants.
abstract final class DbConstants {
  static const String databaseName = 'document_reviewer.db';
  static const int databaseVersion = 1;
}

/// App metadata.
abstract final class AppConstants {
  static const String appName = 'Document Reviewer';
  static const String appVersion = '1.0.0';
  static const String orgName = 'com.example.documentreviewer';
  static const String workingCopyDirName = 'working';
}
