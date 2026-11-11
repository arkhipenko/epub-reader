// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _authorsMeta = const VerificationMeta('authors');
  @override
  late final GeneratedColumn<String> authors = GeneratedColumn<String>(
    'authors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastXPointerMeta = const VerificationMeta('lastXPointer');
  @override
  late final GeneratedColumn<String> lastXPointer = GeneratedColumn<String>(
    'last_x_pointer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta('progress');
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta('lastOpenedAt');
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesMeta = const VerificationMeta('series');
  @override
  late final GeneratedColumn<String> series = GeneratedColumn<String>(
    'series',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _seriesNumberMeta = const VerificationMeta('seriesNumber');
  @override
  late final GeneratedColumn<int> seriesNumber = GeneratedColumn<int>(
    'series_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta('coverPath');
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileModifiedMeta = const VerificationMeta('fileModified');
  @override
  late final GeneratedColumn<DateTime> fileModified = GeneratedColumn<DateTime>(
    'file_modified',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta('favorite');
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("favorite" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missingMeta = const VerificationMeta('missing');
  @override
  late final GeneratedColumn<bool> missing = GeneratedColumn<bool>(
    'missing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("missing" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _settingsMeta = const VerificationMeta('settings');
  @override
  late final GeneratedColumn<String> settings = GeneratedColumn<String>(
    'settings',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    title,
    authors,
    format,
    language,
    lastXPointer,
    progress,
    addedAt,
    lastOpenedAt,
    series,
    seriesNumber,
    description,
    coverPath,
    fileSize,
    fileModified,
    favorite,
    deletedAt,
    missing,
    settings,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(Insertable<Book> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('authors')) {
      context.handle(_authorsMeta, authors.isAcceptableOrUnknown(data['authors']!, _authorsMeta));
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta, format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta, language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    if (data.containsKey('last_x_pointer')) {
      context.handle(_lastXPointerMeta, lastXPointer.isAcceptableOrUnknown(data['last_x_pointer']!, _lastXPointerMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta, progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta, addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(_lastOpenedAtMeta, lastOpenedAt.isAcceptableOrUnknown(data['last_opened_at']!, _lastOpenedAtMeta));
    }
    if (data.containsKey('series')) {
      context.handle(_seriesMeta, series.isAcceptableOrUnknown(data['series']!, _seriesMeta));
    }
    if (data.containsKey('series_number')) {
      context.handle(_seriesNumberMeta, seriesNumber.isAcceptableOrUnknown(data['series_number']!, _seriesNumberMeta));
    }
    if (data.containsKey('description')) {
      context.handle(_descriptionMeta, description.isAcceptableOrUnknown(data['description']!, _descriptionMeta));
    }
    if (data.containsKey('cover_path')) {
      context.handle(_coverPathMeta, coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta));
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta, fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    }
    if (data.containsKey('file_modified')) {
      context.handle(_fileModifiedMeta, fileModified.isAcceptableOrUnknown(data['file_modified']!, _fileModifiedMeta));
    }
    if (data.containsKey('favorite')) {
      context.handle(_favoriteMeta, favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('missing')) {
      context.handle(_missingMeta, missing.isAcceptableOrUnknown(data['missing']!, _missingMeta));
    }
    if (data.containsKey('settings')) {
      context.handle(_settingsMeta, settings.isAcceptableOrUnknown(data['settings']!, _settingsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      authors: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}authors'])!,
      format: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      language: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      lastXPointer: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}last_x_pointer']),
      progress: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}progress'])!,
      addedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      lastOpenedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}last_opened_at']),
      series: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}series'])!,
      seriesNumber: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}series_number'])!,
      description: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      coverPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cover_path']),
      fileSize: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}file_size']),
      fileModified: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}file_modified']),
      favorite: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}favorite'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      missing: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}missing'])!,
      settings: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}settings']),
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  /// KOReader partial MD5 of the file.
  final String id;
  final String path;
  final String title;
  final String authors;
  final String format;
  final String language;

  /// KOReader-compatible XPointer of the last reading position.
  final String? lastXPointer;

  /// Reading progress, 0 to 1 (KOReader percent_finished).
  final double progress;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final String series;
  final int seriesNumber;
  final String description;

  /// Cover image file in app storage, or null when the book has none.
  final String? coverPath;

  /// File size and modification time at the last scan. Null: never scanned.
  final int? fileSize;
  final DateTime? fileModified;
  final bool favorite;

  /// Set when the book is in "Deleted" (Koodo trash).
  final DateTime? deletedAt;

  /// The file was not found at the last scan.
  final bool missing;

  /// Schema 4: advanced settings of this book (BookSettings JSON). Null: all
  /// values are the defaults.
  final String? settings;
  const Book({
    required this.id,
    required this.path,
    required this.title,
    required this.authors,
    required this.format,
    required this.language,
    this.lastXPointer,
    required this.progress,
    required this.addedAt,
    this.lastOpenedAt,
    required this.series,
    required this.seriesNumber,
    required this.description,
    this.coverPath,
    this.fileSize,
    this.fileModified,
    required this.favorite,
    this.deletedAt,
    required this.missing,
    this.settings,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['path'] = Variable<String>(path);
    map['title'] = Variable<String>(title);
    map['authors'] = Variable<String>(authors);
    map['format'] = Variable<String>(format);
    map['language'] = Variable<String>(language);
    if (!nullToAbsent || lastXPointer != null) {
      map['last_x_pointer'] = Variable<String>(lastXPointer);
    }
    map['progress'] = Variable<double>(progress);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    map['series'] = Variable<String>(series);
    map['series_number'] = Variable<int>(seriesNumber);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || fileModified != null) {
      map['file_modified'] = Variable<DateTime>(fileModified);
    }
    map['favorite'] = Variable<bool>(favorite);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['missing'] = Variable<bool>(missing);
    if (!nullToAbsent || settings != null) {
      map['settings'] = Variable<String>(settings);
    }
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      path: Value(path),
      title: Value(title),
      authors: Value(authors),
      format: Value(format),
      language: Value(language),
      lastXPointer: lastXPointer == null && nullToAbsent ? const Value.absent() : Value(lastXPointer),
      progress: Value(progress),
      addedAt: Value(addedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent ? const Value.absent() : Value(lastOpenedAt),
      series: Value(series),
      seriesNumber: Value(seriesNumber),
      description: Value(description),
      coverPath: coverPath == null && nullToAbsent ? const Value.absent() : Value(coverPath),
      fileSize: fileSize == null && nullToAbsent ? const Value.absent() : Value(fileSize),
      fileModified: fileModified == null && nullToAbsent ? const Value.absent() : Value(fileModified),
      favorite: Value(favorite),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      missing: Value(missing),
      settings: settings == null && nullToAbsent ? const Value.absent() : Value(settings),
    );
  }

  factory Book.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<String>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      title: serializer.fromJson<String>(json['title']),
      authors: serializer.fromJson<String>(json['authors']),
      format: serializer.fromJson<String>(json['format']),
      language: serializer.fromJson<String>(json['language']),
      lastXPointer: serializer.fromJson<String?>(json['lastXPointer']),
      progress: serializer.fromJson<double>(json['progress']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      series: serializer.fromJson<String>(json['series']),
      seriesNumber: serializer.fromJson<int>(json['seriesNumber']),
      description: serializer.fromJson<String>(json['description']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      fileModified: serializer.fromJson<DateTime?>(json['fileModified']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      missing: serializer.fromJson<bool>(json['missing']),
      settings: serializer.fromJson<String?>(json['settings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'path': serializer.toJson<String>(path),
      'title': serializer.toJson<String>(title),
      'authors': serializer.toJson<String>(authors),
      'format': serializer.toJson<String>(format),
      'language': serializer.toJson<String>(language),
      'lastXPointer': serializer.toJson<String?>(lastXPointer),
      'progress': serializer.toJson<double>(progress),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'series': serializer.toJson<String>(series),
      'seriesNumber': serializer.toJson<int>(seriesNumber),
      'description': serializer.toJson<String>(description),
      'coverPath': serializer.toJson<String?>(coverPath),
      'fileSize': serializer.toJson<int?>(fileSize),
      'fileModified': serializer.toJson<DateTime?>(fileModified),
      'favorite': serializer.toJson<bool>(favorite),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'missing': serializer.toJson<bool>(missing),
      'settings': serializer.toJson<String?>(settings),
    };
  }

  Book copyWith({
    String? id,
    String? path,
    String? title,
    String? authors,
    String? format,
    String? language,
    Value<String?> lastXPointer = const Value.absent(),
    double? progress,
    DateTime? addedAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    String? series,
    int? seriesNumber,
    String? description,
    Value<String?> coverPath = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    Value<DateTime?> fileModified = const Value.absent(),
    bool? favorite,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? missing,
    Value<String?> settings = const Value.absent(),
  }) => Book(
    id: id ?? this.id,
    path: path ?? this.path,
    title: title ?? this.title,
    authors: authors ?? this.authors,
    format: format ?? this.format,
    language: language ?? this.language,
    lastXPointer: lastXPointer.present ? lastXPointer.value : this.lastXPointer,
    progress: progress ?? this.progress,
    addedAt: addedAt ?? this.addedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    series: series ?? this.series,
    seriesNumber: seriesNumber ?? this.seriesNumber,
    description: description ?? this.description,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    fileModified: fileModified.present ? fileModified.value : this.fileModified,
    favorite: favorite ?? this.favorite,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    missing: missing ?? this.missing,
    settings: settings.present ? settings.value : this.settings,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      title: data.title.present ? data.title.value : this.title,
      authors: data.authors.present ? data.authors.value : this.authors,
      format: data.format.present ? data.format.value : this.format,
      language: data.language.present ? data.language.value : this.language,
      lastXPointer: data.lastXPointer.present ? data.lastXPointer.value : this.lastXPointer,
      progress: data.progress.present ? data.progress.value : this.progress,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastOpenedAt: data.lastOpenedAt.present ? data.lastOpenedAt.value : this.lastOpenedAt,
      series: data.series.present ? data.series.value : this.series,
      seriesNumber: data.seriesNumber.present ? data.seriesNumber.value : this.seriesNumber,
      description: data.description.present ? data.description.value : this.description,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      fileModified: data.fileModified.present ? data.fileModified.value : this.fileModified,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      missing: data.missing.present ? data.missing.value : this.missing,
      settings: data.settings.present ? data.settings.value : this.settings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('authors: $authors, ')
          ..write('format: $format, ')
          ..write('language: $language, ')
          ..write('lastXPointer: $lastXPointer, ')
          ..write('progress: $progress, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('series: $series, ')
          ..write('seriesNumber: $seriesNumber, ')
          ..write('description: $description, ')
          ..write('coverPath: $coverPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileModified: $fileModified, ')
          ..write('favorite: $favorite, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('missing: $missing, ')
          ..write('settings: $settings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    path,
    title,
    authors,
    format,
    language,
    lastXPointer,
    progress,
    addedAt,
    lastOpenedAt,
    series,
    seriesNumber,
    description,
    coverPath,
    fileSize,
    fileModified,
    favorite,
    deletedAt,
    missing,
    settings,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.path == this.path &&
          other.title == this.title &&
          other.authors == this.authors &&
          other.format == this.format &&
          other.language == this.language &&
          other.lastXPointer == this.lastXPointer &&
          other.progress == this.progress &&
          other.addedAt == this.addedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.series == this.series &&
          other.seriesNumber == this.seriesNumber &&
          other.description == this.description &&
          other.coverPath == this.coverPath &&
          other.fileSize == this.fileSize &&
          other.fileModified == this.fileModified &&
          other.favorite == this.favorite &&
          other.deletedAt == this.deletedAt &&
          other.missing == this.missing &&
          other.settings == this.settings);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> id;
  final Value<String> path;
  final Value<String> title;
  final Value<String> authors;
  final Value<String> format;
  final Value<String> language;
  final Value<String?> lastXPointer;
  final Value<double> progress;
  final Value<DateTime> addedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<String> series;
  final Value<int> seriesNumber;
  final Value<String> description;
  final Value<String?> coverPath;
  final Value<int?> fileSize;
  final Value<DateTime?> fileModified;
  final Value<bool> favorite;
  final Value<DateTime?> deletedAt;
  final Value<bool> missing;
  final Value<String?> settings;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.title = const Value.absent(),
    this.authors = const Value.absent(),
    this.format = const Value.absent(),
    this.language = const Value.absent(),
    this.lastXPointer = const Value.absent(),
    this.progress = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.series = const Value.absent(),
    this.seriesNumber = const Value.absent(),
    this.description = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileModified = const Value.absent(),
    this.favorite = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.missing = const Value.absent(),
    this.settings = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String path,
    this.title = const Value.absent(),
    this.authors = const Value.absent(),
    this.format = const Value.absent(),
    this.language = const Value.absent(),
    this.lastXPointer = const Value.absent(),
    this.progress = const Value.absent(),
    required DateTime addedAt,
    this.lastOpenedAt = const Value.absent(),
    this.series = const Value.absent(),
    this.seriesNumber = const Value.absent(),
    this.description = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileModified = const Value.absent(),
    this.favorite = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.missing = const Value.absent(),
    this.settings = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       path = Value(path),
       addedAt = Value(addedAt);
  static Insertable<Book> custom({
    Expression<String>? id,
    Expression<String>? path,
    Expression<String>? title,
    Expression<String>? authors,
    Expression<String>? format,
    Expression<String>? language,
    Expression<String>? lastXPointer,
    Expression<double>? progress,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<String>? series,
    Expression<int>? seriesNumber,
    Expression<String>? description,
    Expression<String>? coverPath,
    Expression<int>? fileSize,
    Expression<DateTime>? fileModified,
    Expression<bool>? favorite,
    Expression<DateTime>? deletedAt,
    Expression<bool>? missing,
    Expression<String>? settings,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (title != null) 'title': title,
      if (authors != null) 'authors': authors,
      if (format != null) 'format': format,
      if (language != null) 'language': language,
      if (lastXPointer != null) 'last_x_pointer': lastXPointer,
      if (progress != null) 'progress': progress,
      if (addedAt != null) 'added_at': addedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (series != null) 'series': series,
      if (seriesNumber != null) 'series_number': seriesNumber,
      if (description != null) 'description': description,
      if (coverPath != null) 'cover_path': coverPath,
      if (fileSize != null) 'file_size': fileSize,
      if (fileModified != null) 'file_modified': fileModified,
      if (favorite != null) 'favorite': favorite,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (missing != null) 'missing': missing,
      if (settings != null) 'settings': settings,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<String>? path,
    Value<String>? title,
    Value<String>? authors,
    Value<String>? format,
    Value<String>? language,
    Value<String?>? lastXPointer,
    Value<double>? progress,
    Value<DateTime>? addedAt,
    Value<DateTime?>? lastOpenedAt,
    Value<String>? series,
    Value<int>? seriesNumber,
    Value<String>? description,
    Value<String?>? coverPath,
    Value<int?>? fileSize,
    Value<DateTime?>? fileModified,
    Value<bool>? favorite,
    Value<DateTime?>? deletedAt,
    Value<bool>? missing,
    Value<String?>? settings,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      format: format ?? this.format,
      language: language ?? this.language,
      lastXPointer: lastXPointer ?? this.lastXPointer,
      progress: progress ?? this.progress,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      series: series ?? this.series,
      seriesNumber: seriesNumber ?? this.seriesNumber,
      description: description ?? this.description,
      coverPath: coverPath ?? this.coverPath,
      fileSize: fileSize ?? this.fileSize,
      fileModified: fileModified ?? this.fileModified,
      favorite: favorite ?? this.favorite,
      deletedAt: deletedAt ?? this.deletedAt,
      missing: missing ?? this.missing,
      settings: settings ?? this.settings,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (authors.present) {
      map['authors'] = Variable<String>(authors.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (lastXPointer.present) {
      map['last_x_pointer'] = Variable<String>(lastXPointer.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (series.present) {
      map['series'] = Variable<String>(series.value);
    }
    if (seriesNumber.present) {
      map['series_number'] = Variable<int>(seriesNumber.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (fileModified.present) {
      map['file_modified'] = Variable<DateTime>(fileModified.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (missing.present) {
      map['missing'] = Variable<bool>(missing.value);
    }
    if (settings.present) {
      map['settings'] = Variable<String>(settings.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('authors: $authors, ')
          ..write('format: $format, ')
          ..write('language: $language, ')
          ..write('lastXPointer: $lastXPointer, ')
          ..write('progress: $progress, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('series: $series, ')
          ..write('seriesNumber: $seriesNumber, ')
          ..write('description: $description, ')
          ..write('coverPath: $coverPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileModified: $fileModified, ')
          ..write('favorite: $favorite, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('missing: $missing, ')
          ..write('settings: $settings, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrefsTable extends Prefs with TableInfo<$PrefsTable, Pref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefs';
  @override
  VerificationContext validateIntegrity(Insertable<Pref> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Pref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pref(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $PrefsTable createAlias(String alias) {
    return $PrefsTable(attachedDatabase, alias);
  }
}

class Pref extends DataClass implements Insertable<Pref> {
  final String key;
  final String value;
  const Pref({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PrefsCompanion toCompanion(bool nullToAbsent) {
    return PrefsCompanion(key: Value(key), value: Value(value));
  }

  factory Pref.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pref(key: serializer.fromJson<String>(json['key']), value: serializer.fromJson<String>(json['value']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'key': serializer.toJson<String>(key), 'value': serializer.toJson<String>(value)};
  }

  Pref copyWith({String? key, String? value}) => Pref(key: key ?? this.key, value: value ?? this.value);
  Pref copyWithCompanion(PrefsCompanion data) {
    return Pref(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pref(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Pref && other.key == this.key && other.value == this.value);
}

class PrefsCompanion extends UpdateCompanion<Pref> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PrefsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefsCompanion.insert({required String key, required String value, this.rowid = const Value.absent()})
    : key = Value(key),
      value = Value(value);
  static Insertable<Pref> custom({Expression<String>? key, Expression<String>? value, Expression<int>? rowid}) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrefsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return PrefsCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrefsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShelvesTable extends Shelves with TableInfo<$ShelvesTable, Shelf> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShelvesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelves';
  @override
  VerificationContext validateIntegrity(Insertable<Shelf> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shelf map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shelf(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ShelvesTable createAlias(String alias) {
    return $ShelvesTable(attachedDatabase, alias);
  }
}

class Shelf extends DataClass implements Insertable<Shelf> {
  final int id;
  final String name;
  final DateTime createdAt;
  const Shelf({required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ShelvesCompanion toCompanion(bool nullToAbsent) {
    return ShelvesCompanion(id: Value(id), name: Value(name), createdAt: Value(createdAt));
  }

  factory Shelf.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shelf(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Shelf copyWith({int? id, String? name, DateTime? createdAt}) =>
      Shelf(id: id ?? this.id, name: name ?? this.name, createdAt: createdAt ?? this.createdAt);
  Shelf copyWithCompanion(ShelvesCompanion data) {
    return Shelf(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shelf(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shelf && other.id == this.id && other.name == this.name && other.createdAt == this.createdAt);
}

class ShelvesCompanion extends UpdateCompanion<Shelf> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const ShelvesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ShelvesCompanion.insert({this.id = const Value.absent(), required String name, required DateTime createdAt})
    : name = Value(name),
      createdAt = Value(createdAt);
  static Insertable<Shelf> custom({Expression<int>? id, Expression<String>? name, Expression<DateTime>? createdAt}) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ShelvesCompanion copyWith({Value<int>? id, Value<String>? name, Value<DateTime>? createdAt}) {
    return ShelvesCompanion(id: id ?? this.id, name: name ?? this.name, createdAt: createdAt ?? this.createdAt);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShelvesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ShelfBooksTable extends ShelfBooks with TableInfo<$ShelfBooksTable, ShelfBook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShelfBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shelfIdMeta = const VerificationMeta('shelfId');
  @override
  late final GeneratedColumn<int> shelfId = GeneratedColumn<int>(
    'shelf_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES shelves (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES books (id) ON DELETE CASCADE'),
  );
  @override
  List<GeneratedColumn> get $columns => [shelfId, bookId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelf_books';
  @override
  VerificationContext validateIntegrity(Insertable<ShelfBook> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shelf_id')) {
      context.handle(_shelfIdMeta, shelfId.isAcceptableOrUnknown(data['shelf_id']!, _shelfIdMeta));
    } else if (isInserting) {
      context.missing(_shelfIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta, bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shelfId, bookId};
  @override
  ShelfBook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShelfBook(
      shelfId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}shelf_id'])!,
      bookId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
    );
  }

  @override
  $ShelfBooksTable createAlias(String alias) {
    return $ShelfBooksTable(attachedDatabase, alias);
  }
}

class ShelfBook extends DataClass implements Insertable<ShelfBook> {
  final int shelfId;
  final String bookId;
  const ShelfBook({required this.shelfId, required this.bookId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shelf_id'] = Variable<int>(shelfId);
    map['book_id'] = Variable<String>(bookId);
    return map;
  }

  ShelfBooksCompanion toCompanion(bool nullToAbsent) {
    return ShelfBooksCompanion(shelfId: Value(shelfId), bookId: Value(bookId));
  }

  factory ShelfBook.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShelfBook(
      shelfId: serializer.fromJson<int>(json['shelfId']),
      bookId: serializer.fromJson<String>(json['bookId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'shelfId': serializer.toJson<int>(shelfId), 'bookId': serializer.toJson<String>(bookId)};
  }

  ShelfBook copyWith({int? shelfId, String? bookId}) =>
      ShelfBook(shelfId: shelfId ?? this.shelfId, bookId: bookId ?? this.bookId);
  ShelfBook copyWithCompanion(ShelfBooksCompanion data) {
    return ShelfBook(
      shelfId: data.shelfId.present ? data.shelfId.value : this.shelfId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShelfBook(')
          ..write('shelfId: $shelfId, ')
          ..write('bookId: $bookId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shelfId, bookId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ShelfBook && other.shelfId == this.shelfId && other.bookId == this.bookId);
}

class ShelfBooksCompanion extends UpdateCompanion<ShelfBook> {
  final Value<int> shelfId;
  final Value<String> bookId;
  final Value<int> rowid;
  const ShelfBooksCompanion({
    this.shelfId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShelfBooksCompanion.insert({required int shelfId, required String bookId, this.rowid = const Value.absent()})
    : shelfId = Value(shelfId),
      bookId = Value(bookId);
  static Insertable<ShelfBook> custom({Expression<int>? shelfId, Expression<String>? bookId, Expression<int>? rowid}) {
    return RawValuesInsertable({
      if (shelfId != null) 'shelf_id': shelfId,
      if (bookId != null) 'book_id': bookId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShelfBooksCompanion copyWith({Value<int>? shelfId, Value<String>? bookId, Value<int>? rowid}) {
    return ShelfBooksCompanion(
      shelfId: shelfId ?? this.shelfId,
      bookId: bookId ?? this.bookId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shelfId.present) {
      map['shelf_id'] = Variable<int>(shelfId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShelfBooksCompanion(')
          ..write('shelfId: $shelfId, ')
          ..write('bookId: $bookId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OpdsCatalogsTable extends OpdsCatalogs with TableInfo<$OpdsCatalogsTable, OpdsCatalog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OpdsCatalogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, url, username, password, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'opds_catalogs';
  @override
  VerificationContext validateIntegrity(Insertable<OpdsCatalog> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('url')) {
      context.handle(_urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta, username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta, password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OpdsCatalog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OpdsCatalog(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      url: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      username: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}username']),
      password: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}password']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $OpdsCatalogsTable createAlias(String alias) {
    return $OpdsCatalogsTable(attachedDatabase, alias);
  }
}

class OpdsCatalog extends DataClass implements Insertable<OpdsCatalog> {
  final int id;
  final String title;
  final String url;
  final String? username;

  /// Stored in the app database (personal use, private app storage).
  final String? password;
  final DateTime createdAt;
  const OpdsCatalog({
    required this.id,
    required this.title,
    required this.url,
    this.username,
    this.password,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OpdsCatalogsCompanion toCompanion(bool nullToAbsent) {
    return OpdsCatalogsCompanion(
      id: Value(id),
      title: Value(title),
      url: Value(url),
      username: username == null && nullToAbsent ? const Value.absent() : Value(username),
      password: password == null && nullToAbsent ? const Value.absent() : Value(password),
      createdAt: Value(createdAt),
    );
  }

  factory OpdsCatalog.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OpdsCatalog(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String>(json['url']),
      username: serializer.fromJson<String?>(json['username']),
      password: serializer.fromJson<String?>(json['password']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String>(url),
      'username': serializer.toJson<String?>(username),
      'password': serializer.toJson<String?>(password),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OpdsCatalog copyWith({
    int? id,
    String? title,
    String? url,
    Value<String?> username = const Value.absent(),
    Value<String?> password = const Value.absent(),
    DateTime? createdAt,
  }) => OpdsCatalog(
    id: id ?? this.id,
    title: title ?? this.title,
    url: url ?? this.url,
    username: username.present ? username.value : this.username,
    password: password.present ? password.value : this.password,
    createdAt: createdAt ?? this.createdAt,
  );
  OpdsCatalog copyWithCompanion(OpdsCatalogsCompanion data) {
    return OpdsCatalog(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OpdsCatalog(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, url, username, password, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OpdsCatalog &&
          other.id == this.id &&
          other.title == this.title &&
          other.url == this.url &&
          other.username == this.username &&
          other.password == this.password &&
          other.createdAt == this.createdAt);
}

class OpdsCatalogsCompanion extends UpdateCompanion<OpdsCatalog> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> url;
  final Value<String?> username;
  final Value<String?> password;
  final Value<DateTime> createdAt;
  const OpdsCatalogsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OpdsCatalogsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String url,
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    required DateTime createdAt,
  }) : title = Value(title),
       url = Value(url),
       createdAt = Value(createdAt);
  static Insertable<OpdsCatalog> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? url,
    Expression<String>? username,
    Expression<String>? password,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OpdsCatalogsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? url,
    Value<String?>? username,
    Value<String?>? password,
    Value<DateTime>? createdAt,
  }) {
    return OpdsCatalogsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OpdsCatalogsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations with TableInfo<$AnnotationsTable, Annotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES books (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<String> page = GeneratedColumn<String>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pos0Meta = const VerificationMeta('pos0');
  @override
  late final GeneratedColumn<String> pos0 = GeneratedColumn<String>(
    'pos0',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pos1Meta = const VerificationMeta('pos1');
  @override
  late final GeneratedColumn<String> pos1 = GeneratedColumn<String>(
    'pos1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta('textContent');
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('yellow'),
  );
  static const VerificationMeta _drawerMeta = const VerificationMeta('drawer');
  @override
  late final GeneratedColumn<String> drawer = GeneratedColumn<String>(
    'drawer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('lighten'),
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta('chapter');
  @override
  late final GeneratedColumn<String> chapter = GeneratedColumn<String>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pagenoMeta = const VerificationMeta('pageno');
  @override
  late final GeneratedColumn<int> pageno = GeneratedColumn<int>(
    'pageno',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _datetimeMeta = const VerificationMeta('datetime');
  @override
  late final GeneratedColumn<DateTime> datetime = GeneratedColumn<DateTime>(
    'datetime',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datetimeUpdatedMeta = const VerificationMeta('datetimeUpdated');
  @override
  late final GeneratedColumn<DateTime> datetimeUpdated = GeneratedColumn<DateTime>(
    'datetime_updated',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    page,
    pos0,
    pos1,
    textContent,
    note,
    color,
    drawer,
    chapter,
    pageno,
    datetime,
    datetimeUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(Insertable<Annotation> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta, bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('page')) {
      context.handle(_pageMeta, page.isAcceptableOrUnknown(data['page']!, _pageMeta));
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('pos0')) {
      context.handle(_pos0Meta, pos0.isAcceptableOrUnknown(data['pos0']!, _pos0Meta));
    }
    if (data.containsKey('pos1')) {
      context.handle(_pos1Meta, pos1.isAcceptableOrUnknown(data['pos1']!, _pos1Meta));
    }
    if (data.containsKey('text')) {
      context.handle(_textContentMeta, textContent.isAcceptableOrUnknown(data['text']!, _textContentMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('drawer')) {
      context.handle(_drawerMeta, drawer.isAcceptableOrUnknown(data['drawer']!, _drawerMeta));
    }
    if (data.containsKey('chapter')) {
      context.handle(_chapterMeta, chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta));
    }
    if (data.containsKey('pageno')) {
      context.handle(_pagenoMeta, pageno.isAcceptableOrUnknown(data['pageno']!, _pagenoMeta));
    }
    if (data.containsKey('datetime')) {
      context.handle(_datetimeMeta, datetime.isAcceptableOrUnknown(data['datetime']!, _datetimeMeta));
    } else if (isInserting) {
      context.missing(_datetimeMeta);
    }
    if (data.containsKey('datetime_updated')) {
      context.handle(
        _datetimeUpdatedMeta,
        datetimeUpdated.isAcceptableOrUnknown(data['datetime_updated']!, _datetimeUpdatedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Annotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Annotation(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      page: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}page'])!,
      pos0: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pos0']),
      pos1: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pos1']),
      textContent: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}text'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      color: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      drawer: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}drawer'])!,
      chapter: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}chapter'])!,
      pageno: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}pageno'])!,
      datetime: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}datetime'])!,
      datetimeUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}datetime_updated'],
      ),
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class Annotation extends DataClass implements Insertable<Annotation> {
  final int id;
  final String bookId;

  /// XPointer: the page top for a bookmark, pos0 for a highlight.
  final String page;
  final String? pos0;
  final String? pos1;
  final String textContent;
  final String? note;

  /// KOReader color name: red, orange, yellow, green, olive, cyan, blue, purple, gray.
  final String color;

  /// KOReader drawer: lighten, underscore, strikeout, invert.
  final String drawer;
  final String chapter;

  /// Page number when the annotation was made (layout dependent, for display).
  final int pageno;
  final DateTime datetime;
  final DateTime? datetimeUpdated;
  const Annotation({
    required this.id,
    required this.bookId,
    required this.page,
    this.pos0,
    this.pos1,
    required this.textContent,
    this.note,
    required this.color,
    required this.drawer,
    required this.chapter,
    required this.pageno,
    required this.datetime,
    this.datetimeUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<String>(bookId);
    map['page'] = Variable<String>(page);
    if (!nullToAbsent || pos0 != null) {
      map['pos0'] = Variable<String>(pos0);
    }
    if (!nullToAbsent || pos1 != null) {
      map['pos1'] = Variable<String>(pos1);
    }
    map['text'] = Variable<String>(textContent);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['color'] = Variable<String>(color);
    map['drawer'] = Variable<String>(drawer);
    map['chapter'] = Variable<String>(chapter);
    map['pageno'] = Variable<int>(pageno);
    map['datetime'] = Variable<DateTime>(datetime);
    if (!nullToAbsent || datetimeUpdated != null) {
      map['datetime_updated'] = Variable<DateTime>(datetimeUpdated);
    }
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      page: Value(page),
      pos0: pos0 == null && nullToAbsent ? const Value.absent() : Value(pos0),
      pos1: pos1 == null && nullToAbsent ? const Value.absent() : Value(pos1),
      textContent: Value(textContent),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      color: Value(color),
      drawer: Value(drawer),
      chapter: Value(chapter),
      pageno: Value(pageno),
      datetime: Value(datetime),
      datetimeUpdated: datetimeUpdated == null && nullToAbsent ? const Value.absent() : Value(datetimeUpdated),
    );
  }

  factory Annotation.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Annotation(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      page: serializer.fromJson<String>(json['page']),
      pos0: serializer.fromJson<String?>(json['pos0']),
      pos1: serializer.fromJson<String?>(json['pos1']),
      textContent: serializer.fromJson<String>(json['textContent']),
      note: serializer.fromJson<String?>(json['note']),
      color: serializer.fromJson<String>(json['color']),
      drawer: serializer.fromJson<String>(json['drawer']),
      chapter: serializer.fromJson<String>(json['chapter']),
      pageno: serializer.fromJson<int>(json['pageno']),
      datetime: serializer.fromJson<DateTime>(json['datetime']),
      datetimeUpdated: serializer.fromJson<DateTime?>(json['datetimeUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<String>(bookId),
      'page': serializer.toJson<String>(page),
      'pos0': serializer.toJson<String?>(pos0),
      'pos1': serializer.toJson<String?>(pos1),
      'textContent': serializer.toJson<String>(textContent),
      'note': serializer.toJson<String?>(note),
      'color': serializer.toJson<String>(color),
      'drawer': serializer.toJson<String>(drawer),
      'chapter': serializer.toJson<String>(chapter),
      'pageno': serializer.toJson<int>(pageno),
      'datetime': serializer.toJson<DateTime>(datetime),
      'datetimeUpdated': serializer.toJson<DateTime?>(datetimeUpdated),
    };
  }

  Annotation copyWith({
    int? id,
    String? bookId,
    String? page,
    Value<String?> pos0 = const Value.absent(),
    Value<String?> pos1 = const Value.absent(),
    String? textContent,
    Value<String?> note = const Value.absent(),
    String? color,
    String? drawer,
    String? chapter,
    int? pageno,
    DateTime? datetime,
    Value<DateTime?> datetimeUpdated = const Value.absent(),
  }) => Annotation(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    page: page ?? this.page,
    pos0: pos0.present ? pos0.value : this.pos0,
    pos1: pos1.present ? pos1.value : this.pos1,
    textContent: textContent ?? this.textContent,
    note: note.present ? note.value : this.note,
    color: color ?? this.color,
    drawer: drawer ?? this.drawer,
    chapter: chapter ?? this.chapter,
    pageno: pageno ?? this.pageno,
    datetime: datetime ?? this.datetime,
    datetimeUpdated: datetimeUpdated.present ? datetimeUpdated.value : this.datetimeUpdated,
  );
  Annotation copyWithCompanion(AnnotationsCompanion data) {
    return Annotation(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      page: data.page.present ? data.page.value : this.page,
      pos0: data.pos0.present ? data.pos0.value : this.pos0,
      pos1: data.pos1.present ? data.pos1.value : this.pos1,
      textContent: data.textContent.present ? data.textContent.value : this.textContent,
      note: data.note.present ? data.note.value : this.note,
      color: data.color.present ? data.color.value : this.color,
      drawer: data.drawer.present ? data.drawer.value : this.drawer,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      pageno: data.pageno.present ? data.pageno.value : this.pageno,
      datetime: data.datetime.present ? data.datetime.value : this.datetime,
      datetimeUpdated: data.datetimeUpdated.present ? data.datetimeUpdated.value : this.datetimeUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Annotation(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('page: $page, ')
          ..write('pos0: $pos0, ')
          ..write('pos1: $pos1, ')
          ..write('textContent: $textContent, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('drawer: $drawer, ')
          ..write('chapter: $chapter, ')
          ..write('pageno: $pageno, ')
          ..write('datetime: $datetime, ')
          ..write('datetimeUpdated: $datetimeUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    page,
    pos0,
    pos1,
    textContent,
    note,
    color,
    drawer,
    chapter,
    pageno,
    datetime,
    datetimeUpdated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Annotation &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.page == this.page &&
          other.pos0 == this.pos0 &&
          other.pos1 == this.pos1 &&
          other.textContent == this.textContent &&
          other.note == this.note &&
          other.color == this.color &&
          other.drawer == this.drawer &&
          other.chapter == this.chapter &&
          other.pageno == this.pageno &&
          other.datetime == this.datetime &&
          other.datetimeUpdated == this.datetimeUpdated);
}

class AnnotationsCompanion extends UpdateCompanion<Annotation> {
  final Value<int> id;
  final Value<String> bookId;
  final Value<String> page;
  final Value<String?> pos0;
  final Value<String?> pos1;
  final Value<String> textContent;
  final Value<String?> note;
  final Value<String> color;
  final Value<String> drawer;
  final Value<String> chapter;
  final Value<int> pageno;
  final Value<DateTime> datetime;
  final Value<DateTime?> datetimeUpdated;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.page = const Value.absent(),
    this.pos0 = const Value.absent(),
    this.pos1 = const Value.absent(),
    this.textContent = const Value.absent(),
    this.note = const Value.absent(),
    this.color = const Value.absent(),
    this.drawer = const Value.absent(),
    this.chapter = const Value.absent(),
    this.pageno = const Value.absent(),
    this.datetime = const Value.absent(),
    this.datetimeUpdated = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    this.id = const Value.absent(),
    required String bookId,
    required String page,
    this.pos0 = const Value.absent(),
    this.pos1 = const Value.absent(),
    this.textContent = const Value.absent(),
    this.note = const Value.absent(),
    this.color = const Value.absent(),
    this.drawer = const Value.absent(),
    this.chapter = const Value.absent(),
    this.pageno = const Value.absent(),
    required DateTime datetime,
    this.datetimeUpdated = const Value.absent(),
  }) : bookId = Value(bookId),
       page = Value(page),
       datetime = Value(datetime);
  static Insertable<Annotation> custom({
    Expression<int>? id,
    Expression<String>? bookId,
    Expression<String>? page,
    Expression<String>? pos0,
    Expression<String>? pos1,
    Expression<String>? textContent,
    Expression<String>? note,
    Expression<String>? color,
    Expression<String>? drawer,
    Expression<String>? chapter,
    Expression<int>? pageno,
    Expression<DateTime>? datetime,
    Expression<DateTime>? datetimeUpdated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (page != null) 'page': page,
      if (pos0 != null) 'pos0': pos0,
      if (pos1 != null) 'pos1': pos1,
      if (textContent != null) 'text': textContent,
      if (note != null) 'note': note,
      if (color != null) 'color': color,
      if (drawer != null) 'drawer': drawer,
      if (chapter != null) 'chapter': chapter,
      if (pageno != null) 'pageno': pageno,
      if (datetime != null) 'datetime': datetime,
      if (datetimeUpdated != null) 'datetime_updated': datetimeUpdated,
    });
  }

  AnnotationsCompanion copyWith({
    Value<int>? id,
    Value<String>? bookId,
    Value<String>? page,
    Value<String?>? pos0,
    Value<String?>? pos1,
    Value<String>? textContent,
    Value<String?>? note,
    Value<String>? color,
    Value<String>? drawer,
    Value<String>? chapter,
    Value<int>? pageno,
    Value<DateTime>? datetime,
    Value<DateTime?>? datetimeUpdated,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      page: page ?? this.page,
      pos0: pos0 ?? this.pos0,
      pos1: pos1 ?? this.pos1,
      textContent: textContent ?? this.textContent,
      note: note ?? this.note,
      color: color ?? this.color,
      drawer: drawer ?? this.drawer,
      chapter: chapter ?? this.chapter,
      pageno: pageno ?? this.pageno,
      datetime: datetime ?? this.datetime,
      datetimeUpdated: datetimeUpdated ?? this.datetimeUpdated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (page.present) {
      map['page'] = Variable<String>(page.value);
    }
    if (pos0.present) {
      map['pos0'] = Variable<String>(pos0.value);
    }
    if (pos1.present) {
      map['pos1'] = Variable<String>(pos1.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (drawer.present) {
      map['drawer'] = Variable<String>(drawer.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<String>(chapter.value);
    }
    if (pageno.present) {
      map['pageno'] = Variable<int>(pageno.value);
    }
    if (datetime.present) {
      map['datetime'] = Variable<DateTime>(datetime.value);
    }
    if (datetimeUpdated.present) {
      map['datetime_updated'] = Variable<DateTime>(datetimeUpdated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('page: $page, ')
          ..write('pos0: $pos0, ')
          ..write('pos1: $pos1, ')
          ..write('textContent: $textContent, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('drawer: $drawer, ')
          ..write('chapter: $chapter, ')
          ..write('pageno: $pageno, ')
          ..write('datetime: $datetime, ')
          ..write('datetimeUpdated: $datetimeUpdated')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $PrefsTable prefs = $PrefsTable(this);
  late final $ShelvesTable shelves = $ShelvesTable(this);
  late final $ShelfBooksTable shelfBooks = $ShelfBooksTable(this);
  late final $OpdsCatalogsTable opdsCatalogs = $OpdsCatalogsTable(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [books, prefs, shelves, shelfBooks, opdsCatalogs, annotations];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('shelves', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('shelf_books', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('books', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('shelf_books', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('books', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('annotations', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  required String id,
  required String path,
  Value<String> title,
  Value<String> authors,
  Value<String> format,
  Value<String> language,
  Value<String?> lastXPointer,
  Value<double> progress,
  required DateTime addedAt,
  Value<DateTime?> lastOpenedAt,
  Value<String> series,
  Value<int> seriesNumber,
  Value<String> description,
  Value<String?> coverPath,
  Value<int?> fileSize,
  Value<DateTime?> fileModified,
  Value<bool> favorite,
  Value<DateTime?> deletedAt,
  Value<bool> missing,
  Value<String?> settings,
  Value<int> rowid,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<String> id,
  Value<String> path,
  Value<String> title,
  Value<String> authors,
  Value<String> format,
  Value<String> language,
  Value<String?> lastXPointer,
  Value<double> progress,
  Value<DateTime> addedAt,
  Value<DateTime?> lastOpenedAt,
  Value<String> series,
  Value<int> seriesNumber,
  Value<String> description,
  Value<String?> coverPath,
  Value<int?> fileSize,
  Value<DateTime?> fileModified,
  Value<bool> favorite,
  Value<DateTime?> deletedAt,
  Value<bool> missing,
  Value<String?> settings,
  Value<int> rowid,
});

final class $$BooksTableReferences extends BaseReferences<_$AppDatabase, $BooksTable, Book> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShelfBooksTable, List<ShelfBook>> _shelfBooksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.shelfBooks, aliasName: 'books__id__shelf_books__book_id');

  $$ShelfBooksTableProcessedTableManager get shelfBooksRefs {
    final manager = $$ShelfBooksTableTableManager(
      $_db,
      $_db.shelfBooks,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shelfBooksRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AnnotationsTable, List<Annotation>> _annotationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.annotations, aliasName: 'books__id__annotations__book_id');

  $$AnnotationsTableProcessedTableManager get annotationsRefs {
    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.annotations,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get authors =>
      $composableBuilder(column: $table.authors, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastXPointer =>
      $composableBuilder(column: $table.lastXPointer, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastOpenedAt =>
      $composableBuilder(column: $table.lastOpenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get series =>
      $composableBuilder(column: $table.series, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seriesNumber =>
      $composableBuilder(column: $table.seriesNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fileModified =>
      $composableBuilder(column: $table.fileModified, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get missing =>
      $composableBuilder(column: $table.missing, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get settings =>
      $composableBuilder(column: $table.settings, builder: (column) => ColumnFilters(column));

  Expression<bool> shelfBooksRefs(Expression<bool> Function($$ShelfBooksTableFilterComposer f) f) {
    final $$ShelfBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shelfBooks,
      getReferencedColumn: (t) => t.bookId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShelfBooksTableFilterComposer(
            $db: $db,
            $table: $db.shelfBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> annotationsRefs(Expression<bool> Function($$AnnotationsTableFilterComposer f) f) {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.bookId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableOrderingComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get authors =>
      $composableBuilder(column: $table.authors, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastXPointer =>
      $composableBuilder(column: $table.lastXPointer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastOpenedAt =>
      $composableBuilder(column: $table.lastOpenedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get series =>
      $composableBuilder(column: $table.series, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seriesNumber =>
      $composableBuilder(column: $table.seriesNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fileModified =>
      $composableBuilder(column: $table.fileModified, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get missing =>
      $composableBuilder(column: $table.missing, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get settings =>
      $composableBuilder(column: $table.settings, builder: (column) => ColumnOrderings(column));
}

class $$BooksTableAnnotationComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path => $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get authors => $composableBuilder(column: $table.authors, builder: (column) => column);

  GeneratedColumn<String> get format => $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get language => $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get lastXPointer =>
      $composableBuilder(column: $table.lastXPointer, builder: (column) => column);

  GeneratedColumn<double> get progress => $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt => $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt =>
      $composableBuilder(column: $table.lastOpenedAt, builder: (column) => column);

  GeneratedColumn<String> get series => $composableBuilder(column: $table.series, builder: (column) => column);

  GeneratedColumn<int> get seriesNumber => $composableBuilder(column: $table.seriesNumber, builder: (column) => column);

  GeneratedColumn<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get coverPath => $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<int> get fileSize => $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get fileModified =>
      $composableBuilder(column: $table.fileModified, builder: (column) => column);

  GeneratedColumn<bool> get favorite => $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get missing => $composableBuilder(column: $table.missing, builder: (column) => column);

  GeneratedColumn<String> get settings => $composableBuilder(column: $table.settings, builder: (column) => column);

  Expression<T> shelfBooksRefs<T extends Object>(Expression<T> Function($$ShelfBooksTableAnnotationComposer a) f) {
    final $$ShelfBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shelfBooks,
      getReferencedColumn: (t) => t.bookId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShelfBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.shelfBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> annotationsRefs<T extends Object>(Expression<T> Function($$AnnotationsTableAnnotationComposer a) f) {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.bookId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, $$BooksTableReferences),
          Book,
          PrefetchHooks Function({bool shelfBooksRefs, bool annotationsRefs})
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> authors = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> lastXPointer = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<String> series = const Value.absent(),
                Value<int> seriesNumber = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<DateTime?> fileModified = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> missing = const Value.absent(),
                Value<String?> settings = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                path: path,
                title: title,
                authors: authors,
                format: format,
                language: language,
                lastXPointer: lastXPointer,
                progress: progress,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                series: series,
                seriesNumber: seriesNumber,
                description: description,
                coverPath: coverPath,
                fileSize: fileSize,
                fileModified: fileModified,
                favorite: favorite,
                deletedAt: deletedAt,
                missing: missing,
                settings: settings,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String path,
                Value<String> title = const Value.absent(),
                Value<String> authors = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> lastXPointer = const Value.absent(),
                Value<double> progress = const Value.absent(),
                required DateTime addedAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<String> series = const Value.absent(),
                Value<int> seriesNumber = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<DateTime?> fileModified = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> missing = const Value.absent(),
                Value<String?> settings = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                path: path,
                title: title,
                authors: authors,
                format: format,
                language: language,
                lastXPointer: lastXPointer,
                progress: progress,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                series: series,
                seriesNumber: seriesNumber,
                description: description,
                coverPath: coverPath,
                fileSize: fileSize,
                fileModified: fileModified,
                favorite: favorite,
                deletedAt: deletedAt,
                missing: missing,
                settings: settings,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$BooksTable, Book>(table), $$BooksTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({shelfBooksRefs = false, annotationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (shelfBooksRefs) db.shelfBooks, if (annotationsRefs) db.annotations],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shelfBooksRefs)
                    await $_getPrefetchedDataByColumns<Book, $BooksTable, ShelfBook, $ShelfBooksTable>(
                      currentTable: table,
                      referencedTable: $$BooksTableReferences._shelfBooksRefsTable(db),
                      managerFromTypedResult: (p0) => $$BooksTableReferences(db, table, p0).shelfBooksRefs,
                      currentColumn: 'id',
                      referencedColumn: 'book_id',
                      typedResults: items,
                    ),
                  if (annotationsRefs)
                    await $_getPrefetchedDataByColumns<Book, $BooksTable, Annotation, $AnnotationsTable>(
                      currentTable: table,
                      referencedTable: $$BooksTableReferences._annotationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$BooksTableReferences(db, table, p0).annotationsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'book_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, $$BooksTableReferences),
      Book,
      PrefetchHooks Function({bool shelfBooksRefs, bool annotationsRefs})
    >;
typedef $$PrefsTableCreateCompanionBuilder = PrefsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$PrefsTableUpdateCompanionBuilder = PrefsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$PrefsTableFilterComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$PrefsTableOrderingComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$PrefsTableAnnotationComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrefsTable,
          Pref,
          $$PrefsTableFilterComposer,
          $$PrefsTableOrderingComposer,
          $$PrefsTableAnnotationComposer,
          $$PrefsTableCreateCompanionBuilder,
          $$PrefsTableUpdateCompanionBuilder,
          (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
          Pref,
          PrefetchHooks Function()
        > {
  $$PrefsTableTableManager(_$AppDatabase db, $PrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrefsTable, Pref>(table),
                  BaseReferences<_$AppDatabase, $PrefsTable, Pref>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrefsTable,
      Pref,
      $$PrefsTableFilterComposer,
      $$PrefsTableOrderingComposer,
      $$PrefsTableAnnotationComposer,
      $$PrefsTableCreateCompanionBuilder,
      $$PrefsTableUpdateCompanionBuilder,
      (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
      Pref,
      PrefetchHooks Function()
    >;
typedef $$ShelvesTableCreateCompanionBuilder = ShelvesCompanion Function({
  Value<int> id,
  required String name,
  required DateTime createdAt,
});
typedef $$ShelvesTableUpdateCompanionBuilder = ShelvesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> createdAt,
});

final class $$ShelvesTableReferences extends BaseReferences<_$AppDatabase, $ShelvesTable, Shelf> {
  $$ShelvesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShelfBooksTable, List<ShelfBook>> _shelfBooksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.shelfBooks, aliasName: 'shelves__id__shelf_books__shelf_id');

  $$ShelfBooksTableProcessedTableManager get shelfBooksRefs {
    final manager = $$ShelfBooksTableTableManager(
      $_db,
      $_db.shelfBooks,
    ).filter((f) => f.shelfId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shelfBooksRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ShelvesTableFilterComposer extends Composer<_$AppDatabase, $ShelvesTable> {
  $$ShelvesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> shelfBooksRefs(Expression<bool> Function($$ShelfBooksTableFilterComposer f) f) {
    final $$ShelfBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shelfBooks,
      getReferencedColumn: (t) => t.shelfId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShelfBooksTableFilterComposer(
            $db: $db,
            $table: $db.shelfBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShelvesTableOrderingComposer extends Composer<_$AppDatabase, $ShelvesTable> {
  $$ShelvesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ShelvesTableAnnotationComposer extends Composer<_$AppDatabase, $ShelvesTable> {
  $$ShelvesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> shelfBooksRefs<T extends Object>(Expression<T> Function($$ShelfBooksTableAnnotationComposer a) f) {
    final $$ShelfBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shelfBooks,
      getReferencedColumn: (t) => t.shelfId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShelfBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.shelfBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShelvesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShelvesTable,
          Shelf,
          $$ShelvesTableFilterComposer,
          $$ShelvesTableOrderingComposer,
          $$ShelvesTableAnnotationComposer,
          $$ShelvesTableCreateCompanionBuilder,
          $$ShelvesTableUpdateCompanionBuilder,
          (Shelf, $$ShelvesTableReferences),
          Shelf,
          PrefetchHooks Function({bool shelfBooksRefs})
        > {
  $$ShelvesTableTableManager(_$AppDatabase db, $ShelvesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ShelvesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ShelvesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ShelvesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) => ShelvesCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required DateTime createdAt,
          }) => ShelvesCompanion.insert(id: id, name: name, createdAt: createdAt),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$ShelvesTable, Shelf>(table), $$ShelvesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({shelfBooksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (shelfBooksRefs) db.shelfBooks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shelfBooksRefs)
                    await $_getPrefetchedDataByColumns<Shelf, $ShelvesTable, ShelfBook, $ShelfBooksTable>(
                      currentTable: table,
                      referencedTable: $$ShelvesTableReferences._shelfBooksRefsTable(db),
                      managerFromTypedResult: (p0) => $$ShelvesTableReferences(db, table, p0).shelfBooksRefs,
                      currentColumn: 'id',
                      referencedColumn: 'shelf_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ShelvesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShelvesTable,
      Shelf,
      $$ShelvesTableFilterComposer,
      $$ShelvesTableOrderingComposer,
      $$ShelvesTableAnnotationComposer,
      $$ShelvesTableCreateCompanionBuilder,
      $$ShelvesTableUpdateCompanionBuilder,
      (Shelf, $$ShelvesTableReferences),
      Shelf,
      PrefetchHooks Function({bool shelfBooksRefs})
    >;
typedef $$ShelfBooksTableCreateCompanionBuilder = ShelfBooksCompanion Function({
  required int shelfId,
  required String bookId,
  Value<int> rowid,
});
typedef $$ShelfBooksTableUpdateCompanionBuilder = ShelfBooksCompanion Function({
  Value<int> shelfId,
  Value<String> bookId,
  Value<int> rowid,
});

final class $$ShelfBooksTableReferences extends BaseReferences<_$AppDatabase, $ShelfBooksTable, ShelfBook> {
  $$ShelfBooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShelvesTable _shelfIdTable(_$AppDatabase db) => db.shelves.createAlias('shelf_books__shelf_id__shelves__id');

  $$ShelvesTableProcessedTableManager get shelfId {
    final $_column = $_itemColumn<int>('shelf_id')!;

    final manager = $$ShelvesTableTableManager($_db, $_db.shelves).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shelfIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BooksTable _bookIdTable(_$AppDatabase db) => db.books.createAlias('shelf_books__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager($_db, $_db.books).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ShelfBooksTableFilterComposer extends Composer<_$AppDatabase, $ShelfBooksTable> {
  $$ShelfBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ShelvesTableFilterComposer get shelfId {
    final $$ShelvesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shelfId,
      referencedTable: $db.shelves,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShelvesTableFilterComposer(
            $db: $db,
            $table: $db.shelves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShelfBooksTableOrderingComposer extends Composer<_$AppDatabase, $ShelfBooksTable> {
  $$ShelfBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ShelvesTableOrderingComposer get shelfId {
    final $$ShelvesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shelfId,
      referencedTable: $db.shelves,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShelvesTableOrderingComposer(
            $db: $db,
            $table: $db.shelves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShelfBooksTableAnnotationComposer extends Composer<_$AppDatabase, $ShelfBooksTable> {
  $$ShelfBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ShelvesTableAnnotationComposer get shelfId {
    final $$ShelvesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shelfId,
      referencedTable: $db.shelves,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShelvesTableAnnotationComposer(
            $db: $db,
            $table: $db.shelves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShelfBooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShelfBooksTable,
          ShelfBook,
          $$ShelfBooksTableFilterComposer,
          $$ShelfBooksTableOrderingComposer,
          $$ShelfBooksTableAnnotationComposer,
          $$ShelfBooksTableCreateCompanionBuilder,
          $$ShelfBooksTableUpdateCompanionBuilder,
          (ShelfBook, $$ShelfBooksTableReferences),
          ShelfBook,
          PrefetchHooks Function({bool shelfId, bool bookId})
        > {
  $$ShelfBooksTableTableManager(_$AppDatabase db, $ShelfBooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ShelfBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ShelfBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ShelfBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> shelfId = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ShelfBooksCompanion(shelfId: shelfId, bookId: bookId, rowid: rowid),
          createCompanionCallback: ({
            required int shelfId,
            required String bookId,
            Value<int> rowid = const Value.absent(),
          }) => ShelfBooksCompanion.insert(shelfId: shelfId, bookId: bookId, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$ShelfBooksTable, ShelfBook>(table), $$ShelfBooksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({shelfId = false, bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (shelfId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.shelfId,
                        referencedTable: $$ShelfBooksTableReferences._shelfIdTable(db),
                        referencedColumn: $$ShelfBooksTableReferences._shelfIdTable(db).id,
                      ) as T;
                    }
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$ShelfBooksTableReferences._bookIdTable(db),
                        referencedColumn: $$ShelfBooksTableReferences._bookIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ShelfBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShelfBooksTable,
      ShelfBook,
      $$ShelfBooksTableFilterComposer,
      $$ShelfBooksTableOrderingComposer,
      $$ShelfBooksTableAnnotationComposer,
      $$ShelfBooksTableCreateCompanionBuilder,
      $$ShelfBooksTableUpdateCompanionBuilder,
      (ShelfBook, $$ShelfBooksTableReferences),
      ShelfBook,
      PrefetchHooks Function({bool shelfId, bool bookId})
    >;
typedef $$OpdsCatalogsTableCreateCompanionBuilder = OpdsCatalogsCompanion Function({
  Value<int> id,
  required String title,
  required String url,
  Value<String?> username,
  Value<String?> password,
  required DateTime createdAt,
});
typedef $$OpdsCatalogsTableUpdateCompanionBuilder = OpdsCatalogsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> url,
  Value<String?> username,
  Value<String?> password,
  Value<DateTime> createdAt,
});

class $$OpdsCatalogsTableFilterComposer extends Composer<_$AppDatabase, $OpdsCatalogsTable> {
  $$OpdsCatalogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$OpdsCatalogsTableOrderingComposer extends Composer<_$AppDatabase, $OpdsCatalogsTable> {
  $$OpdsCatalogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$OpdsCatalogsTableAnnotationComposer extends Composer<_$AppDatabase, $OpdsCatalogsTable> {
  $$OpdsCatalogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get url => $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get username => $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password => $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OpdsCatalogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OpdsCatalogsTable,
          OpdsCatalog,
          $$OpdsCatalogsTableFilterComposer,
          $$OpdsCatalogsTableOrderingComposer,
          $$OpdsCatalogsTableAnnotationComposer,
          $$OpdsCatalogsTableCreateCompanionBuilder,
          $$OpdsCatalogsTableUpdateCompanionBuilder,
          (OpdsCatalog, BaseReferences<_$AppDatabase, $OpdsCatalogsTable, OpdsCatalog>),
          OpdsCatalog,
          PrefetchHooks Function()
        > {
  $$OpdsCatalogsTableTableManager(_$AppDatabase db, $OpdsCatalogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OpdsCatalogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OpdsCatalogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OpdsCatalogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OpdsCatalogsCompanion(
                id: id,
                title: title,
                url: url,
                username: username,
                password: password,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String url,
                Value<String?> username = const Value.absent(),
                Value<String?> password = const Value.absent(),
                required DateTime createdAt,
              }) => OpdsCatalogsCompanion.insert(
                id: id,
                title: title,
                url: url,
                username: username,
                password: password,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OpdsCatalogsTable, OpdsCatalog>(table),
                  BaseReferences<_$AppDatabase, $OpdsCatalogsTable, OpdsCatalog>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OpdsCatalogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OpdsCatalogsTable,
      OpdsCatalog,
      $$OpdsCatalogsTableFilterComposer,
      $$OpdsCatalogsTableOrderingComposer,
      $$OpdsCatalogsTableAnnotationComposer,
      $$OpdsCatalogsTableCreateCompanionBuilder,
      $$OpdsCatalogsTableUpdateCompanionBuilder,
      (OpdsCatalog, BaseReferences<_$AppDatabase, $OpdsCatalogsTable, OpdsCatalog>),
      OpdsCatalog,
      PrefetchHooks Function()
    >;
typedef $$AnnotationsTableCreateCompanionBuilder = AnnotationsCompanion Function({
  Value<int> id,
  required String bookId,
  required String page,
  Value<String?> pos0,
  Value<String?> pos1,
  Value<String> textContent,
  Value<String?> note,
  Value<String> color,
  Value<String> drawer,
  Value<String> chapter,
  Value<int> pageno,
  required DateTime datetime,
  Value<DateTime?> datetimeUpdated,
});
typedef $$AnnotationsTableUpdateCompanionBuilder = AnnotationsCompanion Function({
  Value<int> id,
  Value<String> bookId,
  Value<String> page,
  Value<String?> pos0,
  Value<String?> pos1,
  Value<String> textContent,
  Value<String?> note,
  Value<String> color,
  Value<String> drawer,
  Value<String> chapter,
  Value<int> pageno,
  Value<DateTime> datetime,
  Value<DateTime?> datetimeUpdated,
});

final class $$AnnotationsTableReferences extends BaseReferences<_$AppDatabase, $AnnotationsTable, Annotation> {
  $$AnnotationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) => db.books.createAlias('annotations__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager($_db, $_db.books).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AnnotationsTableFilterComposer extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get page => $composableBuilder(column: $table.page, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pos0 => $composableBuilder(column: $table.pos0, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pos1 => $composableBuilder(column: $table.pos1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textContent =>
      $composableBuilder(column: $table.textContent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get drawer =>
      $composableBuilder(column: $table.drawer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageno =>
      $composableBuilder(column: $table.pageno, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get datetime =>
      $composableBuilder(column: $table.datetime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get datetimeUpdated =>
      $composableBuilder(column: $table.datetimeUpdated, builder: (column) => ColumnFilters(column));

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableOrderingComposer extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get page =>
      $composableBuilder(column: $table.page, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pos0 =>
      $composableBuilder(column: $table.pos0, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pos1 =>
      $composableBuilder(column: $table.pos1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textContent =>
      $composableBuilder(column: $table.textContent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get drawer =>
      $composableBuilder(column: $table.drawer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageno =>
      $composableBuilder(column: $table.pageno, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get datetime =>
      $composableBuilder(column: $table.datetime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get datetimeUpdated =>
      $composableBuilder(column: $table.datetimeUpdated, builder: (column) => ColumnOrderings(column));

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableAnnotationComposer extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get page => $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get pos0 => $composableBuilder(column: $table.pos0, builder: (column) => column);

  GeneratedColumn<String> get pos1 => $composableBuilder(column: $table.pos1, builder: (column) => column);

  GeneratedColumn<String> get textContent =>
      $composableBuilder(column: $table.textContent, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get drawer => $composableBuilder(column: $table.drawer, builder: (column) => column);

  GeneratedColumn<String> get chapter => $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get pageno => $composableBuilder(column: $table.pageno, builder: (column) => column);

  GeneratedColumn<DateTime> get datetime => $composableBuilder(column: $table.datetime, builder: (column) => column);

  GeneratedColumn<DateTime> get datetimeUpdated =>
      $composableBuilder(column: $table.datetimeUpdated, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationsTable,
          Annotation,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (Annotation, $$AnnotationsTableReferences),
          Annotation,
          PrefetchHooks Function({bool bookId})
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> page = const Value.absent(),
                Value<String?> pos0 = const Value.absent(),
                Value<String?> pos1 = const Value.absent(),
                Value<String> textContent = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> drawer = const Value.absent(),
                Value<String> chapter = const Value.absent(),
                Value<int> pageno = const Value.absent(),
                Value<DateTime> datetime = const Value.absent(),
                Value<DateTime?> datetimeUpdated = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                bookId: bookId,
                page: page,
                pos0: pos0,
                pos1: pos1,
                textContent: textContent,
                note: note,
                color: color,
                drawer: drawer,
                chapter: chapter,
                pageno: pageno,
                datetime: datetime,
                datetimeUpdated: datetimeUpdated,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String bookId,
                required String page,
                Value<String?> pos0 = const Value.absent(),
                Value<String?> pos1 = const Value.absent(),
                Value<String> textContent = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> drawer = const Value.absent(),
                Value<String> chapter = const Value.absent(),
                Value<int> pageno = const Value.absent(),
                required DateTime datetime,
                Value<DateTime?> datetimeUpdated = const Value.absent(),
              }) => AnnotationsCompanion.insert(
                id: id,
                bookId: bookId,
                page: page,
                pos0: pos0,
                pos1: pos1,
                textContent: textContent,
                note: note,
                color: color,
                drawer: drawer,
                chapter: chapter,
                pageno: pageno,
                datetime: datetime,
                datetimeUpdated: datetimeUpdated,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$AnnotationsTable, Annotation>(table), $$AnnotationsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$AnnotationsTableReferences._bookIdTable(db),
                        referencedColumn: $$AnnotationsTableReferences._bookIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationsTable,
      Annotation,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (Annotation, $$AnnotationsTableReferences),
      Annotation,
      PrefetchHooks Function({bool bookId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books => $$BooksTableTableManager(_db, _db.books);
  $$PrefsTableTableManager get prefs => $$PrefsTableTableManager(_db, _db.prefs);
  $$ShelvesTableTableManager get shelves => $$ShelvesTableTableManager(_db, _db.shelves);
  $$ShelfBooksTableTableManager get shelfBooks => $$ShelfBooksTableTableManager(_db, _db.shelfBooks);
  $$OpdsCatalogsTableTableManager get opdsCatalogs => $$OpdsCatalogsTableTableManager(_db, _db.opdsCatalogs);
  $$AnnotationsTableTableManager get annotations => $$AnnotationsTableTableManager(_db, _db.annotations);
}
