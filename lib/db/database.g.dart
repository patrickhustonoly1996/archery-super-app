// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RoundTypesTable extends RoundTypes
    with TableInfo<$RoundTypesTable, RoundType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoundTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<int> distance = GeneratedColumn<int>(
    'distance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faceSizeMeta = const VerificationMeta(
    'faceSize',
  );
  @override
  late final GeneratedColumn<int> faceSize = GeneratedColumn<int>(
    'face_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arrowsPerEndMeta = const VerificationMeta(
    'arrowsPerEnd',
  );
  @override
  late final GeneratedColumn<int> arrowsPerEnd = GeneratedColumn<int>(
    'arrows_per_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalEndsMeta = const VerificationMeta(
    'totalEnds',
  );
  @override
  late final GeneratedColumn<int> totalEnds = GeneratedColumn<int>(
    'total_ends',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxScoreMeta = const VerificationMeta(
    'maxScore',
  );
  @override
  late final GeneratedColumn<int> maxScore = GeneratedColumn<int>(
    'max_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isIndoorMeta = const VerificationMeta(
    'isIndoor',
  );
  @override
  late final GeneratedColumn<bool> isIndoor = GeneratedColumn<bool>(
    'is_indoor',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_indoor" IN (0, 1))',
    ),
  );
  static const VerificationMeta _faceCountMeta = const VerificationMeta(
    'faceCount',
  );
  @override
  late final GeneratedColumn<int> faceCount = GeneratedColumn<int>(
    'face_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    distance,
    faceSize,
    arrowsPerEnd,
    totalEnds,
    maxScore,
    isIndoor,
    faceCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'round_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoundType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMeta);
    }
    if (data.containsKey('face_size')) {
      context.handle(
        _faceSizeMeta,
        faceSize.isAcceptableOrUnknown(data['face_size']!, _faceSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_faceSizeMeta);
    }
    if (data.containsKey('arrows_per_end')) {
      context.handle(
        _arrowsPerEndMeta,
        arrowsPerEnd.isAcceptableOrUnknown(
          data['arrows_per_end']!,
          _arrowsPerEndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_arrowsPerEndMeta);
    }
    if (data.containsKey('total_ends')) {
      context.handle(
        _totalEndsMeta,
        totalEnds.isAcceptableOrUnknown(data['total_ends']!, _totalEndsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalEndsMeta);
    }
    if (data.containsKey('max_score')) {
      context.handle(
        _maxScoreMeta,
        maxScore.isAcceptableOrUnknown(data['max_score']!, _maxScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_maxScoreMeta);
    }
    if (data.containsKey('is_indoor')) {
      context.handle(
        _isIndoorMeta,
        isIndoor.isAcceptableOrUnknown(data['is_indoor']!, _isIndoorMeta),
      );
    } else if (isInserting) {
      context.missing(_isIndoorMeta);
    }
    if (data.containsKey('face_count')) {
      context.handle(
        _faceCountMeta,
        faceCount.isAcceptableOrUnknown(data['face_count']!, _faceCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoundType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoundType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance'],
      )!,
      faceSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}face_size'],
      )!,
      arrowsPerEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}arrows_per_end'],
      )!,
      totalEnds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_ends'],
      )!,
      maxScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_score'],
      )!,
      isIndoor: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_indoor'],
      )!,
      faceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}face_count'],
      )!,
    );
  }

  @override
  $RoundTypesTable createAlias(String alias) {
    return $RoundTypesTable(attachedDatabase, alias);
  }
}

class RoundType extends DataClass implements Insertable<RoundType> {
  final String id;
  final String name;
  final String category;
  final int distance;
  final int faceSize;
  final int arrowsPerEnd;
  final int totalEnds;
  final int maxScore;
  final bool isIndoor;
  final int faceCount;
  const RoundType({
    required this.id,
    required this.name,
    required this.category,
    required this.distance,
    required this.faceSize,
    required this.arrowsPerEnd,
    required this.totalEnds,
    required this.maxScore,
    required this.isIndoor,
    required this.faceCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['distance'] = Variable<int>(distance);
    map['face_size'] = Variable<int>(faceSize);
    map['arrows_per_end'] = Variable<int>(arrowsPerEnd);
    map['total_ends'] = Variable<int>(totalEnds);
    map['max_score'] = Variable<int>(maxScore);
    map['is_indoor'] = Variable<bool>(isIndoor);
    map['face_count'] = Variable<int>(faceCount);
    return map;
  }

  RoundTypesCompanion toCompanion(bool nullToAbsent) {
    return RoundTypesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      distance: Value(distance),
      faceSize: Value(faceSize),
      arrowsPerEnd: Value(arrowsPerEnd),
      totalEnds: Value(totalEnds),
      maxScore: Value(maxScore),
      isIndoor: Value(isIndoor),
      faceCount: Value(faceCount),
    );
  }

  factory RoundType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoundType(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      distance: serializer.fromJson<int>(json['distance']),
      faceSize: serializer.fromJson<int>(json['faceSize']),
      arrowsPerEnd: serializer.fromJson<int>(json['arrowsPerEnd']),
      totalEnds: serializer.fromJson<int>(json['totalEnds']),
      maxScore: serializer.fromJson<int>(json['maxScore']),
      isIndoor: serializer.fromJson<bool>(json['isIndoor']),
      faceCount: serializer.fromJson<int>(json['faceCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'distance': serializer.toJson<int>(distance),
      'faceSize': serializer.toJson<int>(faceSize),
      'arrowsPerEnd': serializer.toJson<int>(arrowsPerEnd),
      'totalEnds': serializer.toJson<int>(totalEnds),
      'maxScore': serializer.toJson<int>(maxScore),
      'isIndoor': serializer.toJson<bool>(isIndoor),
      'faceCount': serializer.toJson<int>(faceCount),
    };
  }

  RoundType copyWith({
    String? id,
    String? name,
    String? category,
    int? distance,
    int? faceSize,
    int? arrowsPerEnd,
    int? totalEnds,
    int? maxScore,
    bool? isIndoor,
    int? faceCount,
  }) => RoundType(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    distance: distance ?? this.distance,
    faceSize: faceSize ?? this.faceSize,
    arrowsPerEnd: arrowsPerEnd ?? this.arrowsPerEnd,
    totalEnds: totalEnds ?? this.totalEnds,
    maxScore: maxScore ?? this.maxScore,
    isIndoor: isIndoor ?? this.isIndoor,
    faceCount: faceCount ?? this.faceCount,
  );
  RoundType copyWithCompanion(RoundTypesCompanion data) {
    return RoundType(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      distance: data.distance.present ? data.distance.value : this.distance,
      faceSize: data.faceSize.present ? data.faceSize.value : this.faceSize,
      arrowsPerEnd: data.arrowsPerEnd.present
          ? data.arrowsPerEnd.value
          : this.arrowsPerEnd,
      totalEnds: data.totalEnds.present ? data.totalEnds.value : this.totalEnds,
      maxScore: data.maxScore.present ? data.maxScore.value : this.maxScore,
      isIndoor: data.isIndoor.present ? data.isIndoor.value : this.isIndoor,
      faceCount: data.faceCount.present ? data.faceCount.value : this.faceCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoundType(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('distance: $distance, ')
          ..write('faceSize: $faceSize, ')
          ..write('arrowsPerEnd: $arrowsPerEnd, ')
          ..write('totalEnds: $totalEnds, ')
          ..write('maxScore: $maxScore, ')
          ..write('isIndoor: $isIndoor, ')
          ..write('faceCount: $faceCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    distance,
    faceSize,
    arrowsPerEnd,
    totalEnds,
    maxScore,
    isIndoor,
    faceCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoundType &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.distance == this.distance &&
          other.faceSize == this.faceSize &&
          other.arrowsPerEnd == this.arrowsPerEnd &&
          other.totalEnds == this.totalEnds &&
          other.maxScore == this.maxScore &&
          other.isIndoor == this.isIndoor &&
          other.faceCount == this.faceCount);
}

class RoundTypesCompanion extends UpdateCompanion<RoundType> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<int> distance;
  final Value<int> faceSize;
  final Value<int> arrowsPerEnd;
  final Value<int> totalEnds;
  final Value<int> maxScore;
  final Value<bool> isIndoor;
  final Value<int> faceCount;
  final Value<int> rowid;
  const RoundTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.distance = const Value.absent(),
    this.faceSize = const Value.absent(),
    this.arrowsPerEnd = const Value.absent(),
    this.totalEnds = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.isIndoor = const Value.absent(),
    this.faceCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoundTypesCompanion.insert({
    required String id,
    required String name,
    required String category,
    required int distance,
    required int faceSize,
    required int arrowsPerEnd,
    required int totalEnds,
    required int maxScore,
    required bool isIndoor,
    this.faceCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       distance = Value(distance),
       faceSize = Value(faceSize),
       arrowsPerEnd = Value(arrowsPerEnd),
       totalEnds = Value(totalEnds),
       maxScore = Value(maxScore),
       isIndoor = Value(isIndoor);
  static Insertable<RoundType> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? distance,
    Expression<int>? faceSize,
    Expression<int>? arrowsPerEnd,
    Expression<int>? totalEnds,
    Expression<int>? maxScore,
    Expression<bool>? isIndoor,
    Expression<int>? faceCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (distance != null) 'distance': distance,
      if (faceSize != null) 'face_size': faceSize,
      if (arrowsPerEnd != null) 'arrows_per_end': arrowsPerEnd,
      if (totalEnds != null) 'total_ends': totalEnds,
      if (maxScore != null) 'max_score': maxScore,
      if (isIndoor != null) 'is_indoor': isIndoor,
      if (faceCount != null) 'face_count': faceCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoundTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<int>? distance,
    Value<int>? faceSize,
    Value<int>? arrowsPerEnd,
    Value<int>? totalEnds,
    Value<int>? maxScore,
    Value<bool>? isIndoor,
    Value<int>? faceCount,
    Value<int>? rowid,
  }) {
    return RoundTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      distance: distance ?? this.distance,
      faceSize: faceSize ?? this.faceSize,
      arrowsPerEnd: arrowsPerEnd ?? this.arrowsPerEnd,
      totalEnds: totalEnds ?? this.totalEnds,
      maxScore: maxScore ?? this.maxScore,
      isIndoor: isIndoor ?? this.isIndoor,
      faceCount: faceCount ?? this.faceCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (distance.present) {
      map['distance'] = Variable<int>(distance.value);
    }
    if (faceSize.present) {
      map['face_size'] = Variable<int>(faceSize.value);
    }
    if (arrowsPerEnd.present) {
      map['arrows_per_end'] = Variable<int>(arrowsPerEnd.value);
    }
    if (totalEnds.present) {
      map['total_ends'] = Variable<int>(totalEnds.value);
    }
    if (maxScore.present) {
      map['max_score'] = Variable<int>(maxScore.value);
    }
    if (isIndoor.present) {
      map['is_indoor'] = Variable<bool>(isIndoor.value);
    }
    if (faceCount.present) {
      map['face_count'] = Variable<int>(faceCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoundTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('distance: $distance, ')
          ..write('faceSize: $faceSize, ')
          ..write('arrowsPerEnd: $arrowsPerEnd, ')
          ..write('totalEnds: $totalEnds, ')
          ..write('maxScore: $maxScore, ')
          ..write('isIndoor: $isIndoor, ')
          ..write('faceCount: $faceCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BowsTable extends Bows with TableInfo<$BowsTable, Bow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _bowTypeMeta = const VerificationMeta(
    'bowType',
  );
  @override
  late final GeneratedColumn<String> bowType = GeneratedColumn<String>(
    'bow_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingsMeta = const VerificationMeta(
    'settings',
  );
  @override
  late final GeneratedColumn<String> settings = GeneratedColumn<String>(
    'settings',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    bowType,
    settings,
    isDefault,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bows';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('bow_type')) {
      context.handle(
        _bowTypeMeta,
        bowType.isAcceptableOrUnknown(data['bow_type']!, _bowTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_bowTypeMeta);
    }
    if (data.containsKey('settings')) {
      context.handle(
        _settingsMeta,
        settings.isAcceptableOrUnknown(data['settings']!, _settingsMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bowType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bow_type'],
      )!,
      settings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BowsTable createAlias(String alias) {
    return $BowsTable(attachedDatabase, alias);
  }
}

class Bow extends DataClass implements Insertable<Bow> {
  final String id;
  final String name;
  final String bowType;
  final String? settings;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Bow({
    required this.id,
    required this.name,
    required this.bowType,
    this.settings,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['bow_type'] = Variable<String>(bowType);
    if (!nullToAbsent || settings != null) {
      map['settings'] = Variable<String>(settings);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BowsCompanion toCompanion(bool nullToAbsent) {
    return BowsCompanion(
      id: Value(id),
      name: Value(name),
      bowType: Value(bowType),
      settings: settings == null && nullToAbsent
          ? const Value.absent()
          : Value(settings),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Bow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      bowType: serializer.fromJson<String>(json['bowType']),
      settings: serializer.fromJson<String?>(json['settings']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'bowType': serializer.toJson<String>(bowType),
      'settings': serializer.toJson<String?>(settings),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Bow copyWith({
    String? id,
    String? name,
    String? bowType,
    Value<String?> settings = const Value.absent(),
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Bow(
    id: id ?? this.id,
    name: name ?? this.name,
    bowType: bowType ?? this.bowType,
    settings: settings.present ? settings.value : this.settings,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Bow copyWithCompanion(BowsCompanion data) {
    return Bow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      bowType: data.bowType.present ? data.bowType.value : this.bowType,
      settings: data.settings.present ? data.settings.value : this.settings,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bowType: $bowType, ')
          ..write('settings: $settings, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, bowType, settings, isDefault, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bow &&
          other.id == this.id &&
          other.name == this.name &&
          other.bowType == this.bowType &&
          other.settings == this.settings &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BowsCompanion extends UpdateCompanion<Bow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> bowType;
  final Value<String?> settings;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.bowType = const Value.absent(),
    this.settings = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BowsCompanion.insert({
    required String id,
    required String name,
    required String bowType,
    this.settings = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       bowType = Value(bowType);
  static Insertable<Bow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? bowType,
    Expression<String>? settings,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (bowType != null) 'bow_type': bowType,
      if (settings != null) 'settings': settings,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BowsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? bowType,
    Value<String?>? settings,
    Value<bool>? isDefault,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      bowType: bowType ?? this.bowType,
      settings: settings ?? this.settings,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bowType.present) {
      map['bow_type'] = Variable<String>(bowType.value);
    }
    if (settings.present) {
      map['settings'] = Variable<String>(settings.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('BowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bowType: $bowType, ')
          ..write('settings: $settings, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuiversTable extends Quivers with TableInfo<$QuiversTable, Quiver> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuiversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bowIdMeta = const VerificationMeta('bowId');
  @override
  late final GeneratedColumn<String> bowId = GeneratedColumn<String>(
    'bow_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bows (id)',
    ),
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
  static const VerificationMeta _shaftCountMeta = const VerificationMeta(
    'shaftCount',
  );
  @override
  late final GeneratedColumn<int> shaftCount = GeneratedColumn<int>(
    'shaft_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(12),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bowId,
    name,
    shaftCount,
    isDefault,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quivers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Quiver> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bow_id')) {
      context.handle(
        _bowIdMeta,
        bowId.isAcceptableOrUnknown(data['bow_id']!, _bowIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('shaft_count')) {
      context.handle(
        _shaftCountMeta,
        shaftCount.isAcceptableOrUnknown(data['shaft_count']!, _shaftCountMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Quiver map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Quiver(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bow_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shaftCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shaft_count'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuiversTable createAlias(String alias) {
    return $QuiversTable(attachedDatabase, alias);
  }
}

class Quiver extends DataClass implements Insertable<Quiver> {
  final String id;
  final String? bowId;
  final String name;
  final int shaftCount;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Quiver({
    required this.id,
    this.bowId,
    required this.name,
    required this.shaftCount,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || bowId != null) {
      map['bow_id'] = Variable<String>(bowId);
    }
    map['name'] = Variable<String>(name);
    map['shaft_count'] = Variable<int>(shaftCount);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuiversCompanion toCompanion(bool nullToAbsent) {
    return QuiversCompanion(
      id: Value(id),
      bowId: bowId == null && nullToAbsent
          ? const Value.absent()
          : Value(bowId),
      name: Value(name),
      shaftCount: Value(shaftCount),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Quiver.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Quiver(
      id: serializer.fromJson<String>(json['id']),
      bowId: serializer.fromJson<String?>(json['bowId']),
      name: serializer.fromJson<String>(json['name']),
      shaftCount: serializer.fromJson<int>(json['shaftCount']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bowId': serializer.toJson<String?>(bowId),
      'name': serializer.toJson<String>(name),
      'shaftCount': serializer.toJson<int>(shaftCount),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Quiver copyWith({
    String? id,
    Value<String?> bowId = const Value.absent(),
    String? name,
    int? shaftCount,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Quiver(
    id: id ?? this.id,
    bowId: bowId.present ? bowId.value : this.bowId,
    name: name ?? this.name,
    shaftCount: shaftCount ?? this.shaftCount,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Quiver copyWithCompanion(QuiversCompanion data) {
    return Quiver(
      id: data.id.present ? data.id.value : this.id,
      bowId: data.bowId.present ? data.bowId.value : this.bowId,
      name: data.name.present ? data.name.value : this.name,
      shaftCount: data.shaftCount.present
          ? data.shaftCount.value
          : this.shaftCount,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Quiver(')
          ..write('id: $id, ')
          ..write('bowId: $bowId, ')
          ..write('name: $name, ')
          ..write('shaftCount: $shaftCount, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bowId, name, shaftCount, isDefault, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Quiver &&
          other.id == this.id &&
          other.bowId == this.bowId &&
          other.name == this.name &&
          other.shaftCount == this.shaftCount &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuiversCompanion extends UpdateCompanion<Quiver> {
  final Value<String> id;
  final Value<String?> bowId;
  final Value<String> name;
  final Value<int> shaftCount;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuiversCompanion({
    this.id = const Value.absent(),
    this.bowId = const Value.absent(),
    this.name = const Value.absent(),
    this.shaftCount = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuiversCompanion.insert({
    required String id,
    this.bowId = const Value.absent(),
    required String name,
    this.shaftCount = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Quiver> custom({
    Expression<String>? id,
    Expression<String>? bowId,
    Expression<String>? name,
    Expression<int>? shaftCount,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bowId != null) 'bow_id': bowId,
      if (name != null) 'name': name,
      if (shaftCount != null) 'shaft_count': shaftCount,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuiversCompanion copyWith({
    Value<String>? id,
    Value<String?>? bowId,
    Value<String>? name,
    Value<int>? shaftCount,
    Value<bool>? isDefault,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuiversCompanion(
      id: id ?? this.id,
      bowId: bowId ?? this.bowId,
      name: name ?? this.name,
      shaftCount: shaftCount ?? this.shaftCount,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bowId.present) {
      map['bow_id'] = Variable<String>(bowId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (shaftCount.present) {
      map['shaft_count'] = Variable<int>(shaftCount.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('QuiversCompanion(')
          ..write('id: $id, ')
          ..write('bowId: $bowId, ')
          ..write('name: $name, ')
          ..write('shaftCount: $shaftCount, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundTypeIdMeta = const VerificationMeta(
    'roundTypeId',
  );
  @override
  late final GeneratedColumn<String> roundTypeId = GeneratedColumn<String>(
    'round_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES round_types (id)',
    ),
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('practice'),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalScoreMeta = const VerificationMeta(
    'totalScore',
  );
  @override
  late final GeneratedColumn<int> totalScore = GeneratedColumn<int>(
    'total_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalXsMeta = const VerificationMeta(
    'totalXs',
  );
  @override
  late final GeneratedColumn<int> totalXs = GeneratedColumn<int>(
    'total_xs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bowIdMeta = const VerificationMeta('bowId');
  @override
  late final GeneratedColumn<String> bowId = GeneratedColumn<String>(
    'bow_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bows (id)',
    ),
  );
  static const VerificationMeta _quiverIdMeta = const VerificationMeta(
    'quiverId',
  );
  @override
  late final GeneratedColumn<String> quiverId = GeneratedColumn<String>(
    'quiver_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES quivers (id)',
    ),
  );
  static const VerificationMeta _shaftTaggingEnabledMeta =
      const VerificationMeta('shaftTaggingEnabled');
  @override
  late final GeneratedColumn<bool> shaftTaggingEnabled = GeneratedColumn<bool>(
    'shaft_tagging_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shaft_tagging_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roundTypeId,
    sessionType,
    location,
    notes,
    startedAt,
    completedAt,
    totalScore,
    totalXs,
    bowId,
    quiverId,
    shaftTaggingEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('round_type_id')) {
      context.handle(
        _roundTypeIdMeta,
        roundTypeId.isAcceptableOrUnknown(
          data['round_type_id']!,
          _roundTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roundTypeIdMeta);
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('total_score')) {
      context.handle(
        _totalScoreMeta,
        totalScore.isAcceptableOrUnknown(data['total_score']!, _totalScoreMeta),
      );
    }
    if (data.containsKey('total_xs')) {
      context.handle(
        _totalXsMeta,
        totalXs.isAcceptableOrUnknown(data['total_xs']!, _totalXsMeta),
      );
    }
    if (data.containsKey('bow_id')) {
      context.handle(
        _bowIdMeta,
        bowId.isAcceptableOrUnknown(data['bow_id']!, _bowIdMeta),
      );
    }
    if (data.containsKey('quiver_id')) {
      context.handle(
        _quiverIdMeta,
        quiverId.isAcceptableOrUnknown(data['quiver_id']!, _quiverIdMeta),
      );
    }
    if (data.containsKey('shaft_tagging_enabled')) {
      context.handle(
        _shaftTaggingEnabledMeta,
        shaftTaggingEnabled.isAcceptableOrUnknown(
          data['shaft_tagging_enabled']!,
          _shaftTaggingEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roundTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}round_type_id'],
      )!,
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      totalScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_score'],
      )!,
      totalXs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_xs'],
      )!,
      bowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bow_id'],
      ),
      quiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quiver_id'],
      ),
      shaftTaggingEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shaft_tagging_enabled'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String roundTypeId;
  final String sessionType;
  final String? location;
  final String? notes;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalScore;
  final int totalXs;
  final String? bowId;
  final String? quiverId;
  final bool shaftTaggingEnabled;
  const Session({
    required this.id,
    required this.roundTypeId,
    required this.sessionType,
    this.location,
    this.notes,
    required this.startedAt,
    this.completedAt,
    required this.totalScore,
    required this.totalXs,
    this.bowId,
    this.quiverId,
    required this.shaftTaggingEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['round_type_id'] = Variable<String>(roundTypeId);
    map['session_type'] = Variable<String>(sessionType);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['total_score'] = Variable<int>(totalScore);
    map['total_xs'] = Variable<int>(totalXs);
    if (!nullToAbsent || bowId != null) {
      map['bow_id'] = Variable<String>(bowId);
    }
    if (!nullToAbsent || quiverId != null) {
      map['quiver_id'] = Variable<String>(quiverId);
    }
    map['shaft_tagging_enabled'] = Variable<bool>(shaftTaggingEnabled);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      roundTypeId: Value(roundTypeId),
      sessionType: Value(sessionType),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      totalScore: Value(totalScore),
      totalXs: Value(totalXs),
      bowId: bowId == null && nullToAbsent
          ? const Value.absent()
          : Value(bowId),
      quiverId: quiverId == null && nullToAbsent
          ? const Value.absent()
          : Value(quiverId),
      shaftTaggingEnabled: Value(shaftTaggingEnabled),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      roundTypeId: serializer.fromJson<String>(json['roundTypeId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      location: serializer.fromJson<String?>(json['location']),
      notes: serializer.fromJson<String?>(json['notes']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      totalScore: serializer.fromJson<int>(json['totalScore']),
      totalXs: serializer.fromJson<int>(json['totalXs']),
      bowId: serializer.fromJson<String?>(json['bowId']),
      quiverId: serializer.fromJson<String?>(json['quiverId']),
      shaftTaggingEnabled: serializer.fromJson<bool>(
        json['shaftTaggingEnabled'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roundTypeId': serializer.toJson<String>(roundTypeId),
      'sessionType': serializer.toJson<String>(sessionType),
      'location': serializer.toJson<String?>(location),
      'notes': serializer.toJson<String?>(notes),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'totalScore': serializer.toJson<int>(totalScore),
      'totalXs': serializer.toJson<int>(totalXs),
      'bowId': serializer.toJson<String?>(bowId),
      'quiverId': serializer.toJson<String?>(quiverId),
      'shaftTaggingEnabled': serializer.toJson<bool>(shaftTaggingEnabled),
    };
  }

  Session copyWith({
    String? id,
    String? roundTypeId,
    String? sessionType,
    Value<String?> location = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    int? totalScore,
    int? totalXs,
    Value<String?> bowId = const Value.absent(),
    Value<String?> quiverId = const Value.absent(),
    bool? shaftTaggingEnabled,
  }) => Session(
    id: id ?? this.id,
    roundTypeId: roundTypeId ?? this.roundTypeId,
    sessionType: sessionType ?? this.sessionType,
    location: location.present ? location.value : this.location,
    notes: notes.present ? notes.value : this.notes,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    totalScore: totalScore ?? this.totalScore,
    totalXs: totalXs ?? this.totalXs,
    bowId: bowId.present ? bowId.value : this.bowId,
    quiverId: quiverId.present ? quiverId.value : this.quiverId,
    shaftTaggingEnabled: shaftTaggingEnabled ?? this.shaftTaggingEnabled,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      roundTypeId: data.roundTypeId.present
          ? data.roundTypeId.value
          : this.roundTypeId,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      location: data.location.present ? data.location.value : this.location,
      notes: data.notes.present ? data.notes.value : this.notes,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      totalScore: data.totalScore.present
          ? data.totalScore.value
          : this.totalScore,
      totalXs: data.totalXs.present ? data.totalXs.value : this.totalXs,
      bowId: data.bowId.present ? data.bowId.value : this.bowId,
      quiverId: data.quiverId.present ? data.quiverId.value : this.quiverId,
      shaftTaggingEnabled: data.shaftTaggingEnabled.present
          ? data.shaftTaggingEnabled.value
          : this.shaftTaggingEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('roundTypeId: $roundTypeId, ')
          ..write('sessionType: $sessionType, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('totalScore: $totalScore, ')
          ..write('totalXs: $totalXs, ')
          ..write('bowId: $bowId, ')
          ..write('quiverId: $quiverId, ')
          ..write('shaftTaggingEnabled: $shaftTaggingEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    roundTypeId,
    sessionType,
    location,
    notes,
    startedAt,
    completedAt,
    totalScore,
    totalXs,
    bowId,
    quiverId,
    shaftTaggingEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.roundTypeId == this.roundTypeId &&
          other.sessionType == this.sessionType &&
          other.location == this.location &&
          other.notes == this.notes &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.totalScore == this.totalScore &&
          other.totalXs == this.totalXs &&
          other.bowId == this.bowId &&
          other.quiverId == this.quiverId &&
          other.shaftTaggingEnabled == this.shaftTaggingEnabled);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> roundTypeId;
  final Value<String> sessionType;
  final Value<String?> location;
  final Value<String?> notes;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> totalScore;
  final Value<int> totalXs;
  final Value<String?> bowId;
  final Value<String?> quiverId;
  final Value<bool> shaftTaggingEnabled;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.roundTypeId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.totalXs = const Value.absent(),
    this.bowId = const Value.absent(),
    this.quiverId = const Value.absent(),
    this.shaftTaggingEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String roundTypeId,
    this.sessionType = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.totalXs = const Value.absent(),
    this.bowId = const Value.absent(),
    this.quiverId = const Value.absent(),
    this.shaftTaggingEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roundTypeId = Value(roundTypeId);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? roundTypeId,
    Expression<String>? sessionType,
    Expression<String>? location,
    Expression<String>? notes,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? totalScore,
    Expression<int>? totalXs,
    Expression<String>? bowId,
    Expression<String>? quiverId,
    Expression<bool>? shaftTaggingEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roundTypeId != null) 'round_type_id': roundTypeId,
      if (sessionType != null) 'session_type': sessionType,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (totalScore != null) 'total_score': totalScore,
      if (totalXs != null) 'total_xs': totalXs,
      if (bowId != null) 'bow_id': bowId,
      if (quiverId != null) 'quiver_id': quiverId,
      if (shaftTaggingEnabled != null)
        'shaft_tagging_enabled': shaftTaggingEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? roundTypeId,
    Value<String>? sessionType,
    Value<String?>? location,
    Value<String?>? notes,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? totalScore,
    Value<int>? totalXs,
    Value<String?>? bowId,
    Value<String?>? quiverId,
    Value<bool>? shaftTaggingEnabled,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      roundTypeId: roundTypeId ?? this.roundTypeId,
      sessionType: sessionType ?? this.sessionType,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalScore: totalScore ?? this.totalScore,
      totalXs: totalXs ?? this.totalXs,
      bowId: bowId ?? this.bowId,
      quiverId: quiverId ?? this.quiverId,
      shaftTaggingEnabled: shaftTaggingEnabled ?? this.shaftTaggingEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roundTypeId.present) {
      map['round_type_id'] = Variable<String>(roundTypeId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (totalScore.present) {
      map['total_score'] = Variable<int>(totalScore.value);
    }
    if (totalXs.present) {
      map['total_xs'] = Variable<int>(totalXs.value);
    }
    if (bowId.present) {
      map['bow_id'] = Variable<String>(bowId.value);
    }
    if (quiverId.present) {
      map['quiver_id'] = Variable<String>(quiverId.value);
    }
    if (shaftTaggingEnabled.present) {
      map['shaft_tagging_enabled'] = Variable<bool>(shaftTaggingEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('roundTypeId: $roundTypeId, ')
          ..write('sessionType: $sessionType, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('totalScore: $totalScore, ')
          ..write('totalXs: $totalXs, ')
          ..write('bowId: $bowId, ')
          ..write('quiverId: $quiverId, ')
          ..write('shaftTaggingEnabled: $shaftTaggingEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EndsTable extends Ends with TableInfo<$EndsTable, End> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EndsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _endNumberMeta = const VerificationMeta(
    'endNumber',
  );
  @override
  late final GeneratedColumn<int> endNumber = GeneratedColumn<int>(
    'end_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endScoreMeta = const VerificationMeta(
    'endScore',
  );
  @override
  late final GeneratedColumn<int> endScore = GeneratedColumn<int>(
    'end_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _endXsMeta = const VerificationMeta('endXs');
  @override
  late final GeneratedColumn<int> endXs = GeneratedColumn<int>(
    'end_xs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _committedAtMeta = const VerificationMeta(
    'committedAt',
  );
  @override
  late final GeneratedColumn<DateTime> committedAt = GeneratedColumn<DateTime>(
    'committed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    endNumber,
    endScore,
    endXs,
    status,
    committedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ends';
  @override
  VerificationContext validateIntegrity(
    Insertable<End> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('end_number')) {
      context.handle(
        _endNumberMeta,
        endNumber.isAcceptableOrUnknown(data['end_number']!, _endNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_endNumberMeta);
    }
    if (data.containsKey('end_score')) {
      context.handle(
        _endScoreMeta,
        endScore.isAcceptableOrUnknown(data['end_score']!, _endScoreMeta),
      );
    }
    if (data.containsKey('end_xs')) {
      context.handle(
        _endXsMeta,
        endXs.isAcceptableOrUnknown(data['end_xs']!, _endXsMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('committed_at')) {
      context.handle(
        _committedAtMeta,
        committedAt.isAcceptableOrUnknown(
          data['committed_at']!,
          _committedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  End map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return End(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      endNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_number'],
      )!,
      endScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_score'],
      )!,
      endXs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_xs'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      committedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}committed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EndsTable createAlias(String alias) {
    return $EndsTable(attachedDatabase, alias);
  }
}

class End extends DataClass implements Insertable<End> {
  final String id;
  final String sessionId;
  final int endNumber;
  final int endScore;
  final int endXs;
  final String status;
  final DateTime? committedAt;
  final DateTime createdAt;
  const End({
    required this.id,
    required this.sessionId,
    required this.endNumber,
    required this.endScore,
    required this.endXs,
    required this.status,
    this.committedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['end_number'] = Variable<int>(endNumber);
    map['end_score'] = Variable<int>(endScore);
    map['end_xs'] = Variable<int>(endXs);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || committedAt != null) {
      map['committed_at'] = Variable<DateTime>(committedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EndsCompanion toCompanion(bool nullToAbsent) {
    return EndsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      endNumber: Value(endNumber),
      endScore: Value(endScore),
      endXs: Value(endXs),
      status: Value(status),
      committedAt: committedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(committedAt),
      createdAt: Value(createdAt),
    );
  }

  factory End.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return End(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      endNumber: serializer.fromJson<int>(json['endNumber']),
      endScore: serializer.fromJson<int>(json['endScore']),
      endXs: serializer.fromJson<int>(json['endXs']),
      status: serializer.fromJson<String>(json['status']),
      committedAt: serializer.fromJson<DateTime?>(json['committedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'endNumber': serializer.toJson<int>(endNumber),
      'endScore': serializer.toJson<int>(endScore),
      'endXs': serializer.toJson<int>(endXs),
      'status': serializer.toJson<String>(status),
      'committedAt': serializer.toJson<DateTime?>(committedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  End copyWith({
    String? id,
    String? sessionId,
    int? endNumber,
    int? endScore,
    int? endXs,
    String? status,
    Value<DateTime?> committedAt = const Value.absent(),
    DateTime? createdAt,
  }) => End(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    endNumber: endNumber ?? this.endNumber,
    endScore: endScore ?? this.endScore,
    endXs: endXs ?? this.endXs,
    status: status ?? this.status,
    committedAt: committedAt.present ? committedAt.value : this.committedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  End copyWithCompanion(EndsCompanion data) {
    return End(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      endNumber: data.endNumber.present ? data.endNumber.value : this.endNumber,
      endScore: data.endScore.present ? data.endScore.value : this.endScore,
      endXs: data.endXs.present ? data.endXs.value : this.endXs,
      status: data.status.present ? data.status.value : this.status,
      committedAt: data.committedAt.present
          ? data.committedAt.value
          : this.committedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('End(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('endNumber: $endNumber, ')
          ..write('endScore: $endScore, ')
          ..write('endXs: $endXs, ')
          ..write('status: $status, ')
          ..write('committedAt: $committedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    endNumber,
    endScore,
    endXs,
    status,
    committedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is End &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.endNumber == this.endNumber &&
          other.endScore == this.endScore &&
          other.endXs == this.endXs &&
          other.status == this.status &&
          other.committedAt == this.committedAt &&
          other.createdAt == this.createdAt);
}

class EndsCompanion extends UpdateCompanion<End> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> endNumber;
  final Value<int> endScore;
  final Value<int> endXs;
  final Value<String> status;
  final Value<DateTime?> committedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EndsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.endNumber = const Value.absent(),
    this.endScore = const Value.absent(),
    this.endXs = const Value.absent(),
    this.status = const Value.absent(),
    this.committedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EndsCompanion.insert({
    required String id,
    required String sessionId,
    required int endNumber,
    this.endScore = const Value.absent(),
    this.endXs = const Value.absent(),
    this.status = const Value.absent(),
    this.committedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       endNumber = Value(endNumber);
  static Insertable<End> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? endNumber,
    Expression<int>? endScore,
    Expression<int>? endXs,
    Expression<String>? status,
    Expression<DateTime>? committedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (endNumber != null) 'end_number': endNumber,
      if (endScore != null) 'end_score': endScore,
      if (endXs != null) 'end_xs': endXs,
      if (status != null) 'status': status,
      if (committedAt != null) 'committed_at': committedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EndsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? endNumber,
    Value<int>? endScore,
    Value<int>? endXs,
    Value<String>? status,
    Value<DateTime?>? committedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EndsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      endNumber: endNumber ?? this.endNumber,
      endScore: endScore ?? this.endScore,
      endXs: endXs ?? this.endXs,
      status: status ?? this.status,
      committedAt: committedAt ?? this.committedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (endNumber.present) {
      map['end_number'] = Variable<int>(endNumber.value);
    }
    if (endScore.present) {
      map['end_score'] = Variable<int>(endScore.value);
    }
    if (endXs.present) {
      map['end_xs'] = Variable<int>(endXs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (committedAt.present) {
      map['committed_at'] = Variable<DateTime>(committedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EndsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('endNumber: $endNumber, ')
          ..write('endScore: $endScore, ')
          ..write('endXs: $endXs, ')
          ..write('status: $status, ')
          ..write('committedAt: $committedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArrowsTable extends Arrows with TableInfo<$ArrowsTable, Arrow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArrowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endIdMeta = const VerificationMeta('endId');
  @override
  late final GeneratedColumn<String> endId = GeneratedColumn<String>(
    'end_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ends (id)',
    ),
  );
  static const VerificationMeta _faceIndexMeta = const VerificationMeta(
    'faceIndex',
  );
  @override
  late final GeneratedColumn<int> faceIndex = GeneratedColumn<int>(
    'face_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isXMeta = const VerificationMeta('isX');
  @override
  late final GeneratedColumn<bool> isX = GeneratedColumn<bool>(
    'is_x',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_x" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shaftNumberMeta = const VerificationMeta(
    'shaftNumber',
  );
  @override
  late final GeneratedColumn<int> shaftNumber = GeneratedColumn<int>(
    'shaft_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    endId,
    faceIndex,
    x,
    y,
    score,
    isX,
    sequence,
    shaftNumber,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'arrows';
  @override
  VerificationContext validateIntegrity(
    Insertable<Arrow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('end_id')) {
      context.handle(
        _endIdMeta,
        endId.isAcceptableOrUnknown(data['end_id']!, _endIdMeta),
      );
    } else if (isInserting) {
      context.missing(_endIdMeta);
    }
    if (data.containsKey('face_index')) {
      context.handle(
        _faceIndexMeta,
        faceIndex.isAcceptableOrUnknown(data['face_index']!, _faceIndexMeta),
      );
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('is_x')) {
      context.handle(
        _isXMeta,
        isX.isAcceptableOrUnknown(data['is_x']!, _isXMeta),
      );
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('shaft_number')) {
      context.handle(
        _shaftNumberMeta,
        shaftNumber.isAcceptableOrUnknown(
          data['shaft_number']!,
          _shaftNumberMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Arrow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Arrow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      endId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_id'],
      )!,
      faceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}face_index'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      isX: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_x'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      shaftNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shaft_number'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ArrowsTable createAlias(String alias) {
    return $ArrowsTable(attachedDatabase, alias);
  }
}

class Arrow extends DataClass implements Insertable<Arrow> {
  final String id;
  final String endId;
  final int faceIndex;
  final double x;
  final double y;
  final int score;
  final bool isX;
  final int sequence;
  final int? shaftNumber;
  final DateTime createdAt;
  const Arrow({
    required this.id,
    required this.endId,
    required this.faceIndex,
    required this.x,
    required this.y,
    required this.score,
    required this.isX,
    required this.sequence,
    this.shaftNumber,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['end_id'] = Variable<String>(endId);
    map['face_index'] = Variable<int>(faceIndex);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['score'] = Variable<int>(score);
    map['is_x'] = Variable<bool>(isX);
    map['sequence'] = Variable<int>(sequence);
    if (!nullToAbsent || shaftNumber != null) {
      map['shaft_number'] = Variable<int>(shaftNumber);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ArrowsCompanion toCompanion(bool nullToAbsent) {
    return ArrowsCompanion(
      id: Value(id),
      endId: Value(endId),
      faceIndex: Value(faceIndex),
      x: Value(x),
      y: Value(y),
      score: Value(score),
      isX: Value(isX),
      sequence: Value(sequence),
      shaftNumber: shaftNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(shaftNumber),
      createdAt: Value(createdAt),
    );
  }

  factory Arrow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Arrow(
      id: serializer.fromJson<String>(json['id']),
      endId: serializer.fromJson<String>(json['endId']),
      faceIndex: serializer.fromJson<int>(json['faceIndex']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      score: serializer.fromJson<int>(json['score']),
      isX: serializer.fromJson<bool>(json['isX']),
      sequence: serializer.fromJson<int>(json['sequence']),
      shaftNumber: serializer.fromJson<int?>(json['shaftNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'endId': serializer.toJson<String>(endId),
      'faceIndex': serializer.toJson<int>(faceIndex),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'score': serializer.toJson<int>(score),
      'isX': serializer.toJson<bool>(isX),
      'sequence': serializer.toJson<int>(sequence),
      'shaftNumber': serializer.toJson<int?>(shaftNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Arrow copyWith({
    String? id,
    String? endId,
    int? faceIndex,
    double? x,
    double? y,
    int? score,
    bool? isX,
    int? sequence,
    Value<int?> shaftNumber = const Value.absent(),
    DateTime? createdAt,
  }) => Arrow(
    id: id ?? this.id,
    endId: endId ?? this.endId,
    faceIndex: faceIndex ?? this.faceIndex,
    x: x ?? this.x,
    y: y ?? this.y,
    score: score ?? this.score,
    isX: isX ?? this.isX,
    sequence: sequence ?? this.sequence,
    shaftNumber: shaftNumber.present ? shaftNumber.value : this.shaftNumber,
    createdAt: createdAt ?? this.createdAt,
  );
  Arrow copyWithCompanion(ArrowsCompanion data) {
    return Arrow(
      id: data.id.present ? data.id.value : this.id,
      endId: data.endId.present ? data.endId.value : this.endId,
      faceIndex: data.faceIndex.present ? data.faceIndex.value : this.faceIndex,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      score: data.score.present ? data.score.value : this.score,
      isX: data.isX.present ? data.isX.value : this.isX,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      shaftNumber: data.shaftNumber.present
          ? data.shaftNumber.value
          : this.shaftNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Arrow(')
          ..write('id: $id, ')
          ..write('endId: $endId, ')
          ..write('faceIndex: $faceIndex, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('score: $score, ')
          ..write('isX: $isX, ')
          ..write('sequence: $sequence, ')
          ..write('shaftNumber: $shaftNumber, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    endId,
    faceIndex,
    x,
    y,
    score,
    isX,
    sequence,
    shaftNumber,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Arrow &&
          other.id == this.id &&
          other.endId == this.endId &&
          other.faceIndex == this.faceIndex &&
          other.x == this.x &&
          other.y == this.y &&
          other.score == this.score &&
          other.isX == this.isX &&
          other.sequence == this.sequence &&
          other.shaftNumber == this.shaftNumber &&
          other.createdAt == this.createdAt);
}

class ArrowsCompanion extends UpdateCompanion<Arrow> {
  final Value<String> id;
  final Value<String> endId;
  final Value<int> faceIndex;
  final Value<double> x;
  final Value<double> y;
  final Value<int> score;
  final Value<bool> isX;
  final Value<int> sequence;
  final Value<int?> shaftNumber;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ArrowsCompanion({
    this.id = const Value.absent(),
    this.endId = const Value.absent(),
    this.faceIndex = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.score = const Value.absent(),
    this.isX = const Value.absent(),
    this.sequence = const Value.absent(),
    this.shaftNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArrowsCompanion.insert({
    required String id,
    required String endId,
    this.faceIndex = const Value.absent(),
    required double x,
    required double y,
    required int score,
    this.isX = const Value.absent(),
    required int sequence,
    this.shaftNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       endId = Value(endId),
       x = Value(x),
       y = Value(y),
       score = Value(score),
       sequence = Value(sequence);
  static Insertable<Arrow> custom({
    Expression<String>? id,
    Expression<String>? endId,
    Expression<int>? faceIndex,
    Expression<double>? x,
    Expression<double>? y,
    Expression<int>? score,
    Expression<bool>? isX,
    Expression<int>? sequence,
    Expression<int>? shaftNumber,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (endId != null) 'end_id': endId,
      if (faceIndex != null) 'face_index': faceIndex,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (score != null) 'score': score,
      if (isX != null) 'is_x': isX,
      if (sequence != null) 'sequence': sequence,
      if (shaftNumber != null) 'shaft_number': shaftNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArrowsCompanion copyWith({
    Value<String>? id,
    Value<String>? endId,
    Value<int>? faceIndex,
    Value<double>? x,
    Value<double>? y,
    Value<int>? score,
    Value<bool>? isX,
    Value<int>? sequence,
    Value<int?>? shaftNumber,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ArrowsCompanion(
      id: id ?? this.id,
      endId: endId ?? this.endId,
      faceIndex: faceIndex ?? this.faceIndex,
      x: x ?? this.x,
      y: y ?? this.y,
      score: score ?? this.score,
      isX: isX ?? this.isX,
      sequence: sequence ?? this.sequence,
      shaftNumber: shaftNumber ?? this.shaftNumber,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (endId.present) {
      map['end_id'] = Variable<String>(endId.value);
    }
    if (faceIndex.present) {
      map['face_index'] = Variable<int>(faceIndex.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (isX.present) {
      map['is_x'] = Variable<bool>(isX.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (shaftNumber.present) {
      map['shaft_number'] = Variable<int>(shaftNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArrowsCompanion(')
          ..write('id: $id, ')
          ..write('endId: $endId, ')
          ..write('faceIndex: $faceIndex, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('score: $score, ')
          ..write('isX: $isX, ')
          ..write('sequence: $sequence, ')
          ..write('shaftNumber: $shaftNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportedScoresTable extends ImportedScores
    with TableInfo<$ImportedScoresTable, ImportedScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportedScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundNameMeta = const VerificationMeta(
    'roundName',
  );
  @override
  late final GeneratedColumn<String> roundName = GeneratedColumn<String>(
    'round_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xCountMeta = const VerificationMeta('xCount');
  @override
  late final GeneratedColumn<int> xCount = GeneratedColumn<int>(
    'x_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('competition'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    roundName,
    score,
    xCount,
    location,
    notes,
    sessionType,
    source,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'imported_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportedScore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('round_name')) {
      context.handle(
        _roundNameMeta,
        roundName.isAcceptableOrUnknown(data['round_name']!, _roundNameMeta),
      );
    } else if (isInserting) {
      context.missing(_roundNameMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('x_count')) {
      context.handle(
        _xCountMeta,
        xCount.isAcceptableOrUnknown(data['x_count']!, _xCountMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportedScore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportedScore(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      roundName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}round_name'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      xCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x_count'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $ImportedScoresTable createAlias(String alias) {
    return $ImportedScoresTable(attachedDatabase, alias);
  }
}

class ImportedScore extends DataClass implements Insertable<ImportedScore> {
  final String id;
  final DateTime date;
  final String roundName;
  final int score;
  final int? xCount;
  final String? location;
  final String? notes;
  final String sessionType;
  final String source;
  final DateTime importedAt;
  const ImportedScore({
    required this.id,
    required this.date,
    required this.roundName,
    required this.score,
    this.xCount,
    this.location,
    this.notes,
    required this.sessionType,
    required this.source,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['round_name'] = Variable<String>(roundName);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || xCount != null) {
      map['x_count'] = Variable<int>(xCount);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['session_type'] = Variable<String>(sessionType);
    map['source'] = Variable<String>(source);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  ImportedScoresCompanion toCompanion(bool nullToAbsent) {
    return ImportedScoresCompanion(
      id: Value(id),
      date: Value(date),
      roundName: Value(roundName),
      score: Value(score),
      xCount: xCount == null && nullToAbsent
          ? const Value.absent()
          : Value(xCount),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      sessionType: Value(sessionType),
      source: Value(source),
      importedAt: Value(importedAt),
    );
  }

  factory ImportedScore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportedScore(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      roundName: serializer.fromJson<String>(json['roundName']),
      score: serializer.fromJson<int>(json['score']),
      xCount: serializer.fromJson<int?>(json['xCount']),
      location: serializer.fromJson<String?>(json['location']),
      notes: serializer.fromJson<String?>(json['notes']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      source: serializer.fromJson<String>(json['source']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'roundName': serializer.toJson<String>(roundName),
      'score': serializer.toJson<int>(score),
      'xCount': serializer.toJson<int?>(xCount),
      'location': serializer.toJson<String?>(location),
      'notes': serializer.toJson<String?>(notes),
      'sessionType': serializer.toJson<String>(sessionType),
      'source': serializer.toJson<String>(source),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  ImportedScore copyWith({
    String? id,
    DateTime? date,
    String? roundName,
    int? score,
    Value<int?> xCount = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? sessionType,
    String? source,
    DateTime? importedAt,
  }) => ImportedScore(
    id: id ?? this.id,
    date: date ?? this.date,
    roundName: roundName ?? this.roundName,
    score: score ?? this.score,
    xCount: xCount.present ? xCount.value : this.xCount,
    location: location.present ? location.value : this.location,
    notes: notes.present ? notes.value : this.notes,
    sessionType: sessionType ?? this.sessionType,
    source: source ?? this.source,
    importedAt: importedAt ?? this.importedAt,
  );
  ImportedScore copyWithCompanion(ImportedScoresCompanion data) {
    return ImportedScore(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      roundName: data.roundName.present ? data.roundName.value : this.roundName,
      score: data.score.present ? data.score.value : this.score,
      xCount: data.xCount.present ? data.xCount.value : this.xCount,
      location: data.location.present ? data.location.value : this.location,
      notes: data.notes.present ? data.notes.value : this.notes,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      source: data.source.present ? data.source.value : this.source,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportedScore(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('roundName: $roundName, ')
          ..write('score: $score, ')
          ..write('xCount: $xCount, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('sessionType: $sessionType, ')
          ..write('source: $source, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    roundName,
    score,
    xCount,
    location,
    notes,
    sessionType,
    source,
    importedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportedScore &&
          other.id == this.id &&
          other.date == this.date &&
          other.roundName == this.roundName &&
          other.score == this.score &&
          other.xCount == this.xCount &&
          other.location == this.location &&
          other.notes == this.notes &&
          other.sessionType == this.sessionType &&
          other.source == this.source &&
          other.importedAt == this.importedAt);
}

class ImportedScoresCompanion extends UpdateCompanion<ImportedScore> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<String> roundName;
  final Value<int> score;
  final Value<int?> xCount;
  final Value<String?> location;
  final Value<String?> notes;
  final Value<String> sessionType;
  final Value<String> source;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const ImportedScoresCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.roundName = const Value.absent(),
    this.score = const Value.absent(),
    this.xCount = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.source = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportedScoresCompanion.insert({
    required String id,
    required DateTime date,
    required String roundName,
    required int score,
    this.xCount = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.source = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       roundName = Value(roundName),
       score = Value(score);
  static Insertable<ImportedScore> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? roundName,
    Expression<int>? score,
    Expression<int>? xCount,
    Expression<String>? location,
    Expression<String>? notes,
    Expression<String>? sessionType,
    Expression<String>? source,
    Expression<DateTime>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (roundName != null) 'round_name': roundName,
      if (score != null) 'score': score,
      if (xCount != null) 'x_count': xCount,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (sessionType != null) 'session_type': sessionType,
      if (source != null) 'source': source,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportedScoresCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<String>? roundName,
    Value<int>? score,
    Value<int?>? xCount,
    Value<String?>? location,
    Value<String?>? notes,
    Value<String>? sessionType,
    Value<String>? source,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return ImportedScoresCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      roundName: roundName ?? this.roundName,
      score: score ?? this.score,
      xCount: xCount ?? this.xCount,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      sessionType: sessionType ?? this.sessionType,
      source: source ?? this.source,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (roundName.present) {
      map['round_name'] = Variable<String>(roundName.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (xCount.present) {
      map['x_count'] = Variable<int>(xCount.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportedScoresCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('roundName: $roundName, ')
          ..write('score: $score, ')
          ..write('xCount: $xCount, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('sessionType: $sessionType, ')
          ..write('source: $source, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTable extends UserPreferences
    with TableInfo<$UserPreferencesTable, UserPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UserPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $UserPreferencesTable createAlias(String alias) {
    return $UserPreferencesTable(attachedDatabase, alias);
  }
}

class UserPreference extends DataClass implements Insertable<UserPreference> {
  final String key;
  final String value;
  const UserPreference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  UserPreferencesCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory UserPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  UserPreference copyWith({String? key, String? value}) =>
      UserPreference(key: key ?? this.key, value: value ?? this.value);
  UserPreference copyWithCompanion(UserPreferencesCompanion data) {
    return UserPreference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreference &&
          other.key == this.key &&
          other.value == this.value);
}

class UserPreferencesCompanion extends UpdateCompanion<UserPreference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const UserPreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<UserPreference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return UserPreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShaftsTable extends Shafts with TableInfo<$ShaftsTable, Shaft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShaftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quiverIdMeta = const VerificationMeta(
    'quiverId',
  );
  @override
  late final GeneratedColumn<String> quiverId = GeneratedColumn<String>(
    'quiver_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES quivers (id)',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diameterMeta = const VerificationMeta(
    'diameter',
  );
  @override
  late final GeneratedColumn<String> diameter = GeneratedColumn<String>(
    'diameter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _retiredAtMeta = const VerificationMeta(
    'retiredAt',
  );
  @override
  late final GeneratedColumn<DateTime> retiredAt = GeneratedColumn<DateTime>(
    'retired_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    quiverId,
    number,
    diameter,
    notes,
    createdAt,
    retiredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Shaft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('quiver_id')) {
      context.handle(
        _quiverIdMeta,
        quiverId.isAcceptableOrUnknown(data['quiver_id']!, _quiverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_quiverIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('diameter')) {
      context.handle(
        _diameterMeta,
        diameter.isAcceptableOrUnknown(data['diameter']!, _diameterMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('retired_at')) {
      context.handle(
        _retiredAtMeta,
        retiredAt.isAcceptableOrUnknown(data['retired_at']!, _retiredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shaft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shaft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      quiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quiver_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      diameter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diameter'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retired_at'],
      ),
    );
  }

  @override
  $ShaftsTable createAlias(String alias) {
    return $ShaftsTable(attachedDatabase, alias);
  }
}

class Shaft extends DataClass implements Insertable<Shaft> {
  final String id;
  final String quiverId;
  final int number;
  final String? diameter;
  final String? notes;
  final DateTime createdAt;
  final DateTime? retiredAt;
  const Shaft({
    required this.id,
    required this.quiverId,
    required this.number,
    this.diameter,
    this.notes,
    required this.createdAt,
    this.retiredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['quiver_id'] = Variable<String>(quiverId);
    map['number'] = Variable<int>(number);
    if (!nullToAbsent || diameter != null) {
      map['diameter'] = Variable<String>(diameter);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || retiredAt != null) {
      map['retired_at'] = Variable<DateTime>(retiredAt);
    }
    return map;
  }

  ShaftsCompanion toCompanion(bool nullToAbsent) {
    return ShaftsCompanion(
      id: Value(id),
      quiverId: Value(quiverId),
      number: Value(number),
      diameter: diameter == null && nullToAbsent
          ? const Value.absent()
          : Value(diameter),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      retiredAt: retiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredAt),
    );
  }

  factory Shaft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shaft(
      id: serializer.fromJson<String>(json['id']),
      quiverId: serializer.fromJson<String>(json['quiverId']),
      number: serializer.fromJson<int>(json['number']),
      diameter: serializer.fromJson<String?>(json['diameter']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retiredAt: serializer.fromJson<DateTime?>(json['retiredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'quiverId': serializer.toJson<String>(quiverId),
      'number': serializer.toJson<int>(number),
      'diameter': serializer.toJson<String?>(diameter),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retiredAt': serializer.toJson<DateTime?>(retiredAt),
    };
  }

  Shaft copyWith({
    String? id,
    String? quiverId,
    int? number,
    Value<String?> diameter = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> retiredAt = const Value.absent(),
  }) => Shaft(
    id: id ?? this.id,
    quiverId: quiverId ?? this.quiverId,
    number: number ?? this.number,
    diameter: diameter.present ? diameter.value : this.diameter,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    retiredAt: retiredAt.present ? retiredAt.value : this.retiredAt,
  );
  Shaft copyWithCompanion(ShaftsCompanion data) {
    return Shaft(
      id: data.id.present ? data.id.value : this.id,
      quiverId: data.quiverId.present ? data.quiverId.value : this.quiverId,
      number: data.number.present ? data.number.value : this.number,
      diameter: data.diameter.present ? data.diameter.value : this.diameter,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retiredAt: data.retiredAt.present ? data.retiredAt.value : this.retiredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shaft(')
          ..write('id: $id, ')
          ..write('quiverId: $quiverId, ')
          ..write('number: $number, ')
          ..write('diameter: $diameter, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('retiredAt: $retiredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, quiverId, number, diameter, notes, createdAt, retiredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shaft &&
          other.id == this.id &&
          other.quiverId == this.quiverId &&
          other.number == this.number &&
          other.diameter == this.diameter &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.retiredAt == this.retiredAt);
}

class ShaftsCompanion extends UpdateCompanion<Shaft> {
  final Value<String> id;
  final Value<String> quiverId;
  final Value<int> number;
  final Value<String?> diameter;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> retiredAt;
  final Value<int> rowid;
  const ShaftsCompanion({
    this.id = const Value.absent(),
    this.quiverId = const Value.absent(),
    this.number = const Value.absent(),
    this.diameter = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retiredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShaftsCompanion.insert({
    required String id,
    required String quiverId,
    required int number,
    this.diameter = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retiredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       quiverId = Value(quiverId),
       number = Value(number);
  static Insertable<Shaft> custom({
    Expression<String>? id,
    Expression<String>? quiverId,
    Expression<int>? number,
    Expression<String>? diameter,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? retiredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (quiverId != null) 'quiver_id': quiverId,
      if (number != null) 'number': number,
      if (diameter != null) 'diameter': diameter,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (retiredAt != null) 'retired_at': retiredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShaftsCompanion copyWith({
    Value<String>? id,
    Value<String>? quiverId,
    Value<int>? number,
    Value<String?>? diameter,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? retiredAt,
    Value<int>? rowid,
  }) {
    return ShaftsCompanion(
      id: id ?? this.id,
      quiverId: quiverId ?? this.quiverId,
      number: number ?? this.number,
      diameter: diameter ?? this.diameter,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      retiredAt: retiredAt ?? this.retiredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (quiverId.present) {
      map['quiver_id'] = Variable<String>(quiverId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (diameter.present) {
      map['diameter'] = Variable<String>(diameter.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retiredAt.present) {
      map['retired_at'] = Variable<DateTime>(retiredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShaftsCompanion(')
          ..write('id: $id, ')
          ..write('quiverId: $quiverId, ')
          ..write('number: $number, ')
          ..write('diameter: $diameter, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('retiredAt: $retiredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VolumeEntriesTable extends VolumeEntries
    with TableInfo<$VolumeEntriesTable, VolumeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VolumeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arrowCountMeta = const VerificationMeta(
    'arrowCount',
  );
  @override
  late final GeneratedColumn<int> arrowCount = GeneratedColumn<int>(
    'arrow_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    arrowCount,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'volume_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<VolumeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('arrow_count')) {
      context.handle(
        _arrowCountMeta,
        arrowCount.isAcceptableOrUnknown(data['arrow_count']!, _arrowCountMeta),
      );
    } else if (isInserting) {
      context.missing(_arrowCountMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VolumeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VolumeEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      arrowCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}arrow_count'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VolumeEntriesTable createAlias(String alias) {
    return $VolumeEntriesTable(attachedDatabase, alias);
  }
}

class VolumeEntry extends DataClass implements Insertable<VolumeEntry> {
  final String id;
  final DateTime date;
  final int arrowCount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VolumeEntry({
    required this.id,
    required this.date,
    required this.arrowCount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['arrow_count'] = Variable<int>(arrowCount);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VolumeEntriesCompanion toCompanion(bool nullToAbsent) {
    return VolumeEntriesCompanion(
      id: Value(id),
      date: Value(date),
      arrowCount: Value(arrowCount),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VolumeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VolumeEntry(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      arrowCount: serializer.fromJson<int>(json['arrowCount']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'arrowCount': serializer.toJson<int>(arrowCount),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VolumeEntry copyWith({
    String? id,
    DateTime? date,
    int? arrowCount,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VolumeEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    arrowCount: arrowCount ?? this.arrowCount,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VolumeEntry copyWithCompanion(VolumeEntriesCompanion data) {
    return VolumeEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      arrowCount: data.arrowCount.present
          ? data.arrowCount.value
          : this.arrowCount,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VolumeEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('arrowCount: $arrowCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, arrowCount, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VolumeEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.arrowCount == this.arrowCount &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VolumeEntriesCompanion extends UpdateCompanion<VolumeEntry> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<int> arrowCount;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VolumeEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.arrowCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VolumeEntriesCompanion.insert({
    required String id,
    required DateTime date,
    required int arrowCount,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       arrowCount = Value(arrowCount);
  static Insertable<VolumeEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<int>? arrowCount,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (arrowCount != null) 'arrow_count': arrowCount,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VolumeEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<int>? arrowCount,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VolumeEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      arrowCount: arrowCount ?? this.arrowCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (arrowCount.present) {
      map['arrow_count'] = Variable<int>(arrowCount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('VolumeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('arrowCount: $arrowCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RoundTypesTable roundTypes = $RoundTypesTable(this);
  late final $BowsTable bows = $BowsTable(this);
  late final $QuiversTable quivers = $QuiversTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $EndsTable ends = $EndsTable(this);
  late final $ArrowsTable arrows = $ArrowsTable(this);
  late final $ImportedScoresTable importedScores = $ImportedScoresTable(this);
  late final $UserPreferencesTable userPreferences = $UserPreferencesTable(
    this,
  );
  late final $ShaftsTable shafts = $ShaftsTable(this);
  late final $VolumeEntriesTable volumeEntries = $VolumeEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    roundTypes,
    bows,
    quivers,
    sessions,
    ends,
    arrows,
    importedScores,
    userPreferences,
    shafts,
    volumeEntries,
  ];
}

typedef $$RoundTypesTableCreateCompanionBuilder =
    RoundTypesCompanion Function({
      required String id,
      required String name,
      required String category,
      required int distance,
      required int faceSize,
      required int arrowsPerEnd,
      required int totalEnds,
      required int maxScore,
      required bool isIndoor,
      Value<int> faceCount,
      Value<int> rowid,
    });
typedef $$RoundTypesTableUpdateCompanionBuilder =
    RoundTypesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<int> distance,
      Value<int> faceSize,
      Value<int> arrowsPerEnd,
      Value<int> totalEnds,
      Value<int> maxScore,
      Value<bool> isIndoor,
      Value<int> faceCount,
      Value<int> rowid,
    });

final class $$RoundTypesTableReferences
    extends BaseReferences<_$AppDatabase, $RoundTypesTable, RoundType> {
  $$RoundTypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.roundTypes.id, db.sessions.roundTypeId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.roundTypeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoundTypesTableFilterComposer
    extends Composer<_$AppDatabase, $RoundTypesTable> {
  $$RoundTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get faceSize => $composableBuilder(
    column: $table.faceSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get arrowsPerEnd => $composableBuilder(
    column: $table.arrowsPerEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalEnds => $composableBuilder(
    column: $table.totalEnds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIndoor => $composableBuilder(
    column: $table.isIndoor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get faceCount => $composableBuilder(
    column: $table.faceCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.roundTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoundTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoundTypesTable> {
  $$RoundTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faceSize => $composableBuilder(
    column: $table.faceSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get arrowsPerEnd => $composableBuilder(
    column: $table.arrowsPerEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalEnds => $composableBuilder(
    column: $table.totalEnds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIndoor => $composableBuilder(
    column: $table.isIndoor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faceCount => $composableBuilder(
    column: $table.faceCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoundTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoundTypesTable> {
  $$RoundTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<int> get faceSize =>
      $composableBuilder(column: $table.faceSize, builder: (column) => column);

  GeneratedColumn<int> get arrowsPerEnd => $composableBuilder(
    column: $table.arrowsPerEnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalEnds =>
      $composableBuilder(column: $table.totalEnds, builder: (column) => column);

  GeneratedColumn<int> get maxScore =>
      $composableBuilder(column: $table.maxScore, builder: (column) => column);

  GeneratedColumn<bool> get isIndoor =>
      $composableBuilder(column: $table.isIndoor, builder: (column) => column);

  GeneratedColumn<int> get faceCount =>
      $composableBuilder(column: $table.faceCount, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.roundTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoundTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoundTypesTable,
          RoundType,
          $$RoundTypesTableFilterComposer,
          $$RoundTypesTableOrderingComposer,
          $$RoundTypesTableAnnotationComposer,
          $$RoundTypesTableCreateCompanionBuilder,
          $$RoundTypesTableUpdateCompanionBuilder,
          (RoundType, $$RoundTypesTableReferences),
          RoundType,
          PrefetchHooks Function({bool sessionsRefs})
        > {
  $$RoundTypesTableTableManager(_$AppDatabase db, $RoundTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoundTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoundTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoundTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> distance = const Value.absent(),
                Value<int> faceSize = const Value.absent(),
                Value<int> arrowsPerEnd = const Value.absent(),
                Value<int> totalEnds = const Value.absent(),
                Value<int> maxScore = const Value.absent(),
                Value<bool> isIndoor = const Value.absent(),
                Value<int> faceCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoundTypesCompanion(
                id: id,
                name: name,
                category: category,
                distance: distance,
                faceSize: faceSize,
                arrowsPerEnd: arrowsPerEnd,
                totalEnds: totalEnds,
                maxScore: maxScore,
                isIndoor: isIndoor,
                faceCount: faceCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required int distance,
                required int faceSize,
                required int arrowsPerEnd,
                required int totalEnds,
                required int maxScore,
                required bool isIndoor,
                Value<int> faceCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoundTypesCompanion.insert(
                id: id,
                name: name,
                category: category,
                distance: distance,
                faceSize: faceSize,
                arrowsPerEnd: arrowsPerEnd,
                totalEnds: totalEnds,
                maxScore: maxScore,
                isIndoor: isIndoor,
                faceCount: faceCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RoundTypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionsRefs) db.sessions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<
                      RoundType,
                      $RoundTypesTable,
                      Session
                    >(
                      currentTable: table,
                      referencedTable: $$RoundTypesTableReferences
                          ._sessionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RoundTypesTableReferences(
                            db,
                            table,
                            p0,
                          ).sessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.roundTypeId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoundTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoundTypesTable,
      RoundType,
      $$RoundTypesTableFilterComposer,
      $$RoundTypesTableOrderingComposer,
      $$RoundTypesTableAnnotationComposer,
      $$RoundTypesTableCreateCompanionBuilder,
      $$RoundTypesTableUpdateCompanionBuilder,
      (RoundType, $$RoundTypesTableReferences),
      RoundType,
      PrefetchHooks Function({bool sessionsRefs})
    >;
typedef $$BowsTableCreateCompanionBuilder =
    BowsCompanion Function({
      required String id,
      required String name,
      required String bowType,
      Value<String?> settings,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BowsTableUpdateCompanionBuilder =
    BowsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> bowType,
      Value<String?> settings,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BowsTableReferences
    extends BaseReferences<_$AppDatabase, $BowsTable, Bow> {
  $$BowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QuiversTable, List<Quiver>> _quiversRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.quivers,
    aliasName: $_aliasNameGenerator(db.bows.id, db.quivers.bowId),
  );

  $$QuiversTableProcessedTableManager get quiversRefs {
    final manager = $$QuiversTableTableManager(
      $_db,
      $_db.quivers,
    ).filter((f) => f.bowId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_quiversRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.bows.id, db.sessions.bowId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.bowId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BowsTableFilterComposer extends Composer<_$AppDatabase, $BowsTable> {
  $$BowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bowType => $composableBuilder(
    column: $table.bowType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> quiversRefs(
    Expression<bool> Function($$QuiversTableFilterComposer f) f,
  ) {
    final $$QuiversTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quivers,
      getReferencedColumn: (t) => t.bowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuiversTableFilterComposer(
            $db: $db,
            $table: $db.quivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.bowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BowsTableOrderingComposer extends Composer<_$AppDatabase, $BowsTable> {
  $$BowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bowType => $composableBuilder(
    column: $table.bowType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BowsTable> {
  $$BowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get bowType =>
      $composableBuilder(column: $table.bowType, builder: (column) => column);

  GeneratedColumn<String> get settings =>
      $composableBuilder(column: $table.settings, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> quiversRefs<T extends Object>(
    Expression<T> Function($$QuiversTableAnnotationComposer a) f,
  ) {
    final $$QuiversTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quivers,
      getReferencedColumn: (t) => t.bowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuiversTableAnnotationComposer(
            $db: $db,
            $table: $db.quivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.bowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BowsTable,
          Bow,
          $$BowsTableFilterComposer,
          $$BowsTableOrderingComposer,
          $$BowsTableAnnotationComposer,
          $$BowsTableCreateCompanionBuilder,
          $$BowsTableUpdateCompanionBuilder,
          (Bow, $$BowsTableReferences),
          Bow,
          PrefetchHooks Function({bool quiversRefs, bool sessionsRefs})
        > {
  $$BowsTableTableManager(_$AppDatabase db, $BowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> bowType = const Value.absent(),
                Value<String?> settings = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BowsCompanion(
                id: id,
                name: name,
                bowType: bowType,
                settings: settings,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String bowType,
                Value<String?> settings = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BowsCompanion.insert(
                id: id,
                name: name,
                bowType: bowType,
                settings: settings,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BowsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({quiversRefs = false, sessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (quiversRefs) db.quivers,
                if (sessionsRefs) db.sessions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (quiversRefs)
                    await $_getPrefetchedData<Bow, $BowsTable, Quiver>(
                      currentTable: table,
                      referencedTable: $$BowsTableReferences._quiversRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$BowsTableReferences(db, table, p0).quiversRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.bowId == item.id),
                      typedResults: items,
                    ),
                  if (sessionsRefs)
                    await $_getPrefetchedData<Bow, $BowsTable, Session>(
                      currentTable: table,
                      referencedTable: $$BowsTableReferences._sessionsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$BowsTableReferences(db, table, p0).sessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.bowId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BowsTable,
      Bow,
      $$BowsTableFilterComposer,
      $$BowsTableOrderingComposer,
      $$BowsTableAnnotationComposer,
      $$BowsTableCreateCompanionBuilder,
      $$BowsTableUpdateCompanionBuilder,
      (Bow, $$BowsTableReferences),
      Bow,
      PrefetchHooks Function({bool quiversRefs, bool sessionsRefs})
    >;
typedef $$QuiversTableCreateCompanionBuilder =
    QuiversCompanion Function({
      required String id,
      Value<String?> bowId,
      required String name,
      Value<int> shaftCount,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$QuiversTableUpdateCompanionBuilder =
    QuiversCompanion Function({
      Value<String> id,
      Value<String?> bowId,
      Value<String> name,
      Value<int> shaftCount,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$QuiversTableReferences
    extends BaseReferences<_$AppDatabase, $QuiversTable, Quiver> {
  $$QuiversTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BowsTable _bowIdTable(_$AppDatabase db) =>
      db.bows.createAlias($_aliasNameGenerator(db.quivers.bowId, db.bows.id));

  $$BowsTableProcessedTableManager? get bowId {
    final $_column = $_itemColumn<String>('bow_id');
    if ($_column == null) return null;
    final manager = $$BowsTableTableManager(
      $_db,
      $_db.bows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bowIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.quivers.id, db.sessions.quiverId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.quiverId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShaftsTable, List<Shaft>> _shaftsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.shafts,
    aliasName: $_aliasNameGenerator(db.quivers.id, db.shafts.quiverId),
  );

  $$ShaftsTableProcessedTableManager get shaftsRefs {
    final manager = $$ShaftsTableTableManager(
      $_db,
      $_db.shafts,
    ).filter((f) => f.quiverId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shaftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuiversTableFilterComposer
    extends Composer<_$AppDatabase, $QuiversTable> {
  $$QuiversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shaftCount => $composableBuilder(
    column: $table.shaftCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BowsTableFilterComposer get bowId {
    final $$BowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bowId,
      referencedTable: $db.bows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BowsTableFilterComposer(
            $db: $db,
            $table: $db.bows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.quiverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shaftsRefs(
    Expression<bool> Function($$ShaftsTableFilterComposer f) f,
  ) {
    final $$ShaftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shafts,
      getReferencedColumn: (t) => t.quiverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShaftsTableFilterComposer(
            $db: $db,
            $table: $db.shafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuiversTableOrderingComposer
    extends Composer<_$AppDatabase, $QuiversTable> {
  $$QuiversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shaftCount => $composableBuilder(
    column: $table.shaftCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BowsTableOrderingComposer get bowId {
    final $$BowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bowId,
      referencedTable: $db.bows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BowsTableOrderingComposer(
            $db: $db,
            $table: $db.bows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuiversTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuiversTable> {
  $$QuiversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get shaftCount => $composableBuilder(
    column: $table.shaftCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BowsTableAnnotationComposer get bowId {
    final $$BowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bowId,
      referencedTable: $db.bows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BowsTableAnnotationComposer(
            $db: $db,
            $table: $db.bows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.quiverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shaftsRefs<T extends Object>(
    Expression<T> Function($$ShaftsTableAnnotationComposer a) f,
  ) {
    final $$ShaftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shafts,
      getReferencedColumn: (t) => t.quiverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShaftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuiversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuiversTable,
          Quiver,
          $$QuiversTableFilterComposer,
          $$QuiversTableOrderingComposer,
          $$QuiversTableAnnotationComposer,
          $$QuiversTableCreateCompanionBuilder,
          $$QuiversTableUpdateCompanionBuilder,
          (Quiver, $$QuiversTableReferences),
          Quiver,
          PrefetchHooks Function({
            bool bowId,
            bool sessionsRefs,
            bool shaftsRefs,
          })
        > {
  $$QuiversTableTableManager(_$AppDatabase db, $QuiversTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuiversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuiversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuiversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> bowId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> shaftCount = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuiversCompanion(
                id: id,
                bowId: bowId,
                name: name,
                shaftCount: shaftCount,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> bowId = const Value.absent(),
                required String name,
                Value<int> shaftCount = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuiversCompanion.insert(
                id: id,
                bowId: bowId,
                name: name,
                shaftCount: shaftCount,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuiversTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({bowId = false, sessionsRefs = false, shaftsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionsRefs) db.sessions,
                    if (shaftsRefs) db.shafts,
                  ],
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
                        if (bowId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bowId,
                                    referencedTable: $$QuiversTableReferences
                                        ._bowIdTable(db),
                                    referencedColumn: $$QuiversTableReferences
                                        ._bowIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionsRefs)
                        await $_getPrefetchedData<
                          Quiver,
                          $QuiversTable,
                          Session
                        >(
                          currentTable: table,
                          referencedTable: $$QuiversTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuiversTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.quiverId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shaftsRefs)
                        await $_getPrefetchedData<Quiver, $QuiversTable, Shaft>(
                          currentTable: table,
                          referencedTable: $$QuiversTableReferences
                              ._shaftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuiversTableReferences(
                                db,
                                table,
                                p0,
                              ).shaftsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.quiverId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$QuiversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuiversTable,
      Quiver,
      $$QuiversTableFilterComposer,
      $$QuiversTableOrderingComposer,
      $$QuiversTableAnnotationComposer,
      $$QuiversTableCreateCompanionBuilder,
      $$QuiversTableUpdateCompanionBuilder,
      (Quiver, $$QuiversTableReferences),
      Quiver,
      PrefetchHooks Function({bool bowId, bool sessionsRefs, bool shaftsRefs})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required String roundTypeId,
      Value<String> sessionType,
      Value<String?> location,
      Value<String?> notes,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<int> totalScore,
      Value<int> totalXs,
      Value<String?> bowId,
      Value<String?> quiverId,
      Value<bool> shaftTaggingEnabled,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String> roundTypeId,
      Value<String> sessionType,
      Value<String?> location,
      Value<String?> notes,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<int> totalScore,
      Value<int> totalXs,
      Value<String?> bowId,
      Value<String?> quiverId,
      Value<bool> shaftTaggingEnabled,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoundTypesTable _roundTypeIdTable(_$AppDatabase db) =>
      db.roundTypes.createAlias(
        $_aliasNameGenerator(db.sessions.roundTypeId, db.roundTypes.id),
      );

  $$RoundTypesTableProcessedTableManager get roundTypeId {
    final $_column = $_itemColumn<String>('round_type_id')!;

    final manager = $$RoundTypesTableTableManager(
      $_db,
      $_db.roundTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roundTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BowsTable _bowIdTable(_$AppDatabase db) =>
      db.bows.createAlias($_aliasNameGenerator(db.sessions.bowId, db.bows.id));

  $$BowsTableProcessedTableManager? get bowId {
    final $_column = $_itemColumn<String>('bow_id');
    if ($_column == null) return null;
    final manager = $$BowsTableTableManager(
      $_db,
      $_db.bows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bowIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $QuiversTable _quiverIdTable(_$AppDatabase db) => db.quivers
      .createAlias($_aliasNameGenerator(db.sessions.quiverId, db.quivers.id));

  $$QuiversTableProcessedTableManager? get quiverId {
    final $_column = $_itemColumn<String>('quiver_id');
    if ($_column == null) return null;
    final manager = $$QuiversTableTableManager(
      $_db,
      $_db.quivers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_quiverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EndsTable, List<End>> _endsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ends,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.ends.sessionId),
  );

  $$EndsTableProcessedTableManager get endsRefs {
    final manager = $$EndsTableTableManager(
      $_db,
      $_db.ends,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_endsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalXs => $composableBuilder(
    column: $table.totalXs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shaftTaggingEnabled => $composableBuilder(
    column: $table.shaftTaggingEnabled,
    builder: (column) => ColumnFilters(column),
  );

  $$RoundTypesTableFilterComposer get roundTypeId {
    final $$RoundTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roundTypeId,
      referencedTable: $db.roundTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundTypesTableFilterComposer(
            $db: $db,
            $table: $db.roundTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BowsTableFilterComposer get bowId {
    final $$BowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bowId,
      referencedTable: $db.bows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BowsTableFilterComposer(
            $db: $db,
            $table: $db.bows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$QuiversTableFilterComposer get quiverId {
    final $$QuiversTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quiverId,
      referencedTable: $db.quivers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuiversTableFilterComposer(
            $db: $db,
            $table: $db.quivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> endsRefs(
    Expression<bool> Function($$EndsTableFilterComposer f) f,
  ) {
    final $$EndsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ends,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EndsTableFilterComposer(
            $db: $db,
            $table: $db.ends,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalXs => $composableBuilder(
    column: $table.totalXs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shaftTaggingEnabled => $composableBuilder(
    column: $table.shaftTaggingEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoundTypesTableOrderingComposer get roundTypeId {
    final $$RoundTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roundTypeId,
      referencedTable: $db.roundTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundTypesTableOrderingComposer(
            $db: $db,
            $table: $db.roundTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BowsTableOrderingComposer get bowId {
    final $$BowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bowId,
      referencedTable: $db.bows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BowsTableOrderingComposer(
            $db: $db,
            $table: $db.bows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$QuiversTableOrderingComposer get quiverId {
    final $$QuiversTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quiverId,
      referencedTable: $db.quivers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuiversTableOrderingComposer(
            $db: $db,
            $table: $db.quivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalXs =>
      $composableBuilder(column: $table.totalXs, builder: (column) => column);

  GeneratedColumn<bool> get shaftTaggingEnabled => $composableBuilder(
    column: $table.shaftTaggingEnabled,
    builder: (column) => column,
  );

  $$RoundTypesTableAnnotationComposer get roundTypeId {
    final $$RoundTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roundTypeId,
      referencedTable: $db.roundTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.roundTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BowsTableAnnotationComposer get bowId {
    final $$BowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bowId,
      referencedTable: $db.bows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BowsTableAnnotationComposer(
            $db: $db,
            $table: $db.bows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$QuiversTableAnnotationComposer get quiverId {
    final $$QuiversTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quiverId,
      referencedTable: $db.quivers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuiversTableAnnotationComposer(
            $db: $db,
            $table: $db.quivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> endsRefs<T extends Object>(
    Expression<T> Function($$EndsTableAnnotationComposer a) f,
  ) {
    final $$EndsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ends,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EndsTableAnnotationComposer(
            $db: $db,
            $table: $db.ends,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({
            bool roundTypeId,
            bool bowId,
            bool quiverId,
            bool endsRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> roundTypeId = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> totalScore = const Value.absent(),
                Value<int> totalXs = const Value.absent(),
                Value<String?> bowId = const Value.absent(),
                Value<String?> quiverId = const Value.absent(),
                Value<bool> shaftTaggingEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                roundTypeId: roundTypeId,
                sessionType: sessionType,
                location: location,
                notes: notes,
                startedAt: startedAt,
                completedAt: completedAt,
                totalScore: totalScore,
                totalXs: totalXs,
                bowId: bowId,
                quiverId: quiverId,
                shaftTaggingEnabled: shaftTaggingEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String roundTypeId,
                Value<String> sessionType = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> totalScore = const Value.absent(),
                Value<int> totalXs = const Value.absent(),
                Value<String?> bowId = const Value.absent(),
                Value<String?> quiverId = const Value.absent(),
                Value<bool> shaftTaggingEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                roundTypeId: roundTypeId,
                sessionType: sessionType,
                location: location,
                notes: notes,
                startedAt: startedAt,
                completedAt: completedAt,
                totalScore: totalScore,
                totalXs: totalXs,
                bowId: bowId,
                quiverId: quiverId,
                shaftTaggingEnabled: shaftTaggingEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                roundTypeId = false,
                bowId = false,
                quiverId = false,
                endsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (endsRefs) db.ends],
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
                        if (roundTypeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.roundTypeId,
                                    referencedTable: $$SessionsTableReferences
                                        ._roundTypeIdTable(db),
                                    referencedColumn: $$SessionsTableReferences
                                        ._roundTypeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (bowId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bowId,
                                    referencedTable: $$SessionsTableReferences
                                        ._bowIdTable(db),
                                    referencedColumn: $$SessionsTableReferences
                                        ._bowIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (quiverId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.quiverId,
                                    referencedTable: $$SessionsTableReferences
                                        ._quiverIdTable(db),
                                    referencedColumn: $$SessionsTableReferences
                                        ._quiverIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (endsRefs)
                        await $_getPrefetchedData<Session, $SessionsTable, End>(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._endsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(db, table, p0).endsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({
        bool roundTypeId,
        bool bowId,
        bool quiverId,
        bool endsRefs,
      })
    >;
typedef $$EndsTableCreateCompanionBuilder =
    EndsCompanion Function({
      required String id,
      required String sessionId,
      required int endNumber,
      Value<int> endScore,
      Value<int> endXs,
      Value<String> status,
      Value<DateTime?> committedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$EndsTableUpdateCompanionBuilder =
    EndsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> endNumber,
      Value<int> endScore,
      Value<int> endXs,
      Value<String> status,
      Value<DateTime?> committedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$EndsTableReferences
    extends BaseReferences<_$AppDatabase, $EndsTable, End> {
  $$EndsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) => db.sessions
      .createAlias($_aliasNameGenerator(db.ends.sessionId, db.sessions.id));

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ArrowsTable, List<Arrow>> _arrowsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.arrows,
    aliasName: $_aliasNameGenerator(db.ends.id, db.arrows.endId),
  );

  $$ArrowsTableProcessedTableManager get arrowsRefs {
    final manager = $$ArrowsTableTableManager(
      $_db,
      $_db.arrows,
    ).filter((f) => f.endId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_arrowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EndsTableFilterComposer extends Composer<_$AppDatabase, $EndsTable> {
  $$EndsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endNumber => $composableBuilder(
    column: $table.endNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endScore => $composableBuilder(
    column: $table.endScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endXs => $composableBuilder(
    column: $table.endXs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> arrowsRefs(
    Expression<bool> Function($$ArrowsTableFilterComposer f) f,
  ) {
    final $$ArrowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arrows,
      getReferencedColumn: (t) => t.endId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArrowsTableFilterComposer(
            $db: $db,
            $table: $db.arrows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EndsTableOrderingComposer extends Composer<_$AppDatabase, $EndsTable> {
  $$EndsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endNumber => $composableBuilder(
    column: $table.endNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endScore => $composableBuilder(
    column: $table.endScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endXs => $composableBuilder(
    column: $table.endXs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EndsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EndsTable> {
  $$EndsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get endNumber =>
      $composableBuilder(column: $table.endNumber, builder: (column) => column);

  GeneratedColumn<int> get endScore =>
      $composableBuilder(column: $table.endScore, builder: (column) => column);

  GeneratedColumn<int> get endXs =>
      $composableBuilder(column: $table.endXs, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> arrowsRefs<T extends Object>(
    Expression<T> Function($$ArrowsTableAnnotationComposer a) f,
  ) {
    final $$ArrowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arrows,
      getReferencedColumn: (t) => t.endId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArrowsTableAnnotationComposer(
            $db: $db,
            $table: $db.arrows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EndsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EndsTable,
          End,
          $$EndsTableFilterComposer,
          $$EndsTableOrderingComposer,
          $$EndsTableAnnotationComposer,
          $$EndsTableCreateCompanionBuilder,
          $$EndsTableUpdateCompanionBuilder,
          (End, $$EndsTableReferences),
          End,
          PrefetchHooks Function({bool sessionId, bool arrowsRefs})
        > {
  $$EndsTableTableManager(_$AppDatabase db, $EndsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EndsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EndsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EndsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> endNumber = const Value.absent(),
                Value<int> endScore = const Value.absent(),
                Value<int> endXs = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> committedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EndsCompanion(
                id: id,
                sessionId: sessionId,
                endNumber: endNumber,
                endScore: endScore,
                endXs: endXs,
                status: status,
                committedAt: committedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int endNumber,
                Value<int> endScore = const Value.absent(),
                Value<int> endXs = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> committedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EndsCompanion.insert(
                id: id,
                sessionId: sessionId,
                endNumber: endNumber,
                endScore: endScore,
                endXs: endXs,
                status: status,
                committedAt: committedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$EndsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, arrowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (arrowsRefs) db.arrows],
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
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$EndsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$EndsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (arrowsRefs)
                    await $_getPrefetchedData<End, $EndsTable, Arrow>(
                      currentTable: table,
                      referencedTable: $$EndsTableReferences._arrowsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$EndsTableReferences(db, table, p0).arrowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.endId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EndsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EndsTable,
      End,
      $$EndsTableFilterComposer,
      $$EndsTableOrderingComposer,
      $$EndsTableAnnotationComposer,
      $$EndsTableCreateCompanionBuilder,
      $$EndsTableUpdateCompanionBuilder,
      (End, $$EndsTableReferences),
      End,
      PrefetchHooks Function({bool sessionId, bool arrowsRefs})
    >;
typedef $$ArrowsTableCreateCompanionBuilder =
    ArrowsCompanion Function({
      required String id,
      required String endId,
      Value<int> faceIndex,
      required double x,
      required double y,
      required int score,
      Value<bool> isX,
      required int sequence,
      Value<int?> shaftNumber,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ArrowsTableUpdateCompanionBuilder =
    ArrowsCompanion Function({
      Value<String> id,
      Value<String> endId,
      Value<int> faceIndex,
      Value<double> x,
      Value<double> y,
      Value<int> score,
      Value<bool> isX,
      Value<int> sequence,
      Value<int?> shaftNumber,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ArrowsTableReferences
    extends BaseReferences<_$AppDatabase, $ArrowsTable, Arrow> {
  $$ArrowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EndsTable _endIdTable(_$AppDatabase db) =>
      db.ends.createAlias($_aliasNameGenerator(db.arrows.endId, db.ends.id));

  $$EndsTableProcessedTableManager get endId {
    final $_column = $_itemColumn<String>('end_id')!;

    final manager = $$EndsTableTableManager(
      $_db,
      $_db.ends,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_endIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ArrowsTableFilterComposer
    extends Composer<_$AppDatabase, $ArrowsTable> {
  $$ArrowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get faceIndex => $composableBuilder(
    column: $table.faceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isX => $composableBuilder(
    column: $table.isX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shaftNumber => $composableBuilder(
    column: $table.shaftNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EndsTableFilterComposer get endId {
    final $$EndsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.endId,
      referencedTable: $db.ends,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EndsTableFilterComposer(
            $db: $db,
            $table: $db.ends,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArrowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArrowsTable> {
  $$ArrowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faceIndex => $composableBuilder(
    column: $table.faceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isX => $composableBuilder(
    column: $table.isX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shaftNumber => $composableBuilder(
    column: $table.shaftNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EndsTableOrderingComposer get endId {
    final $$EndsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.endId,
      referencedTable: $db.ends,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EndsTableOrderingComposer(
            $db: $db,
            $table: $db.ends,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArrowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArrowsTable> {
  $$ArrowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get faceIndex =>
      $composableBuilder(column: $table.faceIndex, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<bool> get isX =>
      $composableBuilder(column: $table.isX, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<int> get shaftNumber => $composableBuilder(
    column: $table.shaftNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EndsTableAnnotationComposer get endId {
    final $$EndsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.endId,
      referencedTable: $db.ends,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EndsTableAnnotationComposer(
            $db: $db,
            $table: $db.ends,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArrowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArrowsTable,
          Arrow,
          $$ArrowsTableFilterComposer,
          $$ArrowsTableOrderingComposer,
          $$ArrowsTableAnnotationComposer,
          $$ArrowsTableCreateCompanionBuilder,
          $$ArrowsTableUpdateCompanionBuilder,
          (Arrow, $$ArrowsTableReferences),
          Arrow,
          PrefetchHooks Function({bool endId})
        > {
  $$ArrowsTableTableManager(_$AppDatabase db, $ArrowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArrowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArrowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArrowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> endId = const Value.absent(),
                Value<int> faceIndex = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<bool> isX = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<int?> shaftNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArrowsCompanion(
                id: id,
                endId: endId,
                faceIndex: faceIndex,
                x: x,
                y: y,
                score: score,
                isX: isX,
                sequence: sequence,
                shaftNumber: shaftNumber,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String endId,
                Value<int> faceIndex = const Value.absent(),
                required double x,
                required double y,
                required int score,
                Value<bool> isX = const Value.absent(),
                required int sequence,
                Value<int?> shaftNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArrowsCompanion.insert(
                id: id,
                endId: endId,
                faceIndex: faceIndex,
                x: x,
                y: y,
                score: score,
                isX: isX,
                sequence: sequence,
                shaftNumber: shaftNumber,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ArrowsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({endId = false}) {
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
                    if (endId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.endId,
                                referencedTable: $$ArrowsTableReferences
                                    ._endIdTable(db),
                                referencedColumn: $$ArrowsTableReferences
                                    ._endIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$ArrowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArrowsTable,
      Arrow,
      $$ArrowsTableFilterComposer,
      $$ArrowsTableOrderingComposer,
      $$ArrowsTableAnnotationComposer,
      $$ArrowsTableCreateCompanionBuilder,
      $$ArrowsTableUpdateCompanionBuilder,
      (Arrow, $$ArrowsTableReferences),
      Arrow,
      PrefetchHooks Function({bool endId})
    >;
typedef $$ImportedScoresTableCreateCompanionBuilder =
    ImportedScoresCompanion Function({
      required String id,
      required DateTime date,
      required String roundName,
      required int score,
      Value<int?> xCount,
      Value<String?> location,
      Value<String?> notes,
      Value<String> sessionType,
      Value<String> source,
      Value<DateTime> importedAt,
      Value<int> rowid,
    });
typedef $$ImportedScoresTableUpdateCompanionBuilder =
    ImportedScoresCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<String> roundName,
      Value<int> score,
      Value<int?> xCount,
      Value<String?> location,
      Value<String?> notes,
      Value<String> sessionType,
      Value<String> source,
      Value<DateTime> importedAt,
      Value<int> rowid,
    });

class $$ImportedScoresTableFilterComposer
    extends Composer<_$AppDatabase, $ImportedScoresTable> {
  $$ImportedScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roundName => $composableBuilder(
    column: $table.roundName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xCount => $composableBuilder(
    column: $table.xCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportedScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportedScoresTable> {
  $$ImportedScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roundName => $composableBuilder(
    column: $table.roundName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xCount => $composableBuilder(
    column: $table.xCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportedScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportedScoresTable> {
  $$ImportedScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get roundName =>
      $composableBuilder(column: $table.roundName, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get xCount =>
      $composableBuilder(column: $table.xCount, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );
}

class $$ImportedScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportedScoresTable,
          ImportedScore,
          $$ImportedScoresTableFilterComposer,
          $$ImportedScoresTableOrderingComposer,
          $$ImportedScoresTableAnnotationComposer,
          $$ImportedScoresTableCreateCompanionBuilder,
          $$ImportedScoresTableUpdateCompanionBuilder,
          (
            ImportedScore,
            BaseReferences<_$AppDatabase, $ImportedScoresTable, ImportedScore>,
          ),
          ImportedScore,
          PrefetchHooks Function()
        > {
  $$ImportedScoresTableTableManager(
    _$AppDatabase db,
    $ImportedScoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportedScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportedScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportedScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> roundName = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int?> xCount = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportedScoresCompanion(
                id: id,
                date: date,
                roundName: roundName,
                score: score,
                xCount: xCount,
                location: location,
                notes: notes,
                sessionType: sessionType,
                source: source,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required String roundName,
                required int score,
                Value<int?> xCount = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportedScoresCompanion.insert(
                id: id,
                date: date,
                roundName: roundName,
                score: score,
                xCount: xCount,
                location: location,
                notes: notes,
                sessionType: sessionType,
                source: source,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportedScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportedScoresTable,
      ImportedScore,
      $$ImportedScoresTableFilterComposer,
      $$ImportedScoresTableOrderingComposer,
      $$ImportedScoresTableAnnotationComposer,
      $$ImportedScoresTableCreateCompanionBuilder,
      $$ImportedScoresTableUpdateCompanionBuilder,
      (
        ImportedScore,
        BaseReferences<_$AppDatabase, $ImportedScoresTable, ImportedScore>,
      ),
      ImportedScore,
      PrefetchHooks Function()
    >;
typedef $$UserPreferencesTableCreateCompanionBuilder =
    UserPreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$UserPreferencesTableUpdateCompanionBuilder =
    UserPreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$UserPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableAnnotationComposer({
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
}

class $$UserPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPreferencesTable,
          UserPreference,
          $$UserPreferencesTableFilterComposer,
          $$UserPreferencesTableOrderingComposer,
          $$UserPreferencesTableAnnotationComposer,
          $$UserPreferencesTableCreateCompanionBuilder,
          $$UserPreferencesTableUpdateCompanionBuilder,
          (
            UserPreference,
            BaseReferences<
              _$AppDatabase,
              $UserPreferencesTable,
              UserPreference
            >,
          ),
          UserPreference,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableManager(
    _$AppDatabase db,
    $UserPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPreferencesTable,
      UserPreference,
      $$UserPreferencesTableFilterComposer,
      $$UserPreferencesTableOrderingComposer,
      $$UserPreferencesTableAnnotationComposer,
      $$UserPreferencesTableCreateCompanionBuilder,
      $$UserPreferencesTableUpdateCompanionBuilder,
      (
        UserPreference,
        BaseReferences<_$AppDatabase, $UserPreferencesTable, UserPreference>,
      ),
      UserPreference,
      PrefetchHooks Function()
    >;
typedef $$ShaftsTableCreateCompanionBuilder =
    ShaftsCompanion Function({
      required String id,
      required String quiverId,
      required int number,
      Value<String?> diameter,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime?> retiredAt,
      Value<int> rowid,
    });
typedef $$ShaftsTableUpdateCompanionBuilder =
    ShaftsCompanion Function({
      Value<String> id,
      Value<String> quiverId,
      Value<int> number,
      Value<String?> diameter,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime?> retiredAt,
      Value<int> rowid,
    });

final class $$ShaftsTableReferences
    extends BaseReferences<_$AppDatabase, $ShaftsTable, Shaft> {
  $$ShaftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuiversTable _quiverIdTable(_$AppDatabase db) => db.quivers
      .createAlias($_aliasNameGenerator(db.shafts.quiverId, db.quivers.id));

  $$QuiversTableProcessedTableManager get quiverId {
    final $_column = $_itemColumn<String>('quiver_id')!;

    final manager = $$QuiversTableTableManager(
      $_db,
      $_db.quivers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_quiverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShaftsTableFilterComposer
    extends Composer<_$AppDatabase, $ShaftsTable> {
  $$ShaftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diameter => $composableBuilder(
    column: $table.diameter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get retiredAt => $composableBuilder(
    column: $table.retiredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$QuiversTableFilterComposer get quiverId {
    final $$QuiversTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quiverId,
      referencedTable: $db.quivers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuiversTableFilterComposer(
            $db: $db,
            $table: $db.quivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShaftsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShaftsTable> {
  $$ShaftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diameter => $composableBuilder(
    column: $table.diameter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get retiredAt => $composableBuilder(
    column: $table.retiredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuiversTableOrderingComposer get quiverId {
    final $$QuiversTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quiverId,
      referencedTable: $db.quivers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuiversTableOrderingComposer(
            $db: $db,
            $table: $db.quivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShaftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShaftsTable> {
  $$ShaftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get diameter =>
      $composableBuilder(column: $table.diameter, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get retiredAt =>
      $composableBuilder(column: $table.retiredAt, builder: (column) => column);

  $$QuiversTableAnnotationComposer get quiverId {
    final $$QuiversTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quiverId,
      referencedTable: $db.quivers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuiversTableAnnotationComposer(
            $db: $db,
            $table: $db.quivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShaftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShaftsTable,
          Shaft,
          $$ShaftsTableFilterComposer,
          $$ShaftsTableOrderingComposer,
          $$ShaftsTableAnnotationComposer,
          $$ShaftsTableCreateCompanionBuilder,
          $$ShaftsTableUpdateCompanionBuilder,
          (Shaft, $$ShaftsTableReferences),
          Shaft,
          PrefetchHooks Function({bool quiverId})
        > {
  $$ShaftsTableTableManager(_$AppDatabase db, $ShaftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShaftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShaftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShaftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> quiverId = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String?> diameter = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> retiredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShaftsCompanion(
                id: id,
                quiverId: quiverId,
                number: number,
                diameter: diameter,
                notes: notes,
                createdAt: createdAt,
                retiredAt: retiredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String quiverId,
                required int number,
                Value<String?> diameter = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> retiredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShaftsCompanion.insert(
                id: id,
                quiverId: quiverId,
                number: number,
                diameter: diameter,
                notes: notes,
                createdAt: createdAt,
                retiredAt: retiredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ShaftsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({quiverId = false}) {
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
                    if (quiverId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.quiverId,
                                referencedTable: $$ShaftsTableReferences
                                    ._quiverIdTable(db),
                                referencedColumn: $$ShaftsTableReferences
                                    ._quiverIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$ShaftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShaftsTable,
      Shaft,
      $$ShaftsTableFilterComposer,
      $$ShaftsTableOrderingComposer,
      $$ShaftsTableAnnotationComposer,
      $$ShaftsTableCreateCompanionBuilder,
      $$ShaftsTableUpdateCompanionBuilder,
      (Shaft, $$ShaftsTableReferences),
      Shaft,
      PrefetchHooks Function({bool quiverId})
    >;
typedef $$VolumeEntriesTableCreateCompanionBuilder =
    VolumeEntriesCompanion Function({
      required String id,
      required DateTime date,
      required int arrowCount,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$VolumeEntriesTableUpdateCompanionBuilder =
    VolumeEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<int> arrowCount,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$VolumeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VolumeEntriesTable> {
  $$VolumeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get arrowCount => $composableBuilder(
    column: $table.arrowCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VolumeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VolumeEntriesTable> {
  $$VolumeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get arrowCount => $composableBuilder(
    column: $table.arrowCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VolumeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VolumeEntriesTable> {
  $$VolumeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get arrowCount => $composableBuilder(
    column: $table.arrowCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VolumeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VolumeEntriesTable,
          VolumeEntry,
          $$VolumeEntriesTableFilterComposer,
          $$VolumeEntriesTableOrderingComposer,
          $$VolumeEntriesTableAnnotationComposer,
          $$VolumeEntriesTableCreateCompanionBuilder,
          $$VolumeEntriesTableUpdateCompanionBuilder,
          (
            VolumeEntry,
            BaseReferences<_$AppDatabase, $VolumeEntriesTable, VolumeEntry>,
          ),
          VolumeEntry,
          PrefetchHooks Function()
        > {
  $$VolumeEntriesTableTableManager(_$AppDatabase db, $VolumeEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VolumeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VolumeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VolumeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> arrowCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VolumeEntriesCompanion(
                id: id,
                date: date,
                arrowCount: arrowCount,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required int arrowCount,
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VolumeEntriesCompanion.insert(
                id: id,
                date: date,
                arrowCount: arrowCount,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VolumeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VolumeEntriesTable,
      VolumeEntry,
      $$VolumeEntriesTableFilterComposer,
      $$VolumeEntriesTableOrderingComposer,
      $$VolumeEntriesTableAnnotationComposer,
      $$VolumeEntriesTableCreateCompanionBuilder,
      $$VolumeEntriesTableUpdateCompanionBuilder,
      (
        VolumeEntry,
        BaseReferences<_$AppDatabase, $VolumeEntriesTable, VolumeEntry>,
      ),
      VolumeEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RoundTypesTableTableManager get roundTypes =>
      $$RoundTypesTableTableManager(_db, _db.roundTypes);
  $$BowsTableTableManager get bows => $$BowsTableTableManager(_db, _db.bows);
  $$QuiversTableTableManager get quivers =>
      $$QuiversTableTableManager(_db, _db.quivers);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$EndsTableTableManager get ends => $$EndsTableTableManager(_db, _db.ends);
  $$ArrowsTableTableManager get arrows =>
      $$ArrowsTableTableManager(_db, _db.arrows);
  $$ImportedScoresTableTableManager get importedScores =>
      $$ImportedScoresTableTableManager(_db, _db.importedScores);
  $$UserPreferencesTableTableManager get userPreferences =>
      $$UserPreferencesTableTableManager(_db, _db.userPreferences);
  $$ShaftsTableTableManager get shafts =>
      $$ShaftsTableTableManager(_db, _db.shafts);
  $$VolumeEntriesTableTableManager get volumeEntries =>
      $$VolumeEntriesTableTableManager(_db, _db.volumeEntries);
}
