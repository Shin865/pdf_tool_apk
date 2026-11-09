// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DocumentRecordsTable extends DocumentRecords
    with TableInfo<$DocumentRecordsTable, DocumentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
      'uri', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pageCountMeta =
      const VerificationMeta('pageCount');
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
      'page_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _firstOpenedAtMeta =
      const VerificationMeta('firstOpenedAt');
  @override
  late final GeneratedColumn<DateTime> firstOpenedAt =
      GeneratedColumn<DateTime>('first_opened_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastOpenedAtMeta =
      const VerificationMeta('lastOpenedAt');
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
      'last_opened_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uri,
        displayName,
        mimeType,
        fileSizeBytes,
        pageCount,
        isFavorite,
        firstOpenedAt,
        lastOpenedAt,
        thumbnailPath,
        tags
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_records';
  @override
  VerificationContext validateIntegrity(Insertable<DocumentRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uri')) {
      context.handle(
          _uriMeta, uri.isAcceptableOrUnknown(data['uri']!, _uriMeta));
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    }
    if (data.containsKey('page_count')) {
      context.handle(_pageCountMeta,
          pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('first_opened_at')) {
      context.handle(
          _firstOpenedAtMeta,
          firstOpenedAt.isAcceptableOrUnknown(
              data['first_opened_at']!, _firstOpenedAtMeta));
    } else if (isInserting) {
      context.missing(_firstOpenedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
          _lastOpenedAtMeta,
          lastOpenedAt.isAcceptableOrUnknown(
              data['last_opened_at']!, _lastOpenedAtMeta));
    } else if (isInserting) {
      context.missing(_lastOpenedAtMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uri'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes']),
      pageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_count']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      firstOpenedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}first_opened_at'])!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_opened_at'])!,
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
    );
  }

  @override
  $DocumentRecordsTable createAlias(String alias) {
    return $DocumentRecordsTable(attachedDatabase, alias);
  }
}

class DocumentRecord extends DataClass implements Insertable<DocumentRecord> {
  final int id;
  final String uri;
  final String displayName;
  final String mimeType;
  final int? fileSizeBytes;
  final int? pageCount;
  final bool isFavorite;
  final DateTime firstOpenedAt;
  final DateTime lastOpenedAt;
  final String? thumbnailPath;
  final String? tags;
  const DocumentRecord(
      {required this.id,
      required this.uri,
      required this.displayName,
      required this.mimeType,
      this.fileSizeBytes,
      this.pageCount,
      required this.isFavorite,
      required this.firstOpenedAt,
      required this.lastOpenedAt,
      this.thumbnailPath,
      this.tags});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uri'] = Variable<String>(uri);
    map['display_name'] = Variable<String>(displayName);
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || fileSizeBytes != null) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    }
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['first_opened_at'] = Variable<DateTime>(firstOpenedAt);
    map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    return map;
  }

  DocumentRecordsCompanion toCompanion(bool nullToAbsent) {
    return DocumentRecordsCompanion(
      id: Value(id),
      uri: Value(uri),
      displayName: Value(displayName),
      mimeType: Value(mimeType),
      fileSizeBytes: fileSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSizeBytes),
      pageCount: pageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pageCount),
      isFavorite: Value(isFavorite),
      firstOpenedAt: Value(firstOpenedAt),
      lastOpenedAt: Value(lastOpenedAt),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
    );
  }

  factory DocumentRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRecord(
      id: serializer.fromJson<int>(json['id']),
      uri: serializer.fromJson<String>(json['uri']),
      displayName: serializer.fromJson<String>(json['displayName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      firstOpenedAt: serializer.fromJson<DateTime>(json['firstOpenedAt']),
      lastOpenedAt: serializer.fromJson<DateTime>(json['lastOpenedAt']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      tags: serializer.fromJson<String?>(json['tags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uri': serializer.toJson<String>(uri),
      'displayName': serializer.toJson<String>(displayName),
      'mimeType': serializer.toJson<String>(mimeType),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'pageCount': serializer.toJson<int?>(pageCount),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'firstOpenedAt': serializer.toJson<DateTime>(firstOpenedAt),
      'lastOpenedAt': serializer.toJson<DateTime>(lastOpenedAt),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'tags': serializer.toJson<String?>(tags),
    };
  }

  DocumentRecord copyWith(
          {int? id,
          String? uri,
          String? displayName,
          String? mimeType,
          Value<int?> fileSizeBytes = const Value.absent(),
          Value<int?> pageCount = const Value.absent(),
          bool? isFavorite,
          DateTime? firstOpenedAt,
          DateTime? lastOpenedAt,
          Value<String?> thumbnailPath = const Value.absent(),
          Value<String?> tags = const Value.absent()}) =>
      DocumentRecord(
        id: id ?? this.id,
        uri: uri ?? this.uri,
        displayName: displayName ?? this.displayName,
        mimeType: mimeType ?? this.mimeType,
        fileSizeBytes:
            fileSizeBytes.present ? fileSizeBytes.value : this.fileSizeBytes,
        pageCount: pageCount.present ? pageCount.value : this.pageCount,
        isFavorite: isFavorite ?? this.isFavorite,
        firstOpenedAt: firstOpenedAt ?? this.firstOpenedAt,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        tags: tags.present ? tags.value : this.tags,
      );
  DocumentRecord copyWithCompanion(DocumentRecordsCompanion data) {
    return DocumentRecord(
      id: data.id.present ? data.id.value : this.id,
      uri: data.uri.present ? data.uri.value : this.uri,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      firstOpenedAt: data.firstOpenedAt.present
          ? data.firstOpenedAt.value
          : this.firstOpenedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      tags: data.tags.present ? data.tags.value : this.tags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRecord(')
          ..write('id: $id, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('pageCount: $pageCount, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('firstOpenedAt: $firstOpenedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uri, displayName, mimeType, fileSizeBytes,
      pageCount, isFavorite, firstOpenedAt, lastOpenedAt, thumbnailPath, tags);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRecord &&
          other.id == this.id &&
          other.uri == this.uri &&
          other.displayName == this.displayName &&
          other.mimeType == this.mimeType &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.pageCount == this.pageCount &&
          other.isFavorite == this.isFavorite &&
          other.firstOpenedAt == this.firstOpenedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.thumbnailPath == this.thumbnailPath &&
          other.tags == this.tags);
}

class DocumentRecordsCompanion extends UpdateCompanion<DocumentRecord> {
  final Value<int> id;
  final Value<String> uri;
  final Value<String> displayName;
  final Value<String> mimeType;
  final Value<int?> fileSizeBytes;
  final Value<int?> pageCount;
  final Value<bool> isFavorite;
  final Value<DateTime> firstOpenedAt;
  final Value<DateTime> lastOpenedAt;
  final Value<String?> thumbnailPath;
  final Value<String?> tags;
  const DocumentRecordsCompanion({
    this.id = const Value.absent(),
    this.uri = const Value.absent(),
    this.displayName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.firstOpenedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.tags = const Value.absent(),
  });
  DocumentRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String uri,
    required String displayName,
    required String mimeType,
    this.fileSizeBytes = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required DateTime firstOpenedAt,
    required DateTime lastOpenedAt,
    this.thumbnailPath = const Value.absent(),
    this.tags = const Value.absent(),
  })  : uri = Value(uri),
        displayName = Value(displayName),
        mimeType = Value(mimeType),
        firstOpenedAt = Value(firstOpenedAt),
        lastOpenedAt = Value(lastOpenedAt);
  static Insertable<DocumentRecord> custom({
    Expression<int>? id,
    Expression<String>? uri,
    Expression<String>? displayName,
    Expression<String>? mimeType,
    Expression<int>? fileSizeBytes,
    Expression<int>? pageCount,
    Expression<bool>? isFavorite,
    Expression<DateTime>? firstOpenedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<String>? thumbnailPath,
    Expression<String>? tags,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uri != null) 'uri': uri,
      if (displayName != null) 'display_name': displayName,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (pageCount != null) 'page_count': pageCount,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (firstOpenedAt != null) 'first_opened_at': firstOpenedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (tags != null) 'tags': tags,
    });
  }

  DocumentRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uri,
      Value<String>? displayName,
      Value<String>? mimeType,
      Value<int?>? fileSizeBytes,
      Value<int?>? pageCount,
      Value<bool>? isFavorite,
      Value<DateTime>? firstOpenedAt,
      Value<DateTime>? lastOpenedAt,
      Value<String?>? thumbnailPath,
      Value<String?>? tags}) {
    return DocumentRecordsCompanion(
      id: id ?? this.id,
      uri: uri ?? this.uri,
      displayName: displayName ?? this.displayName,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      pageCount: pageCount ?? this.pageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      firstOpenedAt: firstOpenedAt ?? this.firstOpenedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      tags: tags ?? this.tags,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (firstOpenedAt.present) {
      map['first_opened_at'] = Variable<DateTime>(firstOpenedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRecordsCompanion(')
          ..write('id: $id, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('pageCount: $pageCount, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('firstOpenedAt: $firstOpenedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }
}

class $RecentDocumentsTable extends RecentDocuments
    with TableInfo<$RecentDocumentsTable, RecentDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
      'document_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES document_records (id)'));
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastPageIndexMeta =
      const VerificationMeta('lastPageIndex');
  @override
  late final GeneratedColumn<int> lastPageIndex = GeneratedColumn<int>(
      'last_page_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastScrollOffsetMeta =
      const VerificationMeta('lastScrollOffset');
  @override
  late final GeneratedColumn<double> lastScrollOffset = GeneratedColumn<double>(
      'last_scroll_offset', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastZoomLevelMeta =
      const VerificationMeta('lastZoomLevel');
  @override
  late final GeneratedColumn<double> lastZoomLevel = GeneratedColumn<double>(
      'last_zoom_level', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        documentId,
        openedAt,
        lastPageIndex,
        lastScrollOffset,
        lastZoomLevel
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_documents';
  @override
  VerificationContext validateIntegrity(Insertable<RecentDocument> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document_id')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['document_id']!, _documentIdMeta));
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(_openedAtMeta,
          openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta));
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('last_page_index')) {
      context.handle(
          _lastPageIndexMeta,
          lastPageIndex.isAcceptableOrUnknown(
              data['last_page_index']!, _lastPageIndexMeta));
    }
    if (data.containsKey('last_scroll_offset')) {
      context.handle(
          _lastScrollOffsetMeta,
          lastScrollOffset.isAcceptableOrUnknown(
              data['last_scroll_offset']!, _lastScrollOffsetMeta));
    }
    if (data.containsKey('last_zoom_level')) {
      context.handle(
          _lastZoomLevelMeta,
          lastZoomLevel.isAcceptableOrUnknown(
              data['last_zoom_level']!, _lastZoomLevelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecentDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentDocument(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}document_id'])!,
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opened_at'])!,
      lastPageIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_page_index'])!,
      lastScrollOffset: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}last_scroll_offset'])!,
      lastZoomLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}last_zoom_level'])!,
    );
  }

  @override
  $RecentDocumentsTable createAlias(String alias) {
    return $RecentDocumentsTable(attachedDatabase, alias);
  }
}

class RecentDocument extends DataClass implements Insertable<RecentDocument> {
  final int id;
  final int documentId;
  final DateTime openedAt;
  final int lastPageIndex;
  final double lastScrollOffset;
  final double lastZoomLevel;
  const RecentDocument(
      {required this.id,
      required this.documentId,
      required this.openedAt,
      required this.lastPageIndex,
      required this.lastScrollOffset,
      required this.lastZoomLevel});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document_id'] = Variable<int>(documentId);
    map['opened_at'] = Variable<DateTime>(openedAt);
    map['last_page_index'] = Variable<int>(lastPageIndex);
    map['last_scroll_offset'] = Variable<double>(lastScrollOffset);
    map['last_zoom_level'] = Variable<double>(lastZoomLevel);
    return map;
  }

  RecentDocumentsCompanion toCompanion(bool nullToAbsent) {
    return RecentDocumentsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      openedAt: Value(openedAt),
      lastPageIndex: Value(lastPageIndex),
      lastScrollOffset: Value(lastScrollOffset),
      lastZoomLevel: Value(lastZoomLevel),
    );
  }

  factory RecentDocument.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentDocument(
      id: serializer.fromJson<int>(json['id']),
      documentId: serializer.fromJson<int>(json['documentId']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      lastPageIndex: serializer.fromJson<int>(json['lastPageIndex']),
      lastScrollOffset: serializer.fromJson<double>(json['lastScrollOffset']),
      lastZoomLevel: serializer.fromJson<double>(json['lastZoomLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'documentId': serializer.toJson<int>(documentId),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'lastPageIndex': serializer.toJson<int>(lastPageIndex),
      'lastScrollOffset': serializer.toJson<double>(lastScrollOffset),
      'lastZoomLevel': serializer.toJson<double>(lastZoomLevel),
    };
  }

  RecentDocument copyWith(
          {int? id,
          int? documentId,
          DateTime? openedAt,
          int? lastPageIndex,
          double? lastScrollOffset,
          double? lastZoomLevel}) =>
      RecentDocument(
        id: id ?? this.id,
        documentId: documentId ?? this.documentId,
        openedAt: openedAt ?? this.openedAt,
        lastPageIndex: lastPageIndex ?? this.lastPageIndex,
        lastScrollOffset: lastScrollOffset ?? this.lastScrollOffset,
        lastZoomLevel: lastZoomLevel ?? this.lastZoomLevel,
      );
  RecentDocument copyWithCompanion(RecentDocumentsCompanion data) {
    return RecentDocument(
      id: data.id.present ? data.id.value : this.id,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      lastPageIndex: data.lastPageIndex.present
          ? data.lastPageIndex.value
          : this.lastPageIndex,
      lastScrollOffset: data.lastScrollOffset.present
          ? data.lastScrollOffset.value
          : this.lastScrollOffset,
      lastZoomLevel: data.lastZoomLevel.present
          ? data.lastZoomLevel.value
          : this.lastZoomLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentDocument(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('openedAt: $openedAt, ')
          ..write('lastPageIndex: $lastPageIndex, ')
          ..write('lastScrollOffset: $lastScrollOffset, ')
          ..write('lastZoomLevel: $lastZoomLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, documentId, openedAt, lastPageIndex, lastScrollOffset, lastZoomLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentDocument &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.openedAt == this.openedAt &&
          other.lastPageIndex == this.lastPageIndex &&
          other.lastScrollOffset == this.lastScrollOffset &&
          other.lastZoomLevel == this.lastZoomLevel);
}

class RecentDocumentsCompanion extends UpdateCompanion<RecentDocument> {
  final Value<int> id;
  final Value<int> documentId;
  final Value<DateTime> openedAt;
  final Value<int> lastPageIndex;
  final Value<double> lastScrollOffset;
  final Value<double> lastZoomLevel;
  const RecentDocumentsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.lastPageIndex = const Value.absent(),
    this.lastScrollOffset = const Value.absent(),
    this.lastZoomLevel = const Value.absent(),
  });
  RecentDocumentsCompanion.insert({
    this.id = const Value.absent(),
    required int documentId,
    required DateTime openedAt,
    this.lastPageIndex = const Value.absent(),
    this.lastScrollOffset = const Value.absent(),
    this.lastZoomLevel = const Value.absent(),
  })  : documentId = Value(documentId),
        openedAt = Value(openedAt);
  static Insertable<RecentDocument> custom({
    Expression<int>? id,
    Expression<int>? documentId,
    Expression<DateTime>? openedAt,
    Expression<int>? lastPageIndex,
    Expression<double>? lastScrollOffset,
    Expression<double>? lastZoomLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (openedAt != null) 'opened_at': openedAt,
      if (lastPageIndex != null) 'last_page_index': lastPageIndex,
      if (lastScrollOffset != null) 'last_scroll_offset': lastScrollOffset,
      if (lastZoomLevel != null) 'last_zoom_level': lastZoomLevel,
    });
  }

  RecentDocumentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? documentId,
      Value<DateTime>? openedAt,
      Value<int>? lastPageIndex,
      Value<double>? lastScrollOffset,
      Value<double>? lastZoomLevel}) {
    return RecentDocumentsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      openedAt: openedAt ?? this.openedAt,
      lastPageIndex: lastPageIndex ?? this.lastPageIndex,
      lastScrollOffset: lastScrollOffset ?? this.lastScrollOffset,
      lastZoomLevel: lastZoomLevel ?? this.lastZoomLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (lastPageIndex.present) {
      map['last_page_index'] = Variable<int>(lastPageIndex.value);
    }
    if (lastScrollOffset.present) {
      map['last_scroll_offset'] = Variable<double>(lastScrollOffset.value);
    }
    if (lastZoomLevel.present) {
      map['last_zoom_level'] = Variable<double>(lastZoomLevel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('openedAt: $openedAt, ')
          ..write('lastPageIndex: $lastPageIndex, ')
          ..write('lastScrollOffset: $lastScrollOffset, ')
          ..write('lastZoomLevel: $lastZoomLevel')
          ..write(')'))
        .toString();
  }
}

class $DocumentBookmarksTable extends DocumentBookmarks
    with TableInfo<$DocumentBookmarksTable, DocumentBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
      'document_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES document_records (id)'));
  static const VerificationMeta _pageIndexMeta =
      const VerificationMeta('pageIndex');
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
      'page_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, documentId, pageIndex, label, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<DocumentBookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document_id')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['document_id']!, _documentIdMeta));
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(_pageIndexMeta,
          pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta));
    } else if (isInserting) {
      context.missing(_pageIndexMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentBookmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}document_id'])!,
      pageIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_index'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DocumentBookmarksTable createAlias(String alias) {
    return $DocumentBookmarksTable(attachedDatabase, alias);
  }
}

class DocumentBookmark extends DataClass
    implements Insertable<DocumentBookmark> {
  final int id;
  final int documentId;
  final int pageIndex;
  final String? label;
  final String? note;
  final DateTime createdAt;
  const DocumentBookmark(
      {required this.id,
      required this.documentId,
      required this.pageIndex,
      this.label,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document_id'] = Variable<int>(documentId);
    map['page_index'] = Variable<int>(pageIndex);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DocumentBookmarksCompanion toCompanion(bool nullToAbsent) {
    return DocumentBookmarksCompanion(
      id: Value(id),
      documentId: Value(documentId),
      pageIndex: Value(pageIndex),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory DocumentBookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentBookmark(
      id: serializer.fromJson<int>(json['id']),
      documentId: serializer.fromJson<int>(json['documentId']),
      pageIndex: serializer.fromJson<int>(json['pageIndex']),
      label: serializer.fromJson<String?>(json['label']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'documentId': serializer.toJson<int>(documentId),
      'pageIndex': serializer.toJson<int>(pageIndex),
      'label': serializer.toJson<String?>(label),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DocumentBookmark copyWith(
          {int? id,
          int? documentId,
          int? pageIndex,
          Value<String?> label = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      DocumentBookmark(
        id: id ?? this.id,
        documentId: documentId ?? this.documentId,
        pageIndex: pageIndex ?? this.pageIndex,
        label: label.present ? label.value : this.label,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  DocumentBookmark copyWithCompanion(DocumentBookmarksCompanion data) {
    return DocumentBookmark(
      id: data.id.present ? data.id.value : this.id,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      label: data.label.present ? data.label.value : this.label,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentBookmark(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, documentId, pageIndex, label, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentBookmark &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.pageIndex == this.pageIndex &&
          other.label == this.label &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class DocumentBookmarksCompanion extends UpdateCompanion<DocumentBookmark> {
  final Value<int> id;
  final Value<int> documentId;
  final Value<int> pageIndex;
  final Value<String?> label;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const DocumentBookmarksCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DocumentBookmarksCompanion.insert({
    this.id = const Value.absent(),
    required int documentId,
    required int pageIndex,
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
  })  : documentId = Value(documentId),
        pageIndex = Value(pageIndex),
        createdAt = Value(createdAt);
  static Insertable<DocumentBookmark> custom({
    Expression<int>? id,
    Expression<int>? documentId,
    Expression<int>? pageIndex,
    Expression<String>? label,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (pageIndex != null) 'page_index': pageIndex,
      if (label != null) 'label': label,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DocumentBookmarksCompanion copyWith(
      {Value<int>? id,
      Value<int>? documentId,
      Value<int>? pageIndex,
      Value<String?>? label,
      Value<String?>? note,
      Value<DateTime>? createdAt}) {
    return DocumentBookmarksCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageIndex: pageIndex ?? this.pageIndex,
      label: label ?? this.label,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DocumentVersionsTable extends DocumentVersions
    with TableInfo<$DocumentVersionsTable, DocumentVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
      'document_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES document_records (id)'));
  static const VerificationMeta _localCopyPathMeta =
      const VerificationMeta('localCopyPath');
  @override
  late final GeneratedColumn<String> localCopyPath = GeneratedColumn<String>(
      'local_copy_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionNumberMeta =
      const VerificationMeta('versionNumber');
  @override
  late final GeneratedColumn<int> versionNumber = GeneratedColumn<int>(
      'version_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _changeDescriptionMeta =
      const VerificationMeta('changeDescription');
  @override
  late final GeneratedColumn<String> changeDescription =
      GeneratedColumn<String>('change_description', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isWrittenBackMeta =
      const VerificationMeta('isWrittenBack');
  @override
  late final GeneratedColumn<bool> isWrittenBack = GeneratedColumn<bool>(
      'is_written_back', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_written_back" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        documentId,
        localCopyPath,
        versionNumber,
        changeDescription,
        createdAt,
        isWrittenBack
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_versions';
  @override
  VerificationContext validateIntegrity(Insertable<DocumentVersion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document_id')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['document_id']!, _documentIdMeta));
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('local_copy_path')) {
      context.handle(
          _localCopyPathMeta,
          localCopyPath.isAcceptableOrUnknown(
              data['local_copy_path']!, _localCopyPathMeta));
    } else if (isInserting) {
      context.missing(_localCopyPathMeta);
    }
    if (data.containsKey('version_number')) {
      context.handle(
          _versionNumberMeta,
          versionNumber.isAcceptableOrUnknown(
              data['version_number']!, _versionNumberMeta));
    } else if (isInserting) {
      context.missing(_versionNumberMeta);
    }
    if (data.containsKey('change_description')) {
      context.handle(
          _changeDescriptionMeta,
          changeDescription.isAcceptableOrUnknown(
              data['change_description']!, _changeDescriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_written_back')) {
      context.handle(
          _isWrittenBackMeta,
          isWrittenBack.isAcceptableOrUnknown(
              data['is_written_back']!, _isWrittenBackMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentVersion(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}document_id'])!,
      localCopyPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_copy_path'])!,
      versionNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version_number'])!,
      changeDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}change_description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isWrittenBack: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_written_back'])!,
    );
  }

  @override
  $DocumentVersionsTable createAlias(String alias) {
    return $DocumentVersionsTable(attachedDatabase, alias);
  }
}

class DocumentVersion extends DataClass implements Insertable<DocumentVersion> {
  final int id;
  final int documentId;

  /// Path to the local working copy (not the SAF URI).
  final String localCopyPath;
  final int versionNumber;
  final String? changeDescription;
  final DateTime createdAt;
  final bool isWrittenBack;
  const DocumentVersion(
      {required this.id,
      required this.documentId,
      required this.localCopyPath,
      required this.versionNumber,
      this.changeDescription,
      required this.createdAt,
      required this.isWrittenBack});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document_id'] = Variable<int>(documentId);
    map['local_copy_path'] = Variable<String>(localCopyPath);
    map['version_number'] = Variable<int>(versionNumber);
    if (!nullToAbsent || changeDescription != null) {
      map['change_description'] = Variable<String>(changeDescription);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_written_back'] = Variable<bool>(isWrittenBack);
    return map;
  }

  DocumentVersionsCompanion toCompanion(bool nullToAbsent) {
    return DocumentVersionsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      localCopyPath: Value(localCopyPath),
      versionNumber: Value(versionNumber),
      changeDescription: changeDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(changeDescription),
      createdAt: Value(createdAt),
      isWrittenBack: Value(isWrittenBack),
    );
  }

  factory DocumentVersion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentVersion(
      id: serializer.fromJson<int>(json['id']),
      documentId: serializer.fromJson<int>(json['documentId']),
      localCopyPath: serializer.fromJson<String>(json['localCopyPath']),
      versionNumber: serializer.fromJson<int>(json['versionNumber']),
      changeDescription:
          serializer.fromJson<String?>(json['changeDescription']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isWrittenBack: serializer.fromJson<bool>(json['isWrittenBack']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'documentId': serializer.toJson<int>(documentId),
      'localCopyPath': serializer.toJson<String>(localCopyPath),
      'versionNumber': serializer.toJson<int>(versionNumber),
      'changeDescription': serializer.toJson<String?>(changeDescription),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isWrittenBack': serializer.toJson<bool>(isWrittenBack),
    };
  }

  DocumentVersion copyWith(
          {int? id,
          int? documentId,
          String? localCopyPath,
          int? versionNumber,
          Value<String?> changeDescription = const Value.absent(),
          DateTime? createdAt,
          bool? isWrittenBack}) =>
      DocumentVersion(
        id: id ?? this.id,
        documentId: documentId ?? this.documentId,
        localCopyPath: localCopyPath ?? this.localCopyPath,
        versionNumber: versionNumber ?? this.versionNumber,
        changeDescription: changeDescription.present
            ? changeDescription.value
            : this.changeDescription,
        createdAt: createdAt ?? this.createdAt,
        isWrittenBack: isWrittenBack ?? this.isWrittenBack,
      );
  DocumentVersion copyWithCompanion(DocumentVersionsCompanion data) {
    return DocumentVersion(
      id: data.id.present ? data.id.value : this.id,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      localCopyPath: data.localCopyPath.present
          ? data.localCopyPath.value
          : this.localCopyPath,
      versionNumber: data.versionNumber.present
          ? data.versionNumber.value
          : this.versionNumber,
      changeDescription: data.changeDescription.present
          ? data.changeDescription.value
          : this.changeDescription,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isWrittenBack: data.isWrittenBack.present
          ? data.isWrittenBack.value
          : this.isWrittenBack,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentVersion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('localCopyPath: $localCopyPath, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('changeDescription: $changeDescription, ')
          ..write('createdAt: $createdAt, ')
          ..write('isWrittenBack: $isWrittenBack')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, documentId, localCopyPath, versionNumber,
      changeDescription, createdAt, isWrittenBack);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentVersion &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.localCopyPath == this.localCopyPath &&
          other.versionNumber == this.versionNumber &&
          other.changeDescription == this.changeDescription &&
          other.createdAt == this.createdAt &&
          other.isWrittenBack == this.isWrittenBack);
}

class DocumentVersionsCompanion extends UpdateCompanion<DocumentVersion> {
  final Value<int> id;
  final Value<int> documentId;
  final Value<String> localCopyPath;
  final Value<int> versionNumber;
  final Value<String?> changeDescription;
  final Value<DateTime> createdAt;
  final Value<bool> isWrittenBack;
  const DocumentVersionsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.localCopyPath = const Value.absent(),
    this.versionNumber = const Value.absent(),
    this.changeDescription = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isWrittenBack = const Value.absent(),
  });
  DocumentVersionsCompanion.insert({
    this.id = const Value.absent(),
    required int documentId,
    required String localCopyPath,
    required int versionNumber,
    this.changeDescription = const Value.absent(),
    required DateTime createdAt,
    this.isWrittenBack = const Value.absent(),
  })  : documentId = Value(documentId),
        localCopyPath = Value(localCopyPath),
        versionNumber = Value(versionNumber),
        createdAt = Value(createdAt);
  static Insertable<DocumentVersion> custom({
    Expression<int>? id,
    Expression<int>? documentId,
    Expression<String>? localCopyPath,
    Expression<int>? versionNumber,
    Expression<String>? changeDescription,
    Expression<DateTime>? createdAt,
    Expression<bool>? isWrittenBack,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (localCopyPath != null) 'local_copy_path': localCopyPath,
      if (versionNumber != null) 'version_number': versionNumber,
      if (changeDescription != null) 'change_description': changeDescription,
      if (createdAt != null) 'created_at': createdAt,
      if (isWrittenBack != null) 'is_written_back': isWrittenBack,
    });
  }

  DocumentVersionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? documentId,
      Value<String>? localCopyPath,
      Value<int>? versionNumber,
      Value<String?>? changeDescription,
      Value<DateTime>? createdAt,
      Value<bool>? isWrittenBack}) {
    return DocumentVersionsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      localCopyPath: localCopyPath ?? this.localCopyPath,
      versionNumber: versionNumber ?? this.versionNumber,
      changeDescription: changeDescription ?? this.changeDescription,
      createdAt: createdAt ?? this.createdAt,
      isWrittenBack: isWrittenBack ?? this.isWrittenBack,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    if (localCopyPath.present) {
      map['local_copy_path'] = Variable<String>(localCopyPath.value);
    }
    if (versionNumber.present) {
      map['version_number'] = Variable<int>(versionNumber.value);
    }
    if (changeDescription.present) {
      map['change_description'] = Variable<String>(changeDescription.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isWrittenBack.present) {
      map['is_written_back'] = Variable<bool>(isWrittenBack.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentVersionsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('localCopyPath: $localCopyPath, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('changeDescription: $changeDescription, ')
          ..write('createdAt: $createdAt, ')
          ..write('isWrittenBack: $isWrittenBack')
          ..write(')'))
        .toString();
  }
}

class $AppPreferencesTable extends AppPreferences
    with TableInfo<$AppPreferencesTable, AppPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preferences';
  @override
  VerificationContext validateIntegrity(Insertable<AppPreference> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreference(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppPreferencesTable createAlias(String alias) {
    return $AppPreferencesTable(attachedDatabase, alias);
  }
}

class AppPreference extends DataClass implements Insertable<AppPreference> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppPreference(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppPreferencesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppPreference.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppPreference copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppPreference(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppPreference copyWithCompanion(AppPreferencesCompanion data) {
    return AppPreference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreference(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreference &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppPreferencesCompanion extends UpdateCompanion<AppPreference> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppPreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppPreferencesCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<AppPreference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppPreferencesCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppPreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentRecordsTable documentRecords =
      $DocumentRecordsTable(this);
  late final $RecentDocumentsTable recentDocuments =
      $RecentDocumentsTable(this);
  late final $DocumentBookmarksTable documentBookmarks =
      $DocumentBookmarksTable(this);
  late final $DocumentVersionsTable documentVersions =
      $DocumentVersionsTable(this);
  late final $AppPreferencesTable appPreferences = $AppPreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        documentRecords,
        recentDocuments,
        documentBookmarks,
        documentVersions,
        appPreferences
      ];
}

typedef $$DocumentRecordsTableCreateCompanionBuilder = DocumentRecordsCompanion
    Function({
  Value<int> id,
  required String uri,
  required String displayName,
  required String mimeType,
  Value<int?> fileSizeBytes,
  Value<int?> pageCount,
  Value<bool> isFavorite,
  required DateTime firstOpenedAt,
  required DateTime lastOpenedAt,
  Value<String?> thumbnailPath,
  Value<String?> tags,
});
typedef $$DocumentRecordsTableUpdateCompanionBuilder = DocumentRecordsCompanion
    Function({
  Value<int> id,
  Value<String> uri,
  Value<String> displayName,
  Value<String> mimeType,
  Value<int?> fileSizeBytes,
  Value<int?> pageCount,
  Value<bool> isFavorite,
  Value<DateTime> firstOpenedAt,
  Value<DateTime> lastOpenedAt,
  Value<String?> thumbnailPath,
  Value<String?> tags,
});

final class $$DocumentRecordsTableReferences extends BaseReferences<
    _$AppDatabase, $DocumentRecordsTable, DocumentRecord> {
  $$DocumentRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecentDocumentsTable, List<RecentDocument>>
      _recentDocumentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recentDocuments,
              aliasName: $_aliasNameGenerator(
                  db.documentRecords.id, db.recentDocuments.documentId));

  $$RecentDocumentsTableProcessedTableManager get recentDocumentsRefs {
    final manager =
        $$RecentDocumentsTableTableManager($_db, $_db.recentDocuments)
            .filter((f) => f.documentId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_recentDocumentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DocumentBookmarksTable, List<DocumentBookmark>>
      _documentBookmarksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.documentBookmarks,
              aliasName: $_aliasNameGenerator(
                  db.documentRecords.id, db.documentBookmarks.documentId));

  $$DocumentBookmarksTableProcessedTableManager get documentBookmarksRefs {
    final manager =
        $$DocumentBookmarksTableTableManager($_db, $_db.documentBookmarks)
            .filter((f) => f.documentId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_documentBookmarksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DocumentVersionsTable, List<DocumentVersion>>
      _documentVersionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.documentVersions,
              aliasName: $_aliasNameGenerator(
                  db.documentRecords.id, db.documentVersions.documentId));

  $$DocumentVersionsTableProcessedTableManager get documentVersionsRefs {
    final manager =
        $$DocumentVersionsTableTableManager($_db, $_db.documentVersions)
            .filter((f) => f.documentId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_documentVersionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DocumentRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentRecordsTable> {
  $$DocumentRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uri => $composableBuilder(
      column: $table.uri, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageCount => $composableBuilder(
      column: $table.pageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get firstOpenedAt => $composableBuilder(
      column: $table.firstOpenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  Expression<bool> recentDocumentsRefs(
      Expression<bool> Function($$RecentDocumentsTableFilterComposer f) f) {
    final $$RecentDocumentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recentDocuments,
        getReferencedColumn: (t) => t.documentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecentDocumentsTableFilterComposer(
              $db: $db,
              $table: $db.recentDocuments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> documentBookmarksRefs(
      Expression<bool> Function($$DocumentBookmarksTableFilterComposer f) f) {
    final $$DocumentBookmarksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.documentBookmarks,
        getReferencedColumn: (t) => t.documentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentBookmarksTableFilterComposer(
              $db: $db,
              $table: $db.documentBookmarks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> documentVersionsRefs(
      Expression<bool> Function($$DocumentVersionsTableFilterComposer f) f) {
    final $$DocumentVersionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.documentVersions,
        getReferencedColumn: (t) => t.documentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentVersionsTableFilterComposer(
              $db: $db,
              $table: $db.documentVersions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DocumentRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentRecordsTable> {
  $$DocumentRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uri => $composableBuilder(
      column: $table.uri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageCount => $composableBuilder(
      column: $table.pageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get firstOpenedAt => $composableBuilder(
      column: $table.firstOpenedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));
}

class $$DocumentRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentRecordsTable> {
  $$DocumentRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<DateTime> get firstOpenedAt => $composableBuilder(
      column: $table.firstOpenedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  Expression<T> recentDocumentsRefs<T extends Object>(
      Expression<T> Function($$RecentDocumentsTableAnnotationComposer a) f) {
    final $$RecentDocumentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recentDocuments,
        getReferencedColumn: (t) => t.documentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecentDocumentsTableAnnotationComposer(
              $db: $db,
              $table: $db.recentDocuments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> documentBookmarksRefs<T extends Object>(
      Expression<T> Function($$DocumentBookmarksTableAnnotationComposer a) f) {
    final $$DocumentBookmarksTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.documentBookmarks,
            getReferencedColumn: (t) => t.documentId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DocumentBookmarksTableAnnotationComposer(
                  $db: $db,
                  $table: $db.documentBookmarks,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> documentVersionsRefs<T extends Object>(
      Expression<T> Function($$DocumentVersionsTableAnnotationComposer a) f) {
    final $$DocumentVersionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.documentVersions,
        getReferencedColumn: (t) => t.documentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentVersionsTableAnnotationComposer(
              $db: $db,
              $table: $db.documentVersions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DocumentRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentRecordsTable,
    DocumentRecord,
    $$DocumentRecordsTableFilterComposer,
    $$DocumentRecordsTableOrderingComposer,
    $$DocumentRecordsTableAnnotationComposer,
    $$DocumentRecordsTableCreateCompanionBuilder,
    $$DocumentRecordsTableUpdateCompanionBuilder,
    (DocumentRecord, $$DocumentRecordsTableReferences),
    DocumentRecord,
    PrefetchHooks Function(
        {bool recentDocumentsRefs,
        bool documentBookmarksRefs,
        bool documentVersionsRefs})> {
  $$DocumentRecordsTableTableManager(
      _$AppDatabase db, $DocumentRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uri = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<int?> fileSizeBytes = const Value.absent(),
            Value<int?> pageCount = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime> firstOpenedAt = const Value.absent(),
            Value<DateTime> lastOpenedAt = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String?> tags = const Value.absent(),
          }) =>
              DocumentRecordsCompanion(
            id: id,
            uri: uri,
            displayName: displayName,
            mimeType: mimeType,
            fileSizeBytes: fileSizeBytes,
            pageCount: pageCount,
            isFavorite: isFavorite,
            firstOpenedAt: firstOpenedAt,
            lastOpenedAt: lastOpenedAt,
            thumbnailPath: thumbnailPath,
            tags: tags,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uri,
            required String displayName,
            required String mimeType,
            Value<int?> fileSizeBytes = const Value.absent(),
            Value<int?> pageCount = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            required DateTime firstOpenedAt,
            required DateTime lastOpenedAt,
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String?> tags = const Value.absent(),
          }) =>
              DocumentRecordsCompanion.insert(
            id: id,
            uri: uri,
            displayName: displayName,
            mimeType: mimeType,
            fileSizeBytes: fileSizeBytes,
            pageCount: pageCount,
            isFavorite: isFavorite,
            firstOpenedAt: firstOpenedAt,
            lastOpenedAt: lastOpenedAt,
            thumbnailPath: thumbnailPath,
            tags: tags,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DocumentRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {recentDocumentsRefs = false,
              documentBookmarksRefs = false,
              documentVersionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recentDocumentsRefs) db.recentDocuments,
                if (documentBookmarksRefs) db.documentBookmarks,
                if (documentVersionsRefs) db.documentVersions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recentDocumentsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$DocumentRecordsTableReferences
                            ._recentDocumentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DocumentRecordsTableReferences(db, table, p0)
                                .recentDocumentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.documentId == item.id),
                        typedResults: items),
                  if (documentBookmarksRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$DocumentRecordsTableReferences
                            ._documentBookmarksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DocumentRecordsTableReferences(db, table, p0)
                                .documentBookmarksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.documentId == item.id),
                        typedResults: items),
                  if (documentVersionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$DocumentRecordsTableReferences
                            ._documentVersionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DocumentRecordsTableReferences(db, table, p0)
                                .documentVersionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.documentId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DocumentRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentRecordsTable,
    DocumentRecord,
    $$DocumentRecordsTableFilterComposer,
    $$DocumentRecordsTableOrderingComposer,
    $$DocumentRecordsTableAnnotationComposer,
    $$DocumentRecordsTableCreateCompanionBuilder,
    $$DocumentRecordsTableUpdateCompanionBuilder,
    (DocumentRecord, $$DocumentRecordsTableReferences),
    DocumentRecord,
    PrefetchHooks Function(
        {bool recentDocumentsRefs,
        bool documentBookmarksRefs,
        bool documentVersionsRefs})>;
typedef $$RecentDocumentsTableCreateCompanionBuilder = RecentDocumentsCompanion
    Function({
  Value<int> id,
  required int documentId,
  required DateTime openedAt,
  Value<int> lastPageIndex,
  Value<double> lastScrollOffset,
  Value<double> lastZoomLevel,
});
typedef $$RecentDocumentsTableUpdateCompanionBuilder = RecentDocumentsCompanion
    Function({
  Value<int> id,
  Value<int> documentId,
  Value<DateTime> openedAt,
  Value<int> lastPageIndex,
  Value<double> lastScrollOffset,
  Value<double> lastZoomLevel,
});

final class $$RecentDocumentsTableReferences extends BaseReferences<
    _$AppDatabase, $RecentDocumentsTable, RecentDocument> {
  $$RecentDocumentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DocumentRecordsTable _documentIdTable(_$AppDatabase db) =>
      db.documentRecords.createAlias($_aliasNameGenerator(
          db.recentDocuments.documentId, db.documentRecords.id));

  $$DocumentRecordsTableProcessedTableManager get documentId {
    final manager =
        $$DocumentRecordsTableTableManager($_db, $_db.documentRecords)
            .filter((f) => f.id($_item.documentId));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecentDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $RecentDocumentsTable> {
  $$RecentDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPageIndex => $composableBuilder(
      column: $table.lastPageIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lastScrollOffset => $composableBuilder(
      column: $table.lastScrollOffset,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lastZoomLevel => $composableBuilder(
      column: $table.lastZoomLevel, builder: (column) => ColumnFilters(column));

  $$DocumentRecordsTableFilterComposer get documentId {
    final $$DocumentRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.documentId,
        referencedTable: $db.documentRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRecordsTableFilterComposer(
              $db: $db,
              $table: $db.documentRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecentDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentDocumentsTable> {
  $$RecentDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPageIndex => $composableBuilder(
      column: $table.lastPageIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lastScrollOffset => $composableBuilder(
      column: $table.lastScrollOffset,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lastZoomLevel => $composableBuilder(
      column: $table.lastZoomLevel,
      builder: (column) => ColumnOrderings(column));

  $$DocumentRecordsTableOrderingComposer get documentId {
    final $$DocumentRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.documentId,
        referencedTable: $db.documentRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.documentRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecentDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentDocumentsTable> {
  $$RecentDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<int> get lastPageIndex => $composableBuilder(
      column: $table.lastPageIndex, builder: (column) => column);

  GeneratedColumn<double> get lastScrollOffset => $composableBuilder(
      column: $table.lastScrollOffset, builder: (column) => column);

  GeneratedColumn<double> get lastZoomLevel => $composableBuilder(
      column: $table.lastZoomLevel, builder: (column) => column);

  $$DocumentRecordsTableAnnotationComposer get documentId {
    final $$DocumentRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.documentId,
        referencedTable: $db.documentRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.documentRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecentDocumentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecentDocumentsTable,
    RecentDocument,
    $$RecentDocumentsTableFilterComposer,
    $$RecentDocumentsTableOrderingComposer,
    $$RecentDocumentsTableAnnotationComposer,
    $$RecentDocumentsTableCreateCompanionBuilder,
    $$RecentDocumentsTableUpdateCompanionBuilder,
    (RecentDocument, $$RecentDocumentsTableReferences),
    RecentDocument,
    PrefetchHooks Function({bool documentId})> {
  $$RecentDocumentsTableTableManager(
      _$AppDatabase db, $RecentDocumentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> documentId = const Value.absent(),
            Value<DateTime> openedAt = const Value.absent(),
            Value<int> lastPageIndex = const Value.absent(),
            Value<double> lastScrollOffset = const Value.absent(),
            Value<double> lastZoomLevel = const Value.absent(),
          }) =>
              RecentDocumentsCompanion(
            id: id,
            documentId: documentId,
            openedAt: openedAt,
            lastPageIndex: lastPageIndex,
            lastScrollOffset: lastScrollOffset,
            lastZoomLevel: lastZoomLevel,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int documentId,
            required DateTime openedAt,
            Value<int> lastPageIndex = const Value.absent(),
            Value<double> lastScrollOffset = const Value.absent(),
            Value<double> lastZoomLevel = const Value.absent(),
          }) =>
              RecentDocumentsCompanion.insert(
            id: id,
            documentId: documentId,
            openedAt: openedAt,
            lastPageIndex: lastPageIndex,
            lastScrollOffset: lastScrollOffset,
            lastZoomLevel: lastZoomLevel,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RecentDocumentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (documentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.documentId,
                    referencedTable:
                        $$RecentDocumentsTableReferences._documentIdTable(db),
                    referencedColumn: $$RecentDocumentsTableReferences
                        ._documentIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RecentDocumentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecentDocumentsTable,
    RecentDocument,
    $$RecentDocumentsTableFilterComposer,
    $$RecentDocumentsTableOrderingComposer,
    $$RecentDocumentsTableAnnotationComposer,
    $$RecentDocumentsTableCreateCompanionBuilder,
    $$RecentDocumentsTableUpdateCompanionBuilder,
    (RecentDocument, $$RecentDocumentsTableReferences),
    RecentDocument,
    PrefetchHooks Function({bool documentId})>;
typedef $$DocumentBookmarksTableCreateCompanionBuilder
    = DocumentBookmarksCompanion Function({
  Value<int> id,
  required int documentId,
  required int pageIndex,
  Value<String?> label,
  Value<String?> note,
  required DateTime createdAt,
});
typedef $$DocumentBookmarksTableUpdateCompanionBuilder
    = DocumentBookmarksCompanion Function({
  Value<int> id,
  Value<int> documentId,
  Value<int> pageIndex,
  Value<String?> label,
  Value<String?> note,
  Value<DateTime> createdAt,
});

final class $$DocumentBookmarksTableReferences extends BaseReferences<
    _$AppDatabase, $DocumentBookmarksTable, DocumentBookmark> {
  $$DocumentBookmarksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DocumentRecordsTable _documentIdTable(_$AppDatabase db) =>
      db.documentRecords.createAlias($_aliasNameGenerator(
          db.documentBookmarks.documentId, db.documentRecords.id));

  $$DocumentRecordsTableProcessedTableManager get documentId {
    final manager =
        $$DocumentRecordsTableTableManager($_db, $_db.documentRecords)
            .filter((f) => f.id($_item.documentId));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DocumentBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentBookmarksTable> {
  $$DocumentBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageIndex => $composableBuilder(
      column: $table.pageIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$DocumentRecordsTableFilterComposer get documentId {
    final $$DocumentRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.documentId,
        referencedTable: $db.documentRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRecordsTableFilterComposer(
              $db: $db,
              $table: $db.documentRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentBookmarksTable> {
  $$DocumentBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageIndex => $composableBuilder(
      column: $table.pageIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$DocumentRecordsTableOrderingComposer get documentId {
    final $$DocumentRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.documentId,
        referencedTable: $db.documentRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.documentRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentBookmarksTable> {
  $$DocumentBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DocumentRecordsTableAnnotationComposer get documentId {
    final $$DocumentRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.documentId,
        referencedTable: $db.documentRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.documentRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentBookmarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentBookmarksTable,
    DocumentBookmark,
    $$DocumentBookmarksTableFilterComposer,
    $$DocumentBookmarksTableOrderingComposer,
    $$DocumentBookmarksTableAnnotationComposer,
    $$DocumentBookmarksTableCreateCompanionBuilder,
    $$DocumentBookmarksTableUpdateCompanionBuilder,
    (DocumentBookmark, $$DocumentBookmarksTableReferences),
    DocumentBookmark,
    PrefetchHooks Function({bool documentId})> {
  $$DocumentBookmarksTableTableManager(
      _$AppDatabase db, $DocumentBookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentBookmarksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> documentId = const Value.absent(),
            Value<int> pageIndex = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DocumentBookmarksCompanion(
            id: id,
            documentId: documentId,
            pageIndex: pageIndex,
            label: label,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int documentId,
            required int pageIndex,
            Value<String?> label = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
          }) =>
              DocumentBookmarksCompanion.insert(
            id: id,
            documentId: documentId,
            pageIndex: pageIndex,
            label: label,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DocumentBookmarksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (documentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.documentId,
                    referencedTable:
                        $$DocumentBookmarksTableReferences._documentIdTable(db),
                    referencedColumn: $$DocumentBookmarksTableReferences
                        ._documentIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DocumentBookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentBookmarksTable,
    DocumentBookmark,
    $$DocumentBookmarksTableFilterComposer,
    $$DocumentBookmarksTableOrderingComposer,
    $$DocumentBookmarksTableAnnotationComposer,
    $$DocumentBookmarksTableCreateCompanionBuilder,
    $$DocumentBookmarksTableUpdateCompanionBuilder,
    (DocumentBookmark, $$DocumentBookmarksTableReferences),
    DocumentBookmark,
    PrefetchHooks Function({bool documentId})>;
typedef $$DocumentVersionsTableCreateCompanionBuilder
    = DocumentVersionsCompanion Function({
  Value<int> id,
  required int documentId,
  required String localCopyPath,
  required int versionNumber,
  Value<String?> changeDescription,
  required DateTime createdAt,
  Value<bool> isWrittenBack,
});
typedef $$DocumentVersionsTableUpdateCompanionBuilder
    = DocumentVersionsCompanion Function({
  Value<int> id,
  Value<int> documentId,
  Value<String> localCopyPath,
  Value<int> versionNumber,
  Value<String?> changeDescription,
  Value<DateTime> createdAt,
  Value<bool> isWrittenBack,
});

final class $$DocumentVersionsTableReferences extends BaseReferences<
    _$AppDatabase, $DocumentVersionsTable, DocumentVersion> {
  $$DocumentVersionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DocumentRecordsTable _documentIdTable(_$AppDatabase db) =>
      db.documentRecords.createAlias($_aliasNameGenerator(
          db.documentVersions.documentId, db.documentRecords.id));

  $$DocumentRecordsTableProcessedTableManager get documentId {
    final manager =
        $$DocumentRecordsTableTableManager($_db, $_db.documentRecords)
            .filter((f) => f.id($_item.documentId));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DocumentVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentVersionsTable> {
  $$DocumentVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localCopyPath => $composableBuilder(
      column: $table.localCopyPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get versionNumber => $composableBuilder(
      column: $table.versionNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get changeDescription => $composableBuilder(
      column: $table.changeDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWrittenBack => $composableBuilder(
      column: $table.isWrittenBack, builder: (column) => ColumnFilters(column));

  $$DocumentRecordsTableFilterComposer get documentId {
    final $$DocumentRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.documentId,
        referencedTable: $db.documentRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRecordsTableFilterComposer(
              $db: $db,
              $table: $db.documentRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentVersionsTable> {
  $$DocumentVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localCopyPath => $composableBuilder(
      column: $table.localCopyPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get versionNumber => $composableBuilder(
      column: $table.versionNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get changeDescription => $composableBuilder(
      column: $table.changeDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWrittenBack => $composableBuilder(
      column: $table.isWrittenBack,
      builder: (column) => ColumnOrderings(column));

  $$DocumentRecordsTableOrderingComposer get documentId {
    final $$DocumentRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.documentId,
        referencedTable: $db.documentRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.documentRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentVersionsTable> {
  $$DocumentVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localCopyPath => $composableBuilder(
      column: $table.localCopyPath, builder: (column) => column);

  GeneratedColumn<int> get versionNumber => $composableBuilder(
      column: $table.versionNumber, builder: (column) => column);

  GeneratedColumn<String> get changeDescription => $composableBuilder(
      column: $table.changeDescription, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isWrittenBack => $composableBuilder(
      column: $table.isWrittenBack, builder: (column) => column);

  $$DocumentRecordsTableAnnotationComposer get documentId {
    final $$DocumentRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.documentId,
        referencedTable: $db.documentRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.documentRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentVersionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentVersionsTable,
    DocumentVersion,
    $$DocumentVersionsTableFilterComposer,
    $$DocumentVersionsTableOrderingComposer,
    $$DocumentVersionsTableAnnotationComposer,
    $$DocumentVersionsTableCreateCompanionBuilder,
    $$DocumentVersionsTableUpdateCompanionBuilder,
    (DocumentVersion, $$DocumentVersionsTableReferences),
    DocumentVersion,
    PrefetchHooks Function({bool documentId})> {
  $$DocumentVersionsTableTableManager(
      _$AppDatabase db, $DocumentVersionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> documentId = const Value.absent(),
            Value<String> localCopyPath = const Value.absent(),
            Value<int> versionNumber = const Value.absent(),
            Value<String?> changeDescription = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isWrittenBack = const Value.absent(),
          }) =>
              DocumentVersionsCompanion(
            id: id,
            documentId: documentId,
            localCopyPath: localCopyPath,
            versionNumber: versionNumber,
            changeDescription: changeDescription,
            createdAt: createdAt,
            isWrittenBack: isWrittenBack,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int documentId,
            required String localCopyPath,
            required int versionNumber,
            Value<String?> changeDescription = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isWrittenBack = const Value.absent(),
          }) =>
              DocumentVersionsCompanion.insert(
            id: id,
            documentId: documentId,
            localCopyPath: localCopyPath,
            versionNumber: versionNumber,
            changeDescription: changeDescription,
            createdAt: createdAt,
            isWrittenBack: isWrittenBack,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DocumentVersionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (documentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.documentId,
                    referencedTable:
                        $$DocumentVersionsTableReferences._documentIdTable(db),
                    referencedColumn: $$DocumentVersionsTableReferences
                        ._documentIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DocumentVersionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentVersionsTable,
    DocumentVersion,
    $$DocumentVersionsTableFilterComposer,
    $$DocumentVersionsTableOrderingComposer,
    $$DocumentVersionsTableAnnotationComposer,
    $$DocumentVersionsTableCreateCompanionBuilder,
    $$DocumentVersionsTableUpdateCompanionBuilder,
    (DocumentVersion, $$DocumentVersionsTableReferences),
    DocumentVersion,
    PrefetchHooks Function({bool documentId})>;
typedef $$AppPreferencesTableCreateCompanionBuilder = AppPreferencesCompanion
    Function({
  required String key,
  required String value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AppPreferencesTableUpdateCompanionBuilder = AppPreferencesCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AppPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppPreferencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppPreferencesTable,
    AppPreference,
    $$AppPreferencesTableFilterComposer,
    $$AppPreferencesTableOrderingComposer,
    $$AppPreferencesTableAnnotationComposer,
    $$AppPreferencesTableCreateCompanionBuilder,
    $$AppPreferencesTableUpdateCompanionBuilder,
    (
      AppPreference,
      BaseReferences<_$AppDatabase, $AppPreferencesTable, AppPreference>
    ),
    AppPreference,
    PrefetchHooks Function()> {
  $$AppPreferencesTableTableManager(
      _$AppDatabase db, $AppPreferencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppPreferencesCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppPreferencesCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppPreferencesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppPreferencesTable,
    AppPreference,
    $$AppPreferencesTableFilterComposer,
    $$AppPreferencesTableOrderingComposer,
    $$AppPreferencesTableAnnotationComposer,
    $$AppPreferencesTableCreateCompanionBuilder,
    $$AppPreferencesTableUpdateCompanionBuilder,
    (
      AppPreference,
      BaseReferences<_$AppDatabase, $AppPreferencesTable, AppPreference>
    ),
    AppPreference,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentRecordsTableTableManager get documentRecords =>
      $$DocumentRecordsTableTableManager(_db, _db.documentRecords);
  $$RecentDocumentsTableTableManager get recentDocuments =>
      $$RecentDocumentsTableTableManager(_db, _db.recentDocuments);
  $$DocumentBookmarksTableTableManager get documentBookmarks =>
      $$DocumentBookmarksTableTableManager(_db, _db.documentBookmarks);
  $$DocumentVersionsTableTableManager get documentVersions =>
      $$DocumentVersionsTableTableManager(_db, _db.documentVersions);
  $$AppPreferencesTableTableManager get appPreferences =>
      $$AppPreferencesTableTableManager(_db, _db.appPreferences);
}
