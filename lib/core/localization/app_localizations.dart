import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lightweight, offline-first application localization for Document Reviewer.
/// Supports Bahasa Indonesia ('id') and English ('en').
class AppLocalizations {
  AppLocalizations(this.locale);

  factory AppLocalizations.of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('id'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Document Reviewer',
      'openFile': 'Open Document',
      'recentDocuments': 'Recent Documents',
      'favoriteDocuments': 'Favorites',
      'settings': 'Settings',
      'theme': 'Theme',
      'themeSystem': 'System Default',
      'themeLight': 'Light Mode',
      'themeDark': 'Dark Mode',
      'noRecentDocuments': 'No recent documents found',
      'noFavorites': 'No favorite documents bookmarked',
      'save': 'Save',
      'saveAs': 'Save As',
      'saving': 'Saving...',
      'saved': 'Document saved successfully',
      'error': 'Error occurred',
      'fileNotFound': 'File not found or access revoked',
      'permissionDenied': 'Storage permission not granted',
      'recoveryPrompt': 'An unsaved document session was recovered',
      'restore': 'Restore',
      'discard': 'Discard',
      'page': 'Page',
      'search': 'Search',
      'edit': 'Edit',
      'cancel': 'Cancel',
      'close': 'Close',
      'searchHint': 'Search documents...',
      'categoryAll': 'All',
      'categoryPdf': 'PDF',
      'categoryOffice': 'Office',
      'categoryImages': 'Images',
      'categoryText': 'Text / CSV',
      'sortBy': 'Sort by',
      'sortNameAsc': 'Name (A-Z)',
      'sortNameDesc': 'Name (Z-A)',
      'sortDateDesc': 'Date (Newest)',
      'sortDateAsc': 'Date (Oldest)',
      'sortSizeDesc': 'Size (Largest)',
      'sortSizeAsc': 'Size (Smallest)',
      'share': 'Share',
      'removeFromList': 'Remove from list',
      'removeDialogTitle': 'Remove from List',
      'removeDialogMessage':
          'Remove this document from the list? The original file will not be deleted.',
      'remove': 'Remove',
      'passwordProtected': 'Password Protected',
      'passwordPrompt':
          'This document is encrypted. Please enter the password to open it.',
      'passwordLabel': 'Password',
      'passwordIncorrect': 'Incorrect password. Please try again.',
      'goToPage': 'Go to page',
      'searchInDocument': 'Search in document',
      'noMatchesFound': 'No matches found',
      'matchesCount': '{current} of {total}',
      'orientation': 'Orientation',
      'orientationAuto': 'Auto Rotate',
      'orientationPortrait': 'Portrait',
      'orientationLandscape': 'Landscape',
      'corruptedTitle': 'Document Corrupted',
      'corruptedMessage':
          'The document cannot be opened because it appears to be damaged or corrupted.',
      'unsupportedTitle': 'Unsupported Format',
      'unsupportedMessage':
          'This file format is currently not supported for viewing.',
      'inaccessibleTitle': 'File Inaccessible',
      'inaccessibleMessage':
          'The file could not be accessed. It may have been moved, deleted, or permission revoked.',
      'lowMemory': 'Low Memory',
      'sheet': 'Sheet',
      'line': 'Line',
      'twoPanelPlaceholder': 'Select a document to preview',
      'retry': 'Retry',
      'openExternally': 'Open Externally',
      'scanDocument': 'Scan Document',
      'cameraUnavailable': 'Camera unavailable or permission denied',
      'importFromGallery': 'Import from Gallery',
      'cropAndPerspective': 'Crop & Perspective',
      'filter': 'Filter',
      'filterOriginal': 'Original',
      'filterMagic': 'Magic Color',
      'filterGrayscale': 'Grayscale',
      'filterBw': 'B&W',
      'rotate': 'Rotate',
      'addPage': 'Add Page',
      'deletePage': 'Delete Page',
      'exportScan': 'Export Document',
      'exportPdf': 'Export as PDF',
      'exportImages': 'Export as Images',
      'qualityLow': 'Low (Compact size)',
      'qualityMedium': 'Medium (Balanced)',
      'qualityHigh': 'High (Best quality)',
      'ocr': 'OCR Text Recognition',
      'ocrResult': 'OCR Result',
      'copyText': 'Copy Text',
      'textCopied': 'Text copied to clipboard',
      'createSearchablePdf': 'Save Searchable PDF',
      'processing': 'Processing...',
      'ocrLanguage': 'OCR Language',
      'languageIndonesian': 'Indonesian',
      'languageEnglish': 'English',
      'languageBoth': 'Indonesian + English',
    },
    'id': {
      'appTitle': 'Document Reviewer',
      'openFile': 'Buka Dokumen',
      'recentDocuments': 'Dokumen Terbaru',
      'favoriteDocuments': 'Favorit',
      'settings': 'Pengaturan',
      'theme': 'Tema',
      'themeSystem': 'Ikuti Sistem',
      'themeLight': 'Mode Terang',
      'themeDark': 'Mode Gelap',
      'noRecentDocuments': 'Belum ada dokumen yang dibuka',
      'noFavorites': 'Belum ada dokumen favorit',
      'save': 'Simpan',
      'saveAs': 'Simpan Sebagai',
      'saving': 'Menyimpan...',
      'saved': 'Dokumen berhasil disimpan',
      'error': 'Terjadi kesalahan',
      'fileNotFound': 'File tidak ditemukan atau izin dicabut',
      'permissionDenied': 'Izin akses dokumen ditolak',
      'recoveryPrompt': 'Sesi dokumen yang belum tersimpan ditemukan',
      'restore': 'Pulihkan',
      'discard': 'Buang',
      'page': 'Halaman',
      'search': 'Cari',
      'edit': 'Ubah',
      'cancel': 'Batal',
      'close': 'Tutup',
      'searchHint': 'Cari dokumen...',
      'categoryAll': 'Semua',
      'categoryPdf': 'PDF',
      'categoryOffice': 'Office',
      'categoryImages': 'Gambar',
      'categoryText': 'Teks / CSV',
      'sortBy': 'Urutkan',
      'sortNameAsc': 'Nama (A-Z)',
      'sortNameDesc': 'Nama (Z-A)',
      'sortDateDesc': 'Tanggal (Terbaru)',
      'sortDateAsc': 'Tanggal (Terlama)',
      'sortSizeDesc': 'Ukuran (Terbesar)',
      'sortSizeAsc': 'Ukuran (Terkecil)',
      'share': 'Bagikan',
      'removeFromList': 'Hapus dari daftar',
      'removeDialogTitle': 'Hapus dari Daftar',
      'removeDialogMessage':
          'Hapus dokumen ini dari daftar? File asli tidak akan dihapus.',
      'remove': 'Hapus',
      'passwordProtected': 'Dokumen Terkunci',
      'passwordPrompt':
          'Dokumen ini terenkripsi. Masukkan kata sandi untuk membukanya.',
      'passwordLabel': 'Kata Sandi',
      'passwordIncorrect': 'Kata sandi salah. Silakan coba lagi.',
      'goToPage': 'Ke halaman',
      'searchInDocument': 'Cari dalam dokumen',
      'noMatchesFound': 'Tidak ada hasil yang cocok',
      'matchesCount': '{current} dari {total}',
      'orientation': 'Orientasi',
      'orientationAuto': 'Rotasi Otomatis',
      'orientationPortrait': 'Tegak (Portrait)',
      'orientationLandscape': 'Mendatar (Landscape)',
      'corruptedTitle': 'Dokumen Rusak',
      'corruptedMessage':
          'Dokumen tidak dapat dibuka karena rusak atau tidak lengkap.',
      'unsupportedTitle': 'Format Tidak Didukung',
      'unsupportedMessage':
          'Format file ini saat ini belum didukung untuk ditampilkan.',
      'inaccessibleTitle': 'File Tidak Dapat Diakses',
      'inaccessibleMessage':
          'File tidak dapat diakses. File mungkin telah dipindah, dihapus, atau izin dicabut.',
      'lowMemory': 'Memori Rendah',
      'sheet': 'Lembar',
      'line': 'Baris',
      'twoPanelPlaceholder': 'Pilih dokumen untuk melihat pratinjau',
      'retry': 'Coba Lagi',
      'openExternally': 'Buka dengan Aplikasi Lain',
      'scanDocument': 'Pindai Dokumen',
      'cameraUnavailable': 'Kamera tidak tersedia atau izin ditolak',
      'importFromGallery': 'Impor dari Galeri',
      'cropAndPerspective': 'Potong & Koreksi Sudut',
      'filter': 'Filter',
      'filterOriginal': 'Asli',
      'filterMagic': 'Warna Ajaib',
      'filterGrayscale': 'Skala Abu',
      'filterBw': 'Hitam Putih',
      'rotate': 'Putar',
      'addPage': 'Tambah Halaman',
      'deletePage': 'Hapus Halaman',
      'exportScan': 'Ekspor Dokumen',
      'exportPdf': 'Ekspor sebagai PDF',
      'exportImages': 'Ekspor sebagai Gambar',
      'qualityLow': 'Rendah (Ukuran kecil)',
      'qualityMedium': 'Sedang (Standar)',
      'qualityHigh': 'Tinggi (Kualitas penuh)',
      'ocr': 'OCR Pindai Teks',
      'ocrResult': 'Hasil OCR',
      'copyText': 'Salin Teks',
      'textCopied': 'Teks disalin ke papan klip',
      'createSearchablePdf': 'Simpan Searchable PDF',
      'processing': 'Memproses...',
      'ocrLanguage': 'Bahasa OCR',
      'languageIndonesian': 'Bahasa Indonesia',
      'languageEnglish': 'Bahasa Inggris',
      'languageBoth': 'Indonesia + Inggris',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String get appTitle => translate('appTitle');
  String get openFile => translate('openFile');
  String get recentDocuments => translate('recentDocuments');
  String get favoriteDocuments => translate('favoriteDocuments');
  String get settings => translate('settings');
  String get theme => translate('theme');
  String get themeSystem => translate('themeSystem');
  String get themeLight => translate('themeLight');
  String get themeDark => translate('themeDark');
  String get noRecentDocuments => translate('noRecentDocuments');
  String get noFavorites => translate('noFavorites');
  String get save => translate('save');
  String get saveAs => translate('saveAs');
  String get saving => translate('saving');
  String get saved => translate('saved');
  String get error => translate('error');
  String get fileNotFound => translate('fileNotFound');
  String get permissionDenied => translate('permissionDenied');
  String get recoveryPrompt => translate('recoveryPrompt');
  String get restore => translate('restore');
  String get discard => translate('discard');
  String get page => translate('page');
  String get search => translate('search');
  String get edit => translate('edit');
  String get cancel => translate('cancel');
  String get close => translate('close');
  String get searchHint => translate('searchHint');
  String get categoryAll => translate('categoryAll');
  String get categoryPdf => translate('categoryPdf');
  String get categoryOffice => translate('categoryOffice');
  String get categoryImages => translate('categoryImages');
  String get categoryText => translate('categoryText');
  String get sortBy => translate('sortBy');
  String get sortNameAsc => translate('sortNameAsc');
  String get sortNameDesc => translate('sortNameDesc');
  String get sortDateDesc => translate('sortDateDesc');
  String get sortDateAsc => translate('sortDateAsc');
  String get sortSizeDesc => translate('sortSizeDesc');
  String get sortSizeAsc => translate('sortSizeAsc');
  String get share => translate('share');
  String get removeFromList => translate('removeFromList');
  String get removeDialogTitle => translate('removeDialogTitle');
  String get removeDialogMessage => translate('removeDialogMessage');
  String get remove => translate('remove');
  String get passwordProtected => translate('passwordProtected');
  String get passwordPrompt => translate('passwordPrompt');
  String get passwordLabel => translate('passwordLabel');
  String get passwordIncorrect => translate('passwordIncorrect');
  String get goToPage => translate('goToPage');
  String get searchInDocument => translate('searchInDocument');
  String get noMatchesFound => translate('noMatchesFound');
  String get matchesCount => translate('matchesCount');
  String get orientation => translate('orientation');
  String get orientationAuto => translate('orientationAuto');
  String get orientationPortrait => translate('orientationPortrait');
  String get orientationLandscape => translate('orientationLandscape');
  String get corruptedTitle => translate('corruptedTitle');
  String get corruptedMessage => translate('corruptedMessage');
  String get unsupportedTitle => translate('unsupportedTitle');
  String get unsupportedMessage => translate('unsupportedMessage');
  String get inaccessibleTitle => translate('inaccessibleTitle');
  String get inaccessibleMessage => translate('inaccessibleMessage');
  String get lowMemory => translate('lowMemory');
  String get sheet => translate('sheet');
  String get line => translate('line');
  String get twoPanelPlaceholder => translate('twoPanelPlaceholder');
  String get retry => translate('retry');
  String get openExternally => translate('openExternally');
  String get scanDocument => translate('scanDocument');
  String get cameraUnavailable => translate('cameraUnavailable');
  String get importFromGallery => translate('importFromGallery');
  String get cropAndPerspective => translate('cropAndPerspective');
  String get filter => translate('filter');
  String get filterOriginal => translate('filterOriginal');
  String get filterMagic => translate('filterMagic');
  String get filterGrayscale => translate('filterGrayscale');
  String get filterBw => translate('filterBw');
  String get rotate => translate('rotate');
  String get addPage => translate('addPage');
  String get deletePage => translate('deletePage');
  String get exportScan => translate('exportScan');
  String get exportPdf => translate('exportPdf');
  String get exportImages => translate('exportImages');
  String get qualityLow => translate('qualityLow');
  String get qualityMedium => translate('qualityMedium');
  String get qualityHigh => translate('qualityHigh');
  String get ocr => translate('ocr');
  String get ocrResult => translate('ocrResult');
  String get copyText => translate('copyText');
  String get textCopied => translate('textCopied');
  String get createSearchablePdf => translate('createSearchablePdf');
  String get processing => translate('processing');
  String get ocrLanguage => translate('ocrLanguage');
  String get languageIndonesian => translate('languageIndonesian');
  String get languageEnglish => translate('languageEnglish');
  String get languageBoth => translate('languageBoth');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
