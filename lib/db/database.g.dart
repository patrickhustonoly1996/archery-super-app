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
  static const VerificationMeta _scoringTypeMeta = const VerificationMeta(
    'scoringType',
  );
  @override
  late final GeneratedColumn<String> scoringType = GeneratedColumn<String>(
    'scoring_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('10-zone'),
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
    scoringType,
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
    if (data.containsKey('scoring_type')) {
      context.handle(
        _scoringTypeMeta,
        scoringType.isAcceptableOrUnknown(
          data['scoring_type']!,
          _scoringTypeMeta,
        ),
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
      scoringType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_type'],
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
  final String scoringType;
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
    required this.scoringType,
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
    map['scoring_type'] = Variable<String>(scoringType);
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
      scoringType: Value(scoringType),
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
      scoringType: serializer.fromJson<String>(json['scoringType']),
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
      'scoringType': serializer.toJson<String>(scoringType),
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
    String? scoringType,
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
    scoringType: scoringType ?? this.scoringType,
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
      scoringType: data.scoringType.present
          ? data.scoringType.value
          : this.scoringType,
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
          ..write('faceCount: $faceCount, ')
          ..write('scoringType: $scoringType')
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
    scoringType,
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
          other.faceCount == this.faceCount &&
          other.scoringType == this.scoringType);
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
  final Value<String> scoringType;
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
    this.scoringType = const Value.absent(),
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
    this.scoringType = const Value.absent(),
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
    Expression<String>? scoringType,
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
      if (scoringType != null) 'scoring_type': scoringType,
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
    Value<String>? scoringType,
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
      scoringType: scoringType ?? this.scoringType,
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
    if (scoringType.present) {
      map['scoring_type'] = Variable<String>(scoringType.value);
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
          ..write('scoringType: $scoringType, ')
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
  static const VerificationMeta _xMmMeta = const VerificationMeta('xMm');
  @override
  late final GeneratedColumn<double> xMm = GeneratedColumn<double>(
    'x_mm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _yMmMeta = const VerificationMeta('yMm');
  @override
  late final GeneratedColumn<double> yMm = GeneratedColumn<double>(
    'y_mm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    xMm,
    yMm,
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
    if (data.containsKey('x_mm')) {
      context.handle(
        _xMmMeta,
        xMm.isAcceptableOrUnknown(data['x_mm']!, _xMmMeta),
      );
    }
    if (data.containsKey('y_mm')) {
      context.handle(
        _yMmMeta,
        yMm.isAcceptableOrUnknown(data['y_mm']!, _yMmMeta),
      );
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
      xMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x_mm'],
      )!,
      yMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y_mm'],
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
  final double xMm;
  final double yMm;
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
    required this.xMm,
    required this.yMm,
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
    map['x_mm'] = Variable<double>(xMm);
    map['y_mm'] = Variable<double>(yMm);
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
      xMm: Value(xMm),
      yMm: Value(yMm),
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
      xMm: serializer.fromJson<double>(json['xMm']),
      yMm: serializer.fromJson<double>(json['yMm']),
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
      'xMm': serializer.toJson<double>(xMm),
      'yMm': serializer.toJson<double>(yMm),
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
    double? xMm,
    double? yMm,
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
    xMm: xMm ?? this.xMm,
    yMm: yMm ?? this.yMm,
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
      xMm: data.xMm.present ? data.xMm.value : this.xMm,
      yMm: data.yMm.present ? data.yMm.value : this.yMm,
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
          ..write('xMm: $xMm, ')
          ..write('yMm: $yMm, ')
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
    xMm,
    yMm,
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
          other.xMm == this.xMm &&
          other.yMm == this.yMm &&
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
  final Value<double> xMm;
  final Value<double> yMm;
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
    this.xMm = const Value.absent(),
    this.yMm = const Value.absent(),
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
    this.xMm = const Value.absent(),
    this.yMm = const Value.absent(),
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
    Expression<double>? xMm,
    Expression<double>? yMm,
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
      if (xMm != null) 'x_mm': xMm,
      if (yMm != null) 'y_mm': yMm,
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
    Value<double>? xMm,
    Value<double>? yMm,
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
      xMm: xMm ?? this.xMm,
      yMm: yMm ?? this.yMm,
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
    if (xMm.present) {
      map['x_mm'] = Variable<double>(xMm.value);
    }
    if (yMm.present) {
      map['y_mm'] = Variable<double>(yMm.value);
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
          ..write('xMm: $xMm, ')
          ..write('yMm: $yMm, ')
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
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
    title,
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
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
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
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
  final String? title;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VolumeEntry({
    required this.id,
    required this.date,
    required this.arrowCount,
    this.title,
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
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
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
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
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
      title: serializer.fromJson<String?>(json['title']),
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
      'title': serializer.toJson<String?>(title),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VolumeEntry copyWith({
    String? id,
    DateTime? date,
    int? arrowCount,
    Value<String?> title = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VolumeEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    arrowCount: arrowCount ?? this.arrowCount,
    title: title.present ? title.value : this.title,
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
      title: data.title.present ? data.title.value : this.title,
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
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, arrowCount, title, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VolumeEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.arrowCount == this.arrowCount &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VolumeEntriesCompanion extends UpdateCompanion<VolumeEntry> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<int> arrowCount;
  final Value<String?> title;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VolumeEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.arrowCount = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VolumeEntriesCompanion.insert({
    required String id,
    required DateTime date,
    required int arrowCount,
    this.title = const Value.absent(),
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
    Expression<String>? title,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (arrowCount != null) 'arrow_count': arrowCount,
      if (title != null) 'title': title,
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
    Value<String?>? title,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VolumeEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      arrowCount: arrowCount ?? this.arrowCount,
      title: title ?? this.title,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
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
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OlyExerciseTypesTable extends OlyExerciseTypes
    with TableInfo<$OlyExerciseTypesTable, OlyExerciseType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OlyExerciseTypesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intensityMeta = const VerificationMeta(
    'intensity',
  );
  @override
  late final GeneratedColumn<double> intensity = GeneratedColumn<double>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
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
    requiredDuringInsert: false,
    defaultValue: const Constant('static'),
  );
  static const VerificationMeta _firstIntroducedAtMeta = const VerificationMeta(
    'firstIntroducedAt',
  );
  @override
  late final GeneratedColumn<String> firstIntroducedAt =
      GeneratedColumn<String>(
        'first_introduced_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    intensity,
    category,
    firstIntroducedAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oly_exercise_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<OlyExerciseType> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('intensity')) {
      context.handle(
        _intensityMeta,
        intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('first_introduced_at')) {
      context.handle(
        _firstIntroducedAtMeta,
        firstIntroducedAt.isAcceptableOrUnknown(
          data['first_introduced_at']!,
          _firstIntroducedAtMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OlyExerciseType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OlyExerciseType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      intensity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}intensity'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      firstIntroducedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_introduced_at'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $OlyExerciseTypesTable createAlias(String alias) {
    return $OlyExerciseTypesTable(attachedDatabase, alias);
  }
}

class OlyExerciseType extends DataClass implements Insertable<OlyExerciseType> {
  final String id;
  final String name;
  final String? description;
  final double intensity;
  final String category;
  final String? firstIntroducedAt;
  final int sortOrder;
  const OlyExerciseType({
    required this.id,
    required this.name,
    this.description,
    required this.intensity,
    required this.category,
    this.firstIntroducedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['intensity'] = Variable<double>(intensity);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || firstIntroducedAt != null) {
      map['first_introduced_at'] = Variable<String>(firstIntroducedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  OlyExerciseTypesCompanion toCompanion(bool nullToAbsent) {
    return OlyExerciseTypesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      intensity: Value(intensity),
      category: Value(category),
      firstIntroducedAt: firstIntroducedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstIntroducedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory OlyExerciseType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OlyExerciseType(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      intensity: serializer.fromJson<double>(json['intensity']),
      category: serializer.fromJson<String>(json['category']),
      firstIntroducedAt: serializer.fromJson<String?>(
        json['firstIntroducedAt'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'intensity': serializer.toJson<double>(intensity),
      'category': serializer.toJson<String>(category),
      'firstIntroducedAt': serializer.toJson<String?>(firstIntroducedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  OlyExerciseType copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    double? intensity,
    String? category,
    Value<String?> firstIntroducedAt = const Value.absent(),
    int? sortOrder,
  }) => OlyExerciseType(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    intensity: intensity ?? this.intensity,
    category: category ?? this.category,
    firstIntroducedAt: firstIntroducedAt.present
        ? firstIntroducedAt.value
        : this.firstIntroducedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  OlyExerciseType copyWithCompanion(OlyExerciseTypesCompanion data) {
    return OlyExerciseType(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      category: data.category.present ? data.category.value : this.category,
      firstIntroducedAt: data.firstIntroducedAt.present
          ? data.firstIntroducedAt.value
          : this.firstIntroducedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OlyExerciseType(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('intensity: $intensity, ')
          ..write('category: $category, ')
          ..write('firstIntroducedAt: $firstIntroducedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    intensity,
    category,
    firstIntroducedAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OlyExerciseType &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.intensity == this.intensity &&
          other.category == this.category &&
          other.firstIntroducedAt == this.firstIntroducedAt &&
          other.sortOrder == this.sortOrder);
}

class OlyExerciseTypesCompanion extends UpdateCompanion<OlyExerciseType> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> intensity;
  final Value<String> category;
  final Value<String?> firstIntroducedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const OlyExerciseTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.intensity = const Value.absent(),
    this.category = const Value.absent(),
    this.firstIntroducedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OlyExerciseTypesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.intensity = const Value.absent(),
    this.category = const Value.absent(),
    this.firstIntroducedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<OlyExerciseType> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? intensity,
    Expression<String>? category,
    Expression<String>? firstIntroducedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (intensity != null) 'intensity': intensity,
      if (category != null) 'category': category,
      if (firstIntroducedAt != null) 'first_introduced_at': firstIntroducedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OlyExerciseTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<double>? intensity,
    Value<String>? category,
    Value<String?>? firstIntroducedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return OlyExerciseTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      intensity: intensity ?? this.intensity,
      category: category ?? this.category,
      firstIntroducedAt: firstIntroducedAt ?? this.firstIntroducedAt,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<double>(intensity.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (firstIntroducedAt.present) {
      map['first_introduced_at'] = Variable<String>(firstIntroducedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OlyExerciseTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('intensity: $intensity, ')
          ..write('category: $category, ')
          ..write('firstIntroducedAt: $firstIntroducedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OlySessionTemplatesTable extends OlySessionTemplates
    with TableInfo<$OlySessionTemplatesTable, OlySessionTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OlySessionTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
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
  static const VerificationMeta _focusMeta = const VerificationMeta('focus');
  @override
  late final GeneratedColumn<String> focus = GeneratedColumn<String>(
    'focus',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeLoadMeta = const VerificationMeta(
    'volumeLoad',
  );
  @override
  late final GeneratedColumn<int> volumeLoad = GeneratedColumn<int>(
    'volume_load',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adjustedVolumeLoadMeta =
      const VerificationMeta('adjustedVolumeLoad');
  @override
  late final GeneratedColumn<int> adjustedVolumeLoad = GeneratedColumn<int>(
    'adjusted_volume_load',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workRatioMeta = const VerificationMeta(
    'workRatio',
  );
  @override
  late final GeneratedColumn<double> workRatio = GeneratedColumn<double>(
    'work_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adjustedWorkRatioMeta = const VerificationMeta(
    'adjustedWorkRatio',
  );
  @override
  late final GeneratedColumn<double> adjustedWorkRatio =
      GeneratedColumn<double>(
        'adjusted_work_ratio',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _requirementsMeta = const VerificationMeta(
    'requirements',
  );
  @override
  late final GeneratedColumn<String> requirements = GeneratedColumn<String>(
    'requirements',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Bow, elbow sling, stabilisers'),
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
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    version,
    name,
    focus,
    durationMinutes,
    volumeLoad,
    adjustedVolumeLoad,
    workRatio,
    adjustedWorkRatio,
    requirements,
    equipment,
    notes,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oly_session_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<OlySessionTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('focus')) {
      context.handle(
        _focusMeta,
        focus.isAcceptableOrUnknown(data['focus']!, _focusMeta),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('volume_load')) {
      context.handle(
        _volumeLoadMeta,
        volumeLoad.isAcceptableOrUnknown(data['volume_load']!, _volumeLoadMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeLoadMeta);
    }
    if (data.containsKey('adjusted_volume_load')) {
      context.handle(
        _adjustedVolumeLoadMeta,
        adjustedVolumeLoad.isAcceptableOrUnknown(
          data['adjusted_volume_load']!,
          _adjustedVolumeLoadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adjustedVolumeLoadMeta);
    }
    if (data.containsKey('work_ratio')) {
      context.handle(
        _workRatioMeta,
        workRatio.isAcceptableOrUnknown(data['work_ratio']!, _workRatioMeta),
      );
    } else if (isInserting) {
      context.missing(_workRatioMeta);
    }
    if (data.containsKey('adjusted_work_ratio')) {
      context.handle(
        _adjustedWorkRatioMeta,
        adjustedWorkRatio.isAcceptableOrUnknown(
          data['adjusted_work_ratio']!,
          _adjustedWorkRatioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adjustedWorkRatioMeta);
    }
    if (data.containsKey('requirements')) {
      context.handle(
        _requirementsMeta,
        requirements.isAcceptableOrUnknown(
          data['requirements']!,
          _requirementsMeta,
        ),
      );
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
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
  OlySessionTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OlySessionTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      focus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}focus'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      volumeLoad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume_load'],
      )!,
      adjustedVolumeLoad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adjusted_volume_load'],
      )!,
      workRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}work_ratio'],
      )!,
      adjustedWorkRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}adjusted_work_ratio'],
      )!,
      requirements: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requirements'],
      ),
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OlySessionTemplatesTable createAlias(String alias) {
    return $OlySessionTemplatesTable(attachedDatabase, alias);
  }
}

class OlySessionTemplate extends DataClass
    implements Insertable<OlySessionTemplate> {
  final String id;
  final String version;
  final String name;
  final String? focus;
  final int durationMinutes;
  final int volumeLoad;
  final int adjustedVolumeLoad;
  final double workRatio;
  final double adjustedWorkRatio;
  final String? requirements;
  final String equipment;
  final String? notes;
  final int sortOrder;
  final DateTime createdAt;
  const OlySessionTemplate({
    required this.id,
    required this.version,
    required this.name,
    this.focus,
    required this.durationMinutes,
    required this.volumeLoad,
    required this.adjustedVolumeLoad,
    required this.workRatio,
    required this.adjustedWorkRatio,
    this.requirements,
    required this.equipment,
    this.notes,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<String>(version);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || focus != null) {
      map['focus'] = Variable<String>(focus);
    }
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['volume_load'] = Variable<int>(volumeLoad);
    map['adjusted_volume_load'] = Variable<int>(adjustedVolumeLoad);
    map['work_ratio'] = Variable<double>(workRatio);
    map['adjusted_work_ratio'] = Variable<double>(adjustedWorkRatio);
    if (!nullToAbsent || requirements != null) {
      map['requirements'] = Variable<String>(requirements);
    }
    map['equipment'] = Variable<String>(equipment);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OlySessionTemplatesCompanion toCompanion(bool nullToAbsent) {
    return OlySessionTemplatesCompanion(
      id: Value(id),
      version: Value(version),
      name: Value(name),
      focus: focus == null && nullToAbsent
          ? const Value.absent()
          : Value(focus),
      durationMinutes: Value(durationMinutes),
      volumeLoad: Value(volumeLoad),
      adjustedVolumeLoad: Value(adjustedVolumeLoad),
      workRatio: Value(workRatio),
      adjustedWorkRatio: Value(adjustedWorkRatio),
      requirements: requirements == null && nullToAbsent
          ? const Value.absent()
          : Value(requirements),
      equipment: Value(equipment),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory OlySessionTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OlySessionTemplate(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<String>(json['version']),
      name: serializer.fromJson<String>(json['name']),
      focus: serializer.fromJson<String?>(json['focus']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      volumeLoad: serializer.fromJson<int>(json['volumeLoad']),
      adjustedVolumeLoad: serializer.fromJson<int>(json['adjustedVolumeLoad']),
      workRatio: serializer.fromJson<double>(json['workRatio']),
      adjustedWorkRatio: serializer.fromJson<double>(json['adjustedWorkRatio']),
      requirements: serializer.fromJson<String?>(json['requirements']),
      equipment: serializer.fromJson<String>(json['equipment']),
      notes: serializer.fromJson<String?>(json['notes']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<String>(version),
      'name': serializer.toJson<String>(name),
      'focus': serializer.toJson<String?>(focus),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'volumeLoad': serializer.toJson<int>(volumeLoad),
      'adjustedVolumeLoad': serializer.toJson<int>(adjustedVolumeLoad),
      'workRatio': serializer.toJson<double>(workRatio),
      'adjustedWorkRatio': serializer.toJson<double>(adjustedWorkRatio),
      'requirements': serializer.toJson<String?>(requirements),
      'equipment': serializer.toJson<String>(equipment),
      'notes': serializer.toJson<String?>(notes),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OlySessionTemplate copyWith({
    String? id,
    String? version,
    String? name,
    Value<String?> focus = const Value.absent(),
    int? durationMinutes,
    int? volumeLoad,
    int? adjustedVolumeLoad,
    double? workRatio,
    double? adjustedWorkRatio,
    Value<String?> requirements = const Value.absent(),
    String? equipment,
    Value<String?> notes = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
  }) => OlySessionTemplate(
    id: id ?? this.id,
    version: version ?? this.version,
    name: name ?? this.name,
    focus: focus.present ? focus.value : this.focus,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    volumeLoad: volumeLoad ?? this.volumeLoad,
    adjustedVolumeLoad: adjustedVolumeLoad ?? this.adjustedVolumeLoad,
    workRatio: workRatio ?? this.workRatio,
    adjustedWorkRatio: adjustedWorkRatio ?? this.adjustedWorkRatio,
    requirements: requirements.present ? requirements.value : this.requirements,
    equipment: equipment ?? this.equipment,
    notes: notes.present ? notes.value : this.notes,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  OlySessionTemplate copyWithCompanion(OlySessionTemplatesCompanion data) {
    return OlySessionTemplate(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      name: data.name.present ? data.name.value : this.name,
      focus: data.focus.present ? data.focus.value : this.focus,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      volumeLoad: data.volumeLoad.present
          ? data.volumeLoad.value
          : this.volumeLoad,
      adjustedVolumeLoad: data.adjustedVolumeLoad.present
          ? data.adjustedVolumeLoad.value
          : this.adjustedVolumeLoad,
      workRatio: data.workRatio.present ? data.workRatio.value : this.workRatio,
      adjustedWorkRatio: data.adjustedWorkRatio.present
          ? data.adjustedWorkRatio.value
          : this.adjustedWorkRatio,
      requirements: data.requirements.present
          ? data.requirements.value
          : this.requirements,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      notes: data.notes.present ? data.notes.value : this.notes,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OlySessionTemplate(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('name: $name, ')
          ..write('focus: $focus, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('volumeLoad: $volumeLoad, ')
          ..write('adjustedVolumeLoad: $adjustedVolumeLoad, ')
          ..write('workRatio: $workRatio, ')
          ..write('adjustedWorkRatio: $adjustedWorkRatio, ')
          ..write('requirements: $requirements, ')
          ..write('equipment: $equipment, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    version,
    name,
    focus,
    durationMinutes,
    volumeLoad,
    adjustedVolumeLoad,
    workRatio,
    adjustedWorkRatio,
    requirements,
    equipment,
    notes,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OlySessionTemplate &&
          other.id == this.id &&
          other.version == this.version &&
          other.name == this.name &&
          other.focus == this.focus &&
          other.durationMinutes == this.durationMinutes &&
          other.volumeLoad == this.volumeLoad &&
          other.adjustedVolumeLoad == this.adjustedVolumeLoad &&
          other.workRatio == this.workRatio &&
          other.adjustedWorkRatio == this.adjustedWorkRatio &&
          other.requirements == this.requirements &&
          other.equipment == this.equipment &&
          other.notes == this.notes &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class OlySessionTemplatesCompanion extends UpdateCompanion<OlySessionTemplate> {
  final Value<String> id;
  final Value<String> version;
  final Value<String> name;
  final Value<String?> focus;
  final Value<int> durationMinutes;
  final Value<int> volumeLoad;
  final Value<int> adjustedVolumeLoad;
  final Value<double> workRatio;
  final Value<double> adjustedWorkRatio;
  final Value<String?> requirements;
  final Value<String> equipment;
  final Value<String?> notes;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OlySessionTemplatesCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.name = const Value.absent(),
    this.focus = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.volumeLoad = const Value.absent(),
    this.adjustedVolumeLoad = const Value.absent(),
    this.workRatio = const Value.absent(),
    this.adjustedWorkRatio = const Value.absent(),
    this.requirements = const Value.absent(),
    this.equipment = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OlySessionTemplatesCompanion.insert({
    required String id,
    required String version,
    required String name,
    this.focus = const Value.absent(),
    required int durationMinutes,
    required int volumeLoad,
    required int adjustedVolumeLoad,
    required double workRatio,
    required double adjustedWorkRatio,
    this.requirements = const Value.absent(),
    this.equipment = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       name = Value(name),
       durationMinutes = Value(durationMinutes),
       volumeLoad = Value(volumeLoad),
       adjustedVolumeLoad = Value(adjustedVolumeLoad),
       workRatio = Value(workRatio),
       adjustedWorkRatio = Value(adjustedWorkRatio);
  static Insertable<OlySessionTemplate> custom({
    Expression<String>? id,
    Expression<String>? version,
    Expression<String>? name,
    Expression<String>? focus,
    Expression<int>? durationMinutes,
    Expression<int>? volumeLoad,
    Expression<int>? adjustedVolumeLoad,
    Expression<double>? workRatio,
    Expression<double>? adjustedWorkRatio,
    Expression<String>? requirements,
    Expression<String>? equipment,
    Expression<String>? notes,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (name != null) 'name': name,
      if (focus != null) 'focus': focus,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (volumeLoad != null) 'volume_load': volumeLoad,
      if (adjustedVolumeLoad != null)
        'adjusted_volume_load': adjustedVolumeLoad,
      if (workRatio != null) 'work_ratio': workRatio,
      if (adjustedWorkRatio != null) 'adjusted_work_ratio': adjustedWorkRatio,
      if (requirements != null) 'requirements': requirements,
      if (equipment != null) 'equipment': equipment,
      if (notes != null) 'notes': notes,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OlySessionTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? version,
    Value<String>? name,
    Value<String?>? focus,
    Value<int>? durationMinutes,
    Value<int>? volumeLoad,
    Value<int>? adjustedVolumeLoad,
    Value<double>? workRatio,
    Value<double>? adjustedWorkRatio,
    Value<String?>? requirements,
    Value<String>? equipment,
    Value<String?>? notes,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return OlySessionTemplatesCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      name: name ?? this.name,
      focus: focus ?? this.focus,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      volumeLoad: volumeLoad ?? this.volumeLoad,
      adjustedVolumeLoad: adjustedVolumeLoad ?? this.adjustedVolumeLoad,
      workRatio: workRatio ?? this.workRatio,
      adjustedWorkRatio: adjustedWorkRatio ?? this.adjustedWorkRatio,
      requirements: requirements ?? this.requirements,
      equipment: equipment ?? this.equipment,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (focus.present) {
      map['focus'] = Variable<String>(focus.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (volumeLoad.present) {
      map['volume_load'] = Variable<int>(volumeLoad.value);
    }
    if (adjustedVolumeLoad.present) {
      map['adjusted_volume_load'] = Variable<int>(adjustedVolumeLoad.value);
    }
    if (workRatio.present) {
      map['work_ratio'] = Variable<double>(workRatio.value);
    }
    if (adjustedWorkRatio.present) {
      map['adjusted_work_ratio'] = Variable<double>(adjustedWorkRatio.value);
    }
    if (requirements.present) {
      map['requirements'] = Variable<String>(requirements.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
    return (StringBuffer('OlySessionTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('name: $name, ')
          ..write('focus: $focus, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('volumeLoad: $volumeLoad, ')
          ..write('adjustedVolumeLoad: $adjustedVolumeLoad, ')
          ..write('workRatio: $workRatio, ')
          ..write('adjustedWorkRatio: $adjustedWorkRatio, ')
          ..write('requirements: $requirements, ')
          ..write('equipment: $equipment, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OlySessionExercisesTable extends OlySessionExercises
    with TableInfo<$OlySessionExercisesTable, OlySessionExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OlySessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionTemplateIdMeta = const VerificationMeta(
    'sessionTemplateId',
  );
  @override
  late final GeneratedColumn<String> sessionTemplateId =
      GeneratedColumn<String>(
        'session_template_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES oly_session_templates (id)',
        ),
      );
  static const VerificationMeta _exerciseTypeIdMeta = const VerificationMeta(
    'exerciseTypeId',
  );
  @override
  late final GeneratedColumn<String> exerciseTypeId = GeneratedColumn<String>(
    'exercise_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES oly_exercise_types (id)',
    ),
  );
  static const VerificationMeta _exerciseOrderMeta = const VerificationMeta(
    'exerciseOrder',
  );
  @override
  late final GeneratedColumn<int> exerciseOrder = GeneratedColumn<int>(
    'exercise_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workSecondsMeta = const VerificationMeta(
    'workSeconds',
  );
  @override
  late final GeneratedColumn<int> workSeconds = GeneratedColumn<int>(
    'work_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intensityOverrideMeta = const VerificationMeta(
    'intensityOverride',
  );
  @override
  late final GeneratedColumn<double> intensityOverride =
      GeneratedColumn<double>(
        'intensity_override',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionTemplateId,
    exerciseTypeId,
    exerciseOrder,
    reps,
    workSeconds,
    restSeconds,
    details,
    intensityOverride,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oly_session_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<OlySessionExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_template_id')) {
      context.handle(
        _sessionTemplateIdMeta,
        sessionTemplateId.isAcceptableOrUnknown(
          data['session_template_id']!,
          _sessionTemplateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionTemplateIdMeta);
    }
    if (data.containsKey('exercise_type_id')) {
      context.handle(
        _exerciseTypeIdMeta,
        exerciseTypeId.isAcceptableOrUnknown(
          data['exercise_type_id']!,
          _exerciseTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseTypeIdMeta);
    }
    if (data.containsKey('exercise_order')) {
      context.handle(
        _exerciseOrderMeta,
        exerciseOrder.isAcceptableOrUnknown(
          data['exercise_order']!,
          _exerciseOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseOrderMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('work_seconds')) {
      context.handle(
        _workSecondsMeta,
        workSeconds.isAcceptableOrUnknown(
          data['work_seconds']!,
          _workSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workSecondsMeta);
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
        _restSecondsMeta,
        restSeconds.isAcceptableOrUnknown(
          data['rest_seconds']!,
          _restSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_restSecondsMeta);
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('intensity_override')) {
      context.handle(
        _intensityOverrideMeta,
        intensityOverride.isAcceptableOrUnknown(
          data['intensity_override']!,
          _intensityOverrideMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OlySessionExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OlySessionExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_template_id'],
      )!,
      exerciseTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_type_id'],
      )!,
      exerciseOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_order'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      workSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}work_seconds'],
      )!,
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      intensityOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}intensity_override'],
      ),
    );
  }

  @override
  $OlySessionExercisesTable createAlias(String alias) {
    return $OlySessionExercisesTable(attachedDatabase, alias);
  }
}

class OlySessionExercise extends DataClass
    implements Insertable<OlySessionExercise> {
  final String id;
  final String sessionTemplateId;
  final String exerciseTypeId;
  final int exerciseOrder;
  final int reps;
  final int workSeconds;
  final int restSeconds;
  final String? details;
  final double? intensityOverride;
  const OlySessionExercise({
    required this.id,
    required this.sessionTemplateId,
    required this.exerciseTypeId,
    required this.exerciseOrder,
    required this.reps,
    required this.workSeconds,
    required this.restSeconds,
    this.details,
    this.intensityOverride,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_template_id'] = Variable<String>(sessionTemplateId);
    map['exercise_type_id'] = Variable<String>(exerciseTypeId);
    map['exercise_order'] = Variable<int>(exerciseOrder);
    map['reps'] = Variable<int>(reps);
    map['work_seconds'] = Variable<int>(workSeconds);
    map['rest_seconds'] = Variable<int>(restSeconds);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    if (!nullToAbsent || intensityOverride != null) {
      map['intensity_override'] = Variable<double>(intensityOverride);
    }
    return map;
  }

  OlySessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return OlySessionExercisesCompanion(
      id: Value(id),
      sessionTemplateId: Value(sessionTemplateId),
      exerciseTypeId: Value(exerciseTypeId),
      exerciseOrder: Value(exerciseOrder),
      reps: Value(reps),
      workSeconds: Value(workSeconds),
      restSeconds: Value(restSeconds),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      intensityOverride: intensityOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(intensityOverride),
    );
  }

  factory OlySessionExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OlySessionExercise(
      id: serializer.fromJson<String>(json['id']),
      sessionTemplateId: serializer.fromJson<String>(json['sessionTemplateId']),
      exerciseTypeId: serializer.fromJson<String>(json['exerciseTypeId']),
      exerciseOrder: serializer.fromJson<int>(json['exerciseOrder']),
      reps: serializer.fromJson<int>(json['reps']),
      workSeconds: serializer.fromJson<int>(json['workSeconds']),
      restSeconds: serializer.fromJson<int>(json['restSeconds']),
      details: serializer.fromJson<String?>(json['details']),
      intensityOverride: serializer.fromJson<double?>(
        json['intensityOverride'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionTemplateId': serializer.toJson<String>(sessionTemplateId),
      'exerciseTypeId': serializer.toJson<String>(exerciseTypeId),
      'exerciseOrder': serializer.toJson<int>(exerciseOrder),
      'reps': serializer.toJson<int>(reps),
      'workSeconds': serializer.toJson<int>(workSeconds),
      'restSeconds': serializer.toJson<int>(restSeconds),
      'details': serializer.toJson<String?>(details),
      'intensityOverride': serializer.toJson<double?>(intensityOverride),
    };
  }

  OlySessionExercise copyWith({
    String? id,
    String? sessionTemplateId,
    String? exerciseTypeId,
    int? exerciseOrder,
    int? reps,
    int? workSeconds,
    int? restSeconds,
    Value<String?> details = const Value.absent(),
    Value<double?> intensityOverride = const Value.absent(),
  }) => OlySessionExercise(
    id: id ?? this.id,
    sessionTemplateId: sessionTemplateId ?? this.sessionTemplateId,
    exerciseTypeId: exerciseTypeId ?? this.exerciseTypeId,
    exerciseOrder: exerciseOrder ?? this.exerciseOrder,
    reps: reps ?? this.reps,
    workSeconds: workSeconds ?? this.workSeconds,
    restSeconds: restSeconds ?? this.restSeconds,
    details: details.present ? details.value : this.details,
    intensityOverride: intensityOverride.present
        ? intensityOverride.value
        : this.intensityOverride,
  );
  OlySessionExercise copyWithCompanion(OlySessionExercisesCompanion data) {
    return OlySessionExercise(
      id: data.id.present ? data.id.value : this.id,
      sessionTemplateId: data.sessionTemplateId.present
          ? data.sessionTemplateId.value
          : this.sessionTemplateId,
      exerciseTypeId: data.exerciseTypeId.present
          ? data.exerciseTypeId.value
          : this.exerciseTypeId,
      exerciseOrder: data.exerciseOrder.present
          ? data.exerciseOrder.value
          : this.exerciseOrder,
      reps: data.reps.present ? data.reps.value : this.reps,
      workSeconds: data.workSeconds.present
          ? data.workSeconds.value
          : this.workSeconds,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      details: data.details.present ? data.details.value : this.details,
      intensityOverride: data.intensityOverride.present
          ? data.intensityOverride.value
          : this.intensityOverride,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OlySessionExercise(')
          ..write('id: $id, ')
          ..write('sessionTemplateId: $sessionTemplateId, ')
          ..write('exerciseTypeId: $exerciseTypeId, ')
          ..write('exerciseOrder: $exerciseOrder, ')
          ..write('reps: $reps, ')
          ..write('workSeconds: $workSeconds, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('details: $details, ')
          ..write('intensityOverride: $intensityOverride')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionTemplateId,
    exerciseTypeId,
    exerciseOrder,
    reps,
    workSeconds,
    restSeconds,
    details,
    intensityOverride,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OlySessionExercise &&
          other.id == this.id &&
          other.sessionTemplateId == this.sessionTemplateId &&
          other.exerciseTypeId == this.exerciseTypeId &&
          other.exerciseOrder == this.exerciseOrder &&
          other.reps == this.reps &&
          other.workSeconds == this.workSeconds &&
          other.restSeconds == this.restSeconds &&
          other.details == this.details &&
          other.intensityOverride == this.intensityOverride);
}

class OlySessionExercisesCompanion extends UpdateCompanion<OlySessionExercise> {
  final Value<String> id;
  final Value<String> sessionTemplateId;
  final Value<String> exerciseTypeId;
  final Value<int> exerciseOrder;
  final Value<int> reps;
  final Value<int> workSeconds;
  final Value<int> restSeconds;
  final Value<String?> details;
  final Value<double?> intensityOverride;
  final Value<int> rowid;
  const OlySessionExercisesCompanion({
    this.id = const Value.absent(),
    this.sessionTemplateId = const Value.absent(),
    this.exerciseTypeId = const Value.absent(),
    this.exerciseOrder = const Value.absent(),
    this.reps = const Value.absent(),
    this.workSeconds = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.details = const Value.absent(),
    this.intensityOverride = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OlySessionExercisesCompanion.insert({
    required String id,
    required String sessionTemplateId,
    required String exerciseTypeId,
    required int exerciseOrder,
    required int reps,
    required int workSeconds,
    required int restSeconds,
    this.details = const Value.absent(),
    this.intensityOverride = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionTemplateId = Value(sessionTemplateId),
       exerciseTypeId = Value(exerciseTypeId),
       exerciseOrder = Value(exerciseOrder),
       reps = Value(reps),
       workSeconds = Value(workSeconds),
       restSeconds = Value(restSeconds);
  static Insertable<OlySessionExercise> custom({
    Expression<String>? id,
    Expression<String>? sessionTemplateId,
    Expression<String>? exerciseTypeId,
    Expression<int>? exerciseOrder,
    Expression<int>? reps,
    Expression<int>? workSeconds,
    Expression<int>? restSeconds,
    Expression<String>? details,
    Expression<double>? intensityOverride,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionTemplateId != null) 'session_template_id': sessionTemplateId,
      if (exerciseTypeId != null) 'exercise_type_id': exerciseTypeId,
      if (exerciseOrder != null) 'exercise_order': exerciseOrder,
      if (reps != null) 'reps': reps,
      if (workSeconds != null) 'work_seconds': workSeconds,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (details != null) 'details': details,
      if (intensityOverride != null) 'intensity_override': intensityOverride,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OlySessionExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionTemplateId,
    Value<String>? exerciseTypeId,
    Value<int>? exerciseOrder,
    Value<int>? reps,
    Value<int>? workSeconds,
    Value<int>? restSeconds,
    Value<String?>? details,
    Value<double?>? intensityOverride,
    Value<int>? rowid,
  }) {
    return OlySessionExercisesCompanion(
      id: id ?? this.id,
      sessionTemplateId: sessionTemplateId ?? this.sessionTemplateId,
      exerciseTypeId: exerciseTypeId ?? this.exerciseTypeId,
      exerciseOrder: exerciseOrder ?? this.exerciseOrder,
      reps: reps ?? this.reps,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      details: details ?? this.details,
      intensityOverride: intensityOverride ?? this.intensityOverride,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionTemplateId.present) {
      map['session_template_id'] = Variable<String>(sessionTemplateId.value);
    }
    if (exerciseTypeId.present) {
      map['exercise_type_id'] = Variable<String>(exerciseTypeId.value);
    }
    if (exerciseOrder.present) {
      map['exercise_order'] = Variable<int>(exerciseOrder.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (workSeconds.present) {
      map['work_seconds'] = Variable<int>(workSeconds.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (intensityOverride.present) {
      map['intensity_override'] = Variable<double>(intensityOverride.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OlySessionExercisesCompanion(')
          ..write('id: $id, ')
          ..write('sessionTemplateId: $sessionTemplateId, ')
          ..write('exerciseTypeId: $exerciseTypeId, ')
          ..write('exerciseOrder: $exerciseOrder, ')
          ..write('reps: $reps, ')
          ..write('workSeconds: $workSeconds, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('details: $details, ')
          ..write('intensityOverride: $intensityOverride, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OlyTrainingLogsTable extends OlyTrainingLogs
    with TableInfo<$OlyTrainingLogsTable, OlyTrainingLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OlyTrainingLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionTemplateIdMeta = const VerificationMeta(
    'sessionTemplateId',
  );
  @override
  late final GeneratedColumn<String> sessionTemplateId =
      GeneratedColumn<String>(
        'session_template_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sessionVersionMeta = const VerificationMeta(
    'sessionVersion',
  );
  @override
  late final GeneratedColumn<String> sessionVersion = GeneratedColumn<String>(
    'session_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionNameMeta = const VerificationMeta(
    'sessionName',
  );
  @override
  late final GeneratedColumn<String> sessionName = GeneratedColumn<String>(
    'session_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedDurationSecondsMeta =
      const VerificationMeta('plannedDurationSeconds');
  @override
  late final GeneratedColumn<int> plannedDurationSeconds = GeneratedColumn<int>(
    'planned_duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualDurationSecondsMeta =
      const VerificationMeta('actualDurationSeconds');
  @override
  late final GeneratedColumn<int> actualDurationSeconds = GeneratedColumn<int>(
    'actual_duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedExercisesMeta = const VerificationMeta(
    'plannedExercises',
  );
  @override
  late final GeneratedColumn<int> plannedExercises = GeneratedColumn<int>(
    'planned_exercises',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedExercisesMeta =
      const VerificationMeta('completedExercises');
  @override
  late final GeneratedColumn<int> completedExercises = GeneratedColumn<int>(
    'completed_exercises',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalHoldSecondsMeta = const VerificationMeta(
    'totalHoldSeconds',
  );
  @override
  late final GeneratedColumn<int> totalHoldSeconds = GeneratedColumn<int>(
    'total_hold_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalRestSecondsMeta = const VerificationMeta(
    'totalRestSeconds',
  );
  @override
  late final GeneratedColumn<int> totalRestSeconds = GeneratedColumn<int>(
    'total_rest_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedbackShakingMeta = const VerificationMeta(
    'feedbackShaking',
  );
  @override
  late final GeneratedColumn<int> feedbackShaking = GeneratedColumn<int>(
    'feedback_shaking',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedbackStructureMeta = const VerificationMeta(
    'feedbackStructure',
  );
  @override
  late final GeneratedColumn<int> feedbackStructure = GeneratedColumn<int>(
    'feedback_structure',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedbackRestMeta = const VerificationMeta(
    'feedbackRest',
  );
  @override
  late final GeneratedColumn<int> feedbackRest = GeneratedColumn<int>(
    'feedback_rest',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressionSuggestionMeta =
      const VerificationMeta('progressionSuggestion');
  @override
  late final GeneratedColumn<String> progressionSuggestion =
      GeneratedColumn<String>(
        'progression_suggestion',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _suggestedNextVersionMeta =
      const VerificationMeta('suggestedNextVersion');
  @override
  late final GeneratedColumn<String> suggestedNextVersion =
      GeneratedColumn<String>(
        'suggested_next_version',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionTemplateId,
    sessionVersion,
    sessionName,
    plannedDurationSeconds,
    actualDurationSeconds,
    plannedExercises,
    completedExercises,
    totalHoldSeconds,
    totalRestSeconds,
    feedbackShaking,
    feedbackStructure,
    feedbackRest,
    progressionSuggestion,
    suggestedNextVersion,
    notes,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oly_training_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<OlyTrainingLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_template_id')) {
      context.handle(
        _sessionTemplateIdMeta,
        sessionTemplateId.isAcceptableOrUnknown(
          data['session_template_id']!,
          _sessionTemplateIdMeta,
        ),
      );
    }
    if (data.containsKey('session_version')) {
      context.handle(
        _sessionVersionMeta,
        sessionVersion.isAcceptableOrUnknown(
          data['session_version']!,
          _sessionVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionVersionMeta);
    }
    if (data.containsKey('session_name')) {
      context.handle(
        _sessionNameMeta,
        sessionName.isAcceptableOrUnknown(
          data['session_name']!,
          _sessionNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionNameMeta);
    }
    if (data.containsKey('planned_duration_seconds')) {
      context.handle(
        _plannedDurationSecondsMeta,
        plannedDurationSeconds.isAcceptableOrUnknown(
          data['planned_duration_seconds']!,
          _plannedDurationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedDurationSecondsMeta);
    }
    if (data.containsKey('actual_duration_seconds')) {
      context.handle(
        _actualDurationSecondsMeta,
        actualDurationSeconds.isAcceptableOrUnknown(
          data['actual_duration_seconds']!,
          _actualDurationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualDurationSecondsMeta);
    }
    if (data.containsKey('planned_exercises')) {
      context.handle(
        _plannedExercisesMeta,
        plannedExercises.isAcceptableOrUnknown(
          data['planned_exercises']!,
          _plannedExercisesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedExercisesMeta);
    }
    if (data.containsKey('completed_exercises')) {
      context.handle(
        _completedExercisesMeta,
        completedExercises.isAcceptableOrUnknown(
          data['completed_exercises']!,
          _completedExercisesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedExercisesMeta);
    }
    if (data.containsKey('total_hold_seconds')) {
      context.handle(
        _totalHoldSecondsMeta,
        totalHoldSeconds.isAcceptableOrUnknown(
          data['total_hold_seconds']!,
          _totalHoldSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalHoldSecondsMeta);
    }
    if (data.containsKey('total_rest_seconds')) {
      context.handle(
        _totalRestSecondsMeta,
        totalRestSeconds.isAcceptableOrUnknown(
          data['total_rest_seconds']!,
          _totalRestSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalRestSecondsMeta);
    }
    if (data.containsKey('feedback_shaking')) {
      context.handle(
        _feedbackShakingMeta,
        feedbackShaking.isAcceptableOrUnknown(
          data['feedback_shaking']!,
          _feedbackShakingMeta,
        ),
      );
    }
    if (data.containsKey('feedback_structure')) {
      context.handle(
        _feedbackStructureMeta,
        feedbackStructure.isAcceptableOrUnknown(
          data['feedback_structure']!,
          _feedbackStructureMeta,
        ),
      );
    }
    if (data.containsKey('feedback_rest')) {
      context.handle(
        _feedbackRestMeta,
        feedbackRest.isAcceptableOrUnknown(
          data['feedback_rest']!,
          _feedbackRestMeta,
        ),
      );
    }
    if (data.containsKey('progression_suggestion')) {
      context.handle(
        _progressionSuggestionMeta,
        progressionSuggestion.isAcceptableOrUnknown(
          data['progression_suggestion']!,
          _progressionSuggestionMeta,
        ),
      );
    }
    if (data.containsKey('suggested_next_version')) {
      context.handle(
        _suggestedNextVersionMeta,
        suggestedNextVersion.isAcceptableOrUnknown(
          data['suggested_next_version']!,
          _suggestedNextVersionMeta,
        ),
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
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OlyTrainingLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OlyTrainingLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_template_id'],
      ),
      sessionVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_version'],
      )!,
      sessionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_name'],
      )!,
      plannedDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_duration_seconds'],
      )!,
      actualDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_duration_seconds'],
      )!,
      plannedExercises: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_exercises'],
      )!,
      completedExercises: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_exercises'],
      )!,
      totalHoldSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_hold_seconds'],
      )!,
      totalRestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_rest_seconds'],
      )!,
      feedbackShaking: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feedback_shaking'],
      ),
      feedbackStructure: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feedback_structure'],
      ),
      feedbackRest: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feedback_rest'],
      ),
      progressionSuggestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}progression_suggestion'],
      ),
      suggestedNextVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggested_next_version'],
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
      )!,
    );
  }

  @override
  $OlyTrainingLogsTable createAlias(String alias) {
    return $OlyTrainingLogsTable(attachedDatabase, alias);
  }
}

class OlyTrainingLog extends DataClass implements Insertable<OlyTrainingLog> {
  final String id;
  final String? sessionTemplateId;
  final String sessionVersion;
  final String sessionName;
  final int plannedDurationSeconds;
  final int actualDurationSeconds;
  final int plannedExercises;
  final int completedExercises;
  final int totalHoldSeconds;
  final int totalRestSeconds;
  final int? feedbackShaking;
  final int? feedbackStructure;
  final int? feedbackRest;
  final String? progressionSuggestion;
  final String? suggestedNextVersion;
  final String? notes;
  final DateTime startedAt;
  final DateTime completedAt;
  const OlyTrainingLog({
    required this.id,
    this.sessionTemplateId,
    required this.sessionVersion,
    required this.sessionName,
    required this.plannedDurationSeconds,
    required this.actualDurationSeconds,
    required this.plannedExercises,
    required this.completedExercises,
    required this.totalHoldSeconds,
    required this.totalRestSeconds,
    this.feedbackShaking,
    this.feedbackStructure,
    this.feedbackRest,
    this.progressionSuggestion,
    this.suggestedNextVersion,
    this.notes,
    required this.startedAt,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sessionTemplateId != null) {
      map['session_template_id'] = Variable<String>(sessionTemplateId);
    }
    map['session_version'] = Variable<String>(sessionVersion);
    map['session_name'] = Variable<String>(sessionName);
    map['planned_duration_seconds'] = Variable<int>(plannedDurationSeconds);
    map['actual_duration_seconds'] = Variable<int>(actualDurationSeconds);
    map['planned_exercises'] = Variable<int>(plannedExercises);
    map['completed_exercises'] = Variable<int>(completedExercises);
    map['total_hold_seconds'] = Variable<int>(totalHoldSeconds);
    map['total_rest_seconds'] = Variable<int>(totalRestSeconds);
    if (!nullToAbsent || feedbackShaking != null) {
      map['feedback_shaking'] = Variable<int>(feedbackShaking);
    }
    if (!nullToAbsent || feedbackStructure != null) {
      map['feedback_structure'] = Variable<int>(feedbackStructure);
    }
    if (!nullToAbsent || feedbackRest != null) {
      map['feedback_rest'] = Variable<int>(feedbackRest);
    }
    if (!nullToAbsent || progressionSuggestion != null) {
      map['progression_suggestion'] = Variable<String>(progressionSuggestion);
    }
    if (!nullToAbsent || suggestedNextVersion != null) {
      map['suggested_next_version'] = Variable<String>(suggestedNextVersion);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  OlyTrainingLogsCompanion toCompanion(bool nullToAbsent) {
    return OlyTrainingLogsCompanion(
      id: Value(id),
      sessionTemplateId: sessionTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionTemplateId),
      sessionVersion: Value(sessionVersion),
      sessionName: Value(sessionName),
      plannedDurationSeconds: Value(plannedDurationSeconds),
      actualDurationSeconds: Value(actualDurationSeconds),
      plannedExercises: Value(plannedExercises),
      completedExercises: Value(completedExercises),
      totalHoldSeconds: Value(totalHoldSeconds),
      totalRestSeconds: Value(totalRestSeconds),
      feedbackShaking: feedbackShaking == null && nullToAbsent
          ? const Value.absent()
          : Value(feedbackShaking),
      feedbackStructure: feedbackStructure == null && nullToAbsent
          ? const Value.absent()
          : Value(feedbackStructure),
      feedbackRest: feedbackRest == null && nullToAbsent
          ? const Value.absent()
          : Value(feedbackRest),
      progressionSuggestion: progressionSuggestion == null && nullToAbsent
          ? const Value.absent()
          : Value(progressionSuggestion),
      suggestedNextVersion: suggestedNextVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestedNextVersion),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      startedAt: Value(startedAt),
      completedAt: Value(completedAt),
    );
  }

  factory OlyTrainingLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OlyTrainingLog(
      id: serializer.fromJson<String>(json['id']),
      sessionTemplateId: serializer.fromJson<String?>(
        json['sessionTemplateId'],
      ),
      sessionVersion: serializer.fromJson<String>(json['sessionVersion']),
      sessionName: serializer.fromJson<String>(json['sessionName']),
      plannedDurationSeconds: serializer.fromJson<int>(
        json['plannedDurationSeconds'],
      ),
      actualDurationSeconds: serializer.fromJson<int>(
        json['actualDurationSeconds'],
      ),
      plannedExercises: serializer.fromJson<int>(json['plannedExercises']),
      completedExercises: serializer.fromJson<int>(json['completedExercises']),
      totalHoldSeconds: serializer.fromJson<int>(json['totalHoldSeconds']),
      totalRestSeconds: serializer.fromJson<int>(json['totalRestSeconds']),
      feedbackShaking: serializer.fromJson<int?>(json['feedbackShaking']),
      feedbackStructure: serializer.fromJson<int?>(json['feedbackStructure']),
      feedbackRest: serializer.fromJson<int?>(json['feedbackRest']),
      progressionSuggestion: serializer.fromJson<String?>(
        json['progressionSuggestion'],
      ),
      suggestedNextVersion: serializer.fromJson<String?>(
        json['suggestedNextVersion'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionTemplateId': serializer.toJson<String?>(sessionTemplateId),
      'sessionVersion': serializer.toJson<String>(sessionVersion),
      'sessionName': serializer.toJson<String>(sessionName),
      'plannedDurationSeconds': serializer.toJson<int>(plannedDurationSeconds),
      'actualDurationSeconds': serializer.toJson<int>(actualDurationSeconds),
      'plannedExercises': serializer.toJson<int>(plannedExercises),
      'completedExercises': serializer.toJson<int>(completedExercises),
      'totalHoldSeconds': serializer.toJson<int>(totalHoldSeconds),
      'totalRestSeconds': serializer.toJson<int>(totalRestSeconds),
      'feedbackShaking': serializer.toJson<int?>(feedbackShaking),
      'feedbackStructure': serializer.toJson<int?>(feedbackStructure),
      'feedbackRest': serializer.toJson<int?>(feedbackRest),
      'progressionSuggestion': serializer.toJson<String?>(
        progressionSuggestion,
      ),
      'suggestedNextVersion': serializer.toJson<String?>(suggestedNextVersion),
      'notes': serializer.toJson<String?>(notes),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  OlyTrainingLog copyWith({
    String? id,
    Value<String?> sessionTemplateId = const Value.absent(),
    String? sessionVersion,
    String? sessionName,
    int? plannedDurationSeconds,
    int? actualDurationSeconds,
    int? plannedExercises,
    int? completedExercises,
    int? totalHoldSeconds,
    int? totalRestSeconds,
    Value<int?> feedbackShaking = const Value.absent(),
    Value<int?> feedbackStructure = const Value.absent(),
    Value<int?> feedbackRest = const Value.absent(),
    Value<String?> progressionSuggestion = const Value.absent(),
    Value<String?> suggestedNextVersion = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? startedAt,
    DateTime? completedAt,
  }) => OlyTrainingLog(
    id: id ?? this.id,
    sessionTemplateId: sessionTemplateId.present
        ? sessionTemplateId.value
        : this.sessionTemplateId,
    sessionVersion: sessionVersion ?? this.sessionVersion,
    sessionName: sessionName ?? this.sessionName,
    plannedDurationSeconds:
        plannedDurationSeconds ?? this.plannedDurationSeconds,
    actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
    plannedExercises: plannedExercises ?? this.plannedExercises,
    completedExercises: completedExercises ?? this.completedExercises,
    totalHoldSeconds: totalHoldSeconds ?? this.totalHoldSeconds,
    totalRestSeconds: totalRestSeconds ?? this.totalRestSeconds,
    feedbackShaking: feedbackShaking.present
        ? feedbackShaking.value
        : this.feedbackShaking,
    feedbackStructure: feedbackStructure.present
        ? feedbackStructure.value
        : this.feedbackStructure,
    feedbackRest: feedbackRest.present ? feedbackRest.value : this.feedbackRest,
    progressionSuggestion: progressionSuggestion.present
        ? progressionSuggestion.value
        : this.progressionSuggestion,
    suggestedNextVersion: suggestedNextVersion.present
        ? suggestedNextVersion.value
        : this.suggestedNextVersion,
    notes: notes.present ? notes.value : this.notes,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
  );
  OlyTrainingLog copyWithCompanion(OlyTrainingLogsCompanion data) {
    return OlyTrainingLog(
      id: data.id.present ? data.id.value : this.id,
      sessionTemplateId: data.sessionTemplateId.present
          ? data.sessionTemplateId.value
          : this.sessionTemplateId,
      sessionVersion: data.sessionVersion.present
          ? data.sessionVersion.value
          : this.sessionVersion,
      sessionName: data.sessionName.present
          ? data.sessionName.value
          : this.sessionName,
      plannedDurationSeconds: data.plannedDurationSeconds.present
          ? data.plannedDurationSeconds.value
          : this.plannedDurationSeconds,
      actualDurationSeconds: data.actualDurationSeconds.present
          ? data.actualDurationSeconds.value
          : this.actualDurationSeconds,
      plannedExercises: data.plannedExercises.present
          ? data.plannedExercises.value
          : this.plannedExercises,
      completedExercises: data.completedExercises.present
          ? data.completedExercises.value
          : this.completedExercises,
      totalHoldSeconds: data.totalHoldSeconds.present
          ? data.totalHoldSeconds.value
          : this.totalHoldSeconds,
      totalRestSeconds: data.totalRestSeconds.present
          ? data.totalRestSeconds.value
          : this.totalRestSeconds,
      feedbackShaking: data.feedbackShaking.present
          ? data.feedbackShaking.value
          : this.feedbackShaking,
      feedbackStructure: data.feedbackStructure.present
          ? data.feedbackStructure.value
          : this.feedbackStructure,
      feedbackRest: data.feedbackRest.present
          ? data.feedbackRest.value
          : this.feedbackRest,
      progressionSuggestion: data.progressionSuggestion.present
          ? data.progressionSuggestion.value
          : this.progressionSuggestion,
      suggestedNextVersion: data.suggestedNextVersion.present
          ? data.suggestedNextVersion.value
          : this.suggestedNextVersion,
      notes: data.notes.present ? data.notes.value : this.notes,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OlyTrainingLog(')
          ..write('id: $id, ')
          ..write('sessionTemplateId: $sessionTemplateId, ')
          ..write('sessionVersion: $sessionVersion, ')
          ..write('sessionName: $sessionName, ')
          ..write('plannedDurationSeconds: $plannedDurationSeconds, ')
          ..write('actualDurationSeconds: $actualDurationSeconds, ')
          ..write('plannedExercises: $plannedExercises, ')
          ..write('completedExercises: $completedExercises, ')
          ..write('totalHoldSeconds: $totalHoldSeconds, ')
          ..write('totalRestSeconds: $totalRestSeconds, ')
          ..write('feedbackShaking: $feedbackShaking, ')
          ..write('feedbackStructure: $feedbackStructure, ')
          ..write('feedbackRest: $feedbackRest, ')
          ..write('progressionSuggestion: $progressionSuggestion, ')
          ..write('suggestedNextVersion: $suggestedNextVersion, ')
          ..write('notes: $notes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionTemplateId,
    sessionVersion,
    sessionName,
    plannedDurationSeconds,
    actualDurationSeconds,
    plannedExercises,
    completedExercises,
    totalHoldSeconds,
    totalRestSeconds,
    feedbackShaking,
    feedbackStructure,
    feedbackRest,
    progressionSuggestion,
    suggestedNextVersion,
    notes,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OlyTrainingLog &&
          other.id == this.id &&
          other.sessionTemplateId == this.sessionTemplateId &&
          other.sessionVersion == this.sessionVersion &&
          other.sessionName == this.sessionName &&
          other.plannedDurationSeconds == this.plannedDurationSeconds &&
          other.actualDurationSeconds == this.actualDurationSeconds &&
          other.plannedExercises == this.plannedExercises &&
          other.completedExercises == this.completedExercises &&
          other.totalHoldSeconds == this.totalHoldSeconds &&
          other.totalRestSeconds == this.totalRestSeconds &&
          other.feedbackShaking == this.feedbackShaking &&
          other.feedbackStructure == this.feedbackStructure &&
          other.feedbackRest == this.feedbackRest &&
          other.progressionSuggestion == this.progressionSuggestion &&
          other.suggestedNextVersion == this.suggestedNextVersion &&
          other.notes == this.notes &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class OlyTrainingLogsCompanion extends UpdateCompanion<OlyTrainingLog> {
  final Value<String> id;
  final Value<String?> sessionTemplateId;
  final Value<String> sessionVersion;
  final Value<String> sessionName;
  final Value<int> plannedDurationSeconds;
  final Value<int> actualDurationSeconds;
  final Value<int> plannedExercises;
  final Value<int> completedExercises;
  final Value<int> totalHoldSeconds;
  final Value<int> totalRestSeconds;
  final Value<int?> feedbackShaking;
  final Value<int?> feedbackStructure;
  final Value<int?> feedbackRest;
  final Value<String?> progressionSuggestion;
  final Value<String?> suggestedNextVersion;
  final Value<String?> notes;
  final Value<DateTime> startedAt;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const OlyTrainingLogsCompanion({
    this.id = const Value.absent(),
    this.sessionTemplateId = const Value.absent(),
    this.sessionVersion = const Value.absent(),
    this.sessionName = const Value.absent(),
    this.plannedDurationSeconds = const Value.absent(),
    this.actualDurationSeconds = const Value.absent(),
    this.plannedExercises = const Value.absent(),
    this.completedExercises = const Value.absent(),
    this.totalHoldSeconds = const Value.absent(),
    this.totalRestSeconds = const Value.absent(),
    this.feedbackShaking = const Value.absent(),
    this.feedbackStructure = const Value.absent(),
    this.feedbackRest = const Value.absent(),
    this.progressionSuggestion = const Value.absent(),
    this.suggestedNextVersion = const Value.absent(),
    this.notes = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OlyTrainingLogsCompanion.insert({
    required String id,
    this.sessionTemplateId = const Value.absent(),
    required String sessionVersion,
    required String sessionName,
    required int plannedDurationSeconds,
    required int actualDurationSeconds,
    required int plannedExercises,
    required int completedExercises,
    required int totalHoldSeconds,
    required int totalRestSeconds,
    this.feedbackShaking = const Value.absent(),
    this.feedbackStructure = const Value.absent(),
    this.feedbackRest = const Value.absent(),
    this.progressionSuggestion = const Value.absent(),
    this.suggestedNextVersion = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime startedAt,
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionVersion = Value(sessionVersion),
       sessionName = Value(sessionName),
       plannedDurationSeconds = Value(plannedDurationSeconds),
       actualDurationSeconds = Value(actualDurationSeconds),
       plannedExercises = Value(plannedExercises),
       completedExercises = Value(completedExercises),
       totalHoldSeconds = Value(totalHoldSeconds),
       totalRestSeconds = Value(totalRestSeconds),
       startedAt = Value(startedAt),
       completedAt = Value(completedAt);
  static Insertable<OlyTrainingLog> custom({
    Expression<String>? id,
    Expression<String>? sessionTemplateId,
    Expression<String>? sessionVersion,
    Expression<String>? sessionName,
    Expression<int>? plannedDurationSeconds,
    Expression<int>? actualDurationSeconds,
    Expression<int>? plannedExercises,
    Expression<int>? completedExercises,
    Expression<int>? totalHoldSeconds,
    Expression<int>? totalRestSeconds,
    Expression<int>? feedbackShaking,
    Expression<int>? feedbackStructure,
    Expression<int>? feedbackRest,
    Expression<String>? progressionSuggestion,
    Expression<String>? suggestedNextVersion,
    Expression<String>? notes,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionTemplateId != null) 'session_template_id': sessionTemplateId,
      if (sessionVersion != null) 'session_version': sessionVersion,
      if (sessionName != null) 'session_name': sessionName,
      if (plannedDurationSeconds != null)
        'planned_duration_seconds': plannedDurationSeconds,
      if (actualDurationSeconds != null)
        'actual_duration_seconds': actualDurationSeconds,
      if (plannedExercises != null) 'planned_exercises': plannedExercises,
      if (completedExercises != null) 'completed_exercises': completedExercises,
      if (totalHoldSeconds != null) 'total_hold_seconds': totalHoldSeconds,
      if (totalRestSeconds != null) 'total_rest_seconds': totalRestSeconds,
      if (feedbackShaking != null) 'feedback_shaking': feedbackShaking,
      if (feedbackStructure != null) 'feedback_structure': feedbackStructure,
      if (feedbackRest != null) 'feedback_rest': feedbackRest,
      if (progressionSuggestion != null)
        'progression_suggestion': progressionSuggestion,
      if (suggestedNextVersion != null)
        'suggested_next_version': suggestedNextVersion,
      if (notes != null) 'notes': notes,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OlyTrainingLogsCompanion copyWith({
    Value<String>? id,
    Value<String?>? sessionTemplateId,
    Value<String>? sessionVersion,
    Value<String>? sessionName,
    Value<int>? plannedDurationSeconds,
    Value<int>? actualDurationSeconds,
    Value<int>? plannedExercises,
    Value<int>? completedExercises,
    Value<int>? totalHoldSeconds,
    Value<int>? totalRestSeconds,
    Value<int?>? feedbackShaking,
    Value<int?>? feedbackStructure,
    Value<int?>? feedbackRest,
    Value<String?>? progressionSuggestion,
    Value<String?>? suggestedNextVersion,
    Value<String?>? notes,
    Value<DateTime>? startedAt,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return OlyTrainingLogsCompanion(
      id: id ?? this.id,
      sessionTemplateId: sessionTemplateId ?? this.sessionTemplateId,
      sessionVersion: sessionVersion ?? this.sessionVersion,
      sessionName: sessionName ?? this.sessionName,
      plannedDurationSeconds:
          plannedDurationSeconds ?? this.plannedDurationSeconds,
      actualDurationSeconds:
          actualDurationSeconds ?? this.actualDurationSeconds,
      plannedExercises: plannedExercises ?? this.plannedExercises,
      completedExercises: completedExercises ?? this.completedExercises,
      totalHoldSeconds: totalHoldSeconds ?? this.totalHoldSeconds,
      totalRestSeconds: totalRestSeconds ?? this.totalRestSeconds,
      feedbackShaking: feedbackShaking ?? this.feedbackShaking,
      feedbackStructure: feedbackStructure ?? this.feedbackStructure,
      feedbackRest: feedbackRest ?? this.feedbackRest,
      progressionSuggestion:
          progressionSuggestion ?? this.progressionSuggestion,
      suggestedNextVersion: suggestedNextVersion ?? this.suggestedNextVersion,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionTemplateId.present) {
      map['session_template_id'] = Variable<String>(sessionTemplateId.value);
    }
    if (sessionVersion.present) {
      map['session_version'] = Variable<String>(sessionVersion.value);
    }
    if (sessionName.present) {
      map['session_name'] = Variable<String>(sessionName.value);
    }
    if (plannedDurationSeconds.present) {
      map['planned_duration_seconds'] = Variable<int>(
        plannedDurationSeconds.value,
      );
    }
    if (actualDurationSeconds.present) {
      map['actual_duration_seconds'] = Variable<int>(
        actualDurationSeconds.value,
      );
    }
    if (plannedExercises.present) {
      map['planned_exercises'] = Variable<int>(plannedExercises.value);
    }
    if (completedExercises.present) {
      map['completed_exercises'] = Variable<int>(completedExercises.value);
    }
    if (totalHoldSeconds.present) {
      map['total_hold_seconds'] = Variable<int>(totalHoldSeconds.value);
    }
    if (totalRestSeconds.present) {
      map['total_rest_seconds'] = Variable<int>(totalRestSeconds.value);
    }
    if (feedbackShaking.present) {
      map['feedback_shaking'] = Variable<int>(feedbackShaking.value);
    }
    if (feedbackStructure.present) {
      map['feedback_structure'] = Variable<int>(feedbackStructure.value);
    }
    if (feedbackRest.present) {
      map['feedback_rest'] = Variable<int>(feedbackRest.value);
    }
    if (progressionSuggestion.present) {
      map['progression_suggestion'] = Variable<String>(
        progressionSuggestion.value,
      );
    }
    if (suggestedNextVersion.present) {
      map['suggested_next_version'] = Variable<String>(
        suggestedNextVersion.value,
      );
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OlyTrainingLogsCompanion(')
          ..write('id: $id, ')
          ..write('sessionTemplateId: $sessionTemplateId, ')
          ..write('sessionVersion: $sessionVersion, ')
          ..write('sessionName: $sessionName, ')
          ..write('plannedDurationSeconds: $plannedDurationSeconds, ')
          ..write('actualDurationSeconds: $actualDurationSeconds, ')
          ..write('plannedExercises: $plannedExercises, ')
          ..write('completedExercises: $completedExercises, ')
          ..write('totalHoldSeconds: $totalHoldSeconds, ')
          ..write('totalRestSeconds: $totalRestSeconds, ')
          ..write('feedbackShaking: $feedbackShaking, ')
          ..write('feedbackStructure: $feedbackStructure, ')
          ..write('feedbackRest: $feedbackRest, ')
          ..write('progressionSuggestion: $progressionSuggestion, ')
          ..write('suggestedNextVersion: $suggestedNextVersion, ')
          ..write('notes: $notes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserTrainingProgressTable extends UserTrainingProgress
    with TableInfo<$UserTrainingProgressTable, UserTrainingProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTrainingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentLevelMeta = const VerificationMeta(
    'currentLevel',
  );
  @override
  late final GeneratedColumn<String> currentLevel = GeneratedColumn<String>(
    'current_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1.0'),
  );
  static const VerificationMeta _sessionsAtCurrentLevelMeta =
      const VerificationMeta('sessionsAtCurrentLevel');
  @override
  late final GeneratedColumn<int> sessionsAtCurrentLevel = GeneratedColumn<int>(
    'sessions_at_current_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSessionAtMeta = const VerificationMeta(
    'lastSessionAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSessionAt =
      GeneratedColumn<DateTime>(
        'last_session_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSessionVersionMeta =
      const VerificationMeta('lastSessionVersion');
  @override
  late final GeneratedColumn<String> lastSessionVersion =
      GeneratedColumn<String>(
        'last_session_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _totalSessionsCompletedMeta =
      const VerificationMeta('totalSessionsCompleted');
  @override
  late final GeneratedColumn<int> totalSessionsCompleted = GeneratedColumn<int>(
    'total_sessions_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hasCompletedAssessmentMeta =
      const VerificationMeta('hasCompletedAssessment');
  @override
  late final GeneratedColumn<bool> hasCompletedAssessment =
      GeneratedColumn<bool>(
        'has_completed_assessment',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_completed_assessment" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _assessmentMaxHoldSecondsMeta =
      const VerificationMeta('assessmentMaxHoldSeconds');
  @override
  late final GeneratedColumn<int> assessmentMaxHoldSeconds =
      GeneratedColumn<int>(
        'assessment_max_hold_seconds',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _assessmentDateMeta = const VerificationMeta(
    'assessmentDate',
  );
  @override
  late final GeneratedColumn<DateTime> assessmentDate =
      GeneratedColumn<DateTime>(
        'assessment_date',
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
    currentLevel,
    sessionsAtCurrentLevel,
    lastSessionAt,
    lastSessionVersion,
    totalSessionsCompleted,
    hasCompletedAssessment,
    assessmentMaxHoldSeconds,
    assessmentDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_training_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserTrainingProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('current_level')) {
      context.handle(
        _currentLevelMeta,
        currentLevel.isAcceptableOrUnknown(
          data['current_level']!,
          _currentLevelMeta,
        ),
      );
    }
    if (data.containsKey('sessions_at_current_level')) {
      context.handle(
        _sessionsAtCurrentLevelMeta,
        sessionsAtCurrentLevel.isAcceptableOrUnknown(
          data['sessions_at_current_level']!,
          _sessionsAtCurrentLevelMeta,
        ),
      );
    }
    if (data.containsKey('last_session_at')) {
      context.handle(
        _lastSessionAtMeta,
        lastSessionAt.isAcceptableOrUnknown(
          data['last_session_at']!,
          _lastSessionAtMeta,
        ),
      );
    }
    if (data.containsKey('last_session_version')) {
      context.handle(
        _lastSessionVersionMeta,
        lastSessionVersion.isAcceptableOrUnknown(
          data['last_session_version']!,
          _lastSessionVersionMeta,
        ),
      );
    }
    if (data.containsKey('total_sessions_completed')) {
      context.handle(
        _totalSessionsCompletedMeta,
        totalSessionsCompleted.isAcceptableOrUnknown(
          data['total_sessions_completed']!,
          _totalSessionsCompletedMeta,
        ),
      );
    }
    if (data.containsKey('has_completed_assessment')) {
      context.handle(
        _hasCompletedAssessmentMeta,
        hasCompletedAssessment.isAcceptableOrUnknown(
          data['has_completed_assessment']!,
          _hasCompletedAssessmentMeta,
        ),
      );
    }
    if (data.containsKey('assessment_max_hold_seconds')) {
      context.handle(
        _assessmentMaxHoldSecondsMeta,
        assessmentMaxHoldSeconds.isAcceptableOrUnknown(
          data['assessment_max_hold_seconds']!,
          _assessmentMaxHoldSecondsMeta,
        ),
      );
    }
    if (data.containsKey('assessment_date')) {
      context.handle(
        _assessmentDateMeta,
        assessmentDate.isAcceptableOrUnknown(
          data['assessment_date']!,
          _assessmentDateMeta,
        ),
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
  UserTrainingProgressData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserTrainingProgressData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      currentLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_level'],
      )!,
      sessionsAtCurrentLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sessions_at_current_level'],
      )!,
      lastSessionAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_session_at'],
      ),
      lastSessionVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_session_version'],
      ),
      totalSessionsCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_sessions_completed'],
      )!,
      hasCompletedAssessment: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_completed_assessment'],
      )!,
      assessmentMaxHoldSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assessment_max_hold_seconds'],
      ),
      assessmentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}assessment_date'],
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
  $UserTrainingProgressTable createAlias(String alias) {
    return $UserTrainingProgressTable(attachedDatabase, alias);
  }
}

class UserTrainingProgressData extends DataClass
    implements Insertable<UserTrainingProgressData> {
  final String id;
  final String currentLevel;
  final int sessionsAtCurrentLevel;
  final DateTime? lastSessionAt;
  final String? lastSessionVersion;
  final int totalSessionsCompleted;
  final bool hasCompletedAssessment;
  final int? assessmentMaxHoldSeconds;
  final DateTime? assessmentDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserTrainingProgressData({
    required this.id,
    required this.currentLevel,
    required this.sessionsAtCurrentLevel,
    this.lastSessionAt,
    this.lastSessionVersion,
    required this.totalSessionsCompleted,
    required this.hasCompletedAssessment,
    this.assessmentMaxHoldSeconds,
    this.assessmentDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['current_level'] = Variable<String>(currentLevel);
    map['sessions_at_current_level'] = Variable<int>(sessionsAtCurrentLevel);
    if (!nullToAbsent || lastSessionAt != null) {
      map['last_session_at'] = Variable<DateTime>(lastSessionAt);
    }
    if (!nullToAbsent || lastSessionVersion != null) {
      map['last_session_version'] = Variable<String>(lastSessionVersion);
    }
    map['total_sessions_completed'] = Variable<int>(totalSessionsCompleted);
    map['has_completed_assessment'] = Variable<bool>(hasCompletedAssessment);
    if (!nullToAbsent || assessmentMaxHoldSeconds != null) {
      map['assessment_max_hold_seconds'] = Variable<int>(
        assessmentMaxHoldSeconds,
      );
    }
    if (!nullToAbsent || assessmentDate != null) {
      map['assessment_date'] = Variable<DateTime>(assessmentDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserTrainingProgressCompanion toCompanion(bool nullToAbsent) {
    return UserTrainingProgressCompanion(
      id: Value(id),
      currentLevel: Value(currentLevel),
      sessionsAtCurrentLevel: Value(sessionsAtCurrentLevel),
      lastSessionAt: lastSessionAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSessionAt),
      lastSessionVersion: lastSessionVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSessionVersion),
      totalSessionsCompleted: Value(totalSessionsCompleted),
      hasCompletedAssessment: Value(hasCompletedAssessment),
      assessmentMaxHoldSeconds: assessmentMaxHoldSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(assessmentMaxHoldSeconds),
      assessmentDate: assessmentDate == null && nullToAbsent
          ? const Value.absent()
          : Value(assessmentDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserTrainingProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserTrainingProgressData(
      id: serializer.fromJson<String>(json['id']),
      currentLevel: serializer.fromJson<String>(json['currentLevel']),
      sessionsAtCurrentLevel: serializer.fromJson<int>(
        json['sessionsAtCurrentLevel'],
      ),
      lastSessionAt: serializer.fromJson<DateTime?>(json['lastSessionAt']),
      lastSessionVersion: serializer.fromJson<String?>(
        json['lastSessionVersion'],
      ),
      totalSessionsCompleted: serializer.fromJson<int>(
        json['totalSessionsCompleted'],
      ),
      hasCompletedAssessment: serializer.fromJson<bool>(
        json['hasCompletedAssessment'],
      ),
      assessmentMaxHoldSeconds: serializer.fromJson<int?>(
        json['assessmentMaxHoldSeconds'],
      ),
      assessmentDate: serializer.fromJson<DateTime?>(json['assessmentDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'currentLevel': serializer.toJson<String>(currentLevel),
      'sessionsAtCurrentLevel': serializer.toJson<int>(sessionsAtCurrentLevel),
      'lastSessionAt': serializer.toJson<DateTime?>(lastSessionAt),
      'lastSessionVersion': serializer.toJson<String?>(lastSessionVersion),
      'totalSessionsCompleted': serializer.toJson<int>(totalSessionsCompleted),
      'hasCompletedAssessment': serializer.toJson<bool>(hasCompletedAssessment),
      'assessmentMaxHoldSeconds': serializer.toJson<int?>(
        assessmentMaxHoldSeconds,
      ),
      'assessmentDate': serializer.toJson<DateTime?>(assessmentDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserTrainingProgressData copyWith({
    String? id,
    String? currentLevel,
    int? sessionsAtCurrentLevel,
    Value<DateTime?> lastSessionAt = const Value.absent(),
    Value<String?> lastSessionVersion = const Value.absent(),
    int? totalSessionsCompleted,
    bool? hasCompletedAssessment,
    Value<int?> assessmentMaxHoldSeconds = const Value.absent(),
    Value<DateTime?> assessmentDate = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserTrainingProgressData(
    id: id ?? this.id,
    currentLevel: currentLevel ?? this.currentLevel,
    sessionsAtCurrentLevel:
        sessionsAtCurrentLevel ?? this.sessionsAtCurrentLevel,
    lastSessionAt: lastSessionAt.present
        ? lastSessionAt.value
        : this.lastSessionAt,
    lastSessionVersion: lastSessionVersion.present
        ? lastSessionVersion.value
        : this.lastSessionVersion,
    totalSessionsCompleted:
        totalSessionsCompleted ?? this.totalSessionsCompleted,
    hasCompletedAssessment:
        hasCompletedAssessment ?? this.hasCompletedAssessment,
    assessmentMaxHoldSeconds: assessmentMaxHoldSeconds.present
        ? assessmentMaxHoldSeconds.value
        : this.assessmentMaxHoldSeconds,
    assessmentDate: assessmentDate.present
        ? assessmentDate.value
        : this.assessmentDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserTrainingProgressData copyWithCompanion(
    UserTrainingProgressCompanion data,
  ) {
    return UserTrainingProgressData(
      id: data.id.present ? data.id.value : this.id,
      currentLevel: data.currentLevel.present
          ? data.currentLevel.value
          : this.currentLevel,
      sessionsAtCurrentLevel: data.sessionsAtCurrentLevel.present
          ? data.sessionsAtCurrentLevel.value
          : this.sessionsAtCurrentLevel,
      lastSessionAt: data.lastSessionAt.present
          ? data.lastSessionAt.value
          : this.lastSessionAt,
      lastSessionVersion: data.lastSessionVersion.present
          ? data.lastSessionVersion.value
          : this.lastSessionVersion,
      totalSessionsCompleted: data.totalSessionsCompleted.present
          ? data.totalSessionsCompleted.value
          : this.totalSessionsCompleted,
      hasCompletedAssessment: data.hasCompletedAssessment.present
          ? data.hasCompletedAssessment.value
          : this.hasCompletedAssessment,
      assessmentMaxHoldSeconds: data.assessmentMaxHoldSeconds.present
          ? data.assessmentMaxHoldSeconds.value
          : this.assessmentMaxHoldSeconds,
      assessmentDate: data.assessmentDate.present
          ? data.assessmentDate.value
          : this.assessmentDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserTrainingProgressData(')
          ..write('id: $id, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('sessionsAtCurrentLevel: $sessionsAtCurrentLevel, ')
          ..write('lastSessionAt: $lastSessionAt, ')
          ..write('lastSessionVersion: $lastSessionVersion, ')
          ..write('totalSessionsCompleted: $totalSessionsCompleted, ')
          ..write('hasCompletedAssessment: $hasCompletedAssessment, ')
          ..write('assessmentMaxHoldSeconds: $assessmentMaxHoldSeconds, ')
          ..write('assessmentDate: $assessmentDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    currentLevel,
    sessionsAtCurrentLevel,
    lastSessionAt,
    lastSessionVersion,
    totalSessionsCompleted,
    hasCompletedAssessment,
    assessmentMaxHoldSeconds,
    assessmentDate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserTrainingProgressData &&
          other.id == this.id &&
          other.currentLevel == this.currentLevel &&
          other.sessionsAtCurrentLevel == this.sessionsAtCurrentLevel &&
          other.lastSessionAt == this.lastSessionAt &&
          other.lastSessionVersion == this.lastSessionVersion &&
          other.totalSessionsCompleted == this.totalSessionsCompleted &&
          other.hasCompletedAssessment == this.hasCompletedAssessment &&
          other.assessmentMaxHoldSeconds == this.assessmentMaxHoldSeconds &&
          other.assessmentDate == this.assessmentDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserTrainingProgressCompanion
    extends UpdateCompanion<UserTrainingProgressData> {
  final Value<String> id;
  final Value<String> currentLevel;
  final Value<int> sessionsAtCurrentLevel;
  final Value<DateTime?> lastSessionAt;
  final Value<String?> lastSessionVersion;
  final Value<int> totalSessionsCompleted;
  final Value<bool> hasCompletedAssessment;
  final Value<int?> assessmentMaxHoldSeconds;
  final Value<DateTime?> assessmentDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserTrainingProgressCompanion({
    this.id = const Value.absent(),
    this.currentLevel = const Value.absent(),
    this.sessionsAtCurrentLevel = const Value.absent(),
    this.lastSessionAt = const Value.absent(),
    this.lastSessionVersion = const Value.absent(),
    this.totalSessionsCompleted = const Value.absent(),
    this.hasCompletedAssessment = const Value.absent(),
    this.assessmentMaxHoldSeconds = const Value.absent(),
    this.assessmentDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserTrainingProgressCompanion.insert({
    required String id,
    this.currentLevel = const Value.absent(),
    this.sessionsAtCurrentLevel = const Value.absent(),
    this.lastSessionAt = const Value.absent(),
    this.lastSessionVersion = const Value.absent(),
    this.totalSessionsCompleted = const Value.absent(),
    this.hasCompletedAssessment = const Value.absent(),
    this.assessmentMaxHoldSeconds = const Value.absent(),
    this.assessmentDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<UserTrainingProgressData> custom({
    Expression<String>? id,
    Expression<String>? currentLevel,
    Expression<int>? sessionsAtCurrentLevel,
    Expression<DateTime>? lastSessionAt,
    Expression<String>? lastSessionVersion,
    Expression<int>? totalSessionsCompleted,
    Expression<bool>? hasCompletedAssessment,
    Expression<int>? assessmentMaxHoldSeconds,
    Expression<DateTime>? assessmentDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentLevel != null) 'current_level': currentLevel,
      if (sessionsAtCurrentLevel != null)
        'sessions_at_current_level': sessionsAtCurrentLevel,
      if (lastSessionAt != null) 'last_session_at': lastSessionAt,
      if (lastSessionVersion != null)
        'last_session_version': lastSessionVersion,
      if (totalSessionsCompleted != null)
        'total_sessions_completed': totalSessionsCompleted,
      if (hasCompletedAssessment != null)
        'has_completed_assessment': hasCompletedAssessment,
      if (assessmentMaxHoldSeconds != null)
        'assessment_max_hold_seconds': assessmentMaxHoldSeconds,
      if (assessmentDate != null) 'assessment_date': assessmentDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserTrainingProgressCompanion copyWith({
    Value<String>? id,
    Value<String>? currentLevel,
    Value<int>? sessionsAtCurrentLevel,
    Value<DateTime?>? lastSessionAt,
    Value<String?>? lastSessionVersion,
    Value<int>? totalSessionsCompleted,
    Value<bool>? hasCompletedAssessment,
    Value<int?>? assessmentMaxHoldSeconds,
    Value<DateTime?>? assessmentDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserTrainingProgressCompanion(
      id: id ?? this.id,
      currentLevel: currentLevel ?? this.currentLevel,
      sessionsAtCurrentLevel:
          sessionsAtCurrentLevel ?? this.sessionsAtCurrentLevel,
      lastSessionAt: lastSessionAt ?? this.lastSessionAt,
      lastSessionVersion: lastSessionVersion ?? this.lastSessionVersion,
      totalSessionsCompleted:
          totalSessionsCompleted ?? this.totalSessionsCompleted,
      hasCompletedAssessment:
          hasCompletedAssessment ?? this.hasCompletedAssessment,
      assessmentMaxHoldSeconds:
          assessmentMaxHoldSeconds ?? this.assessmentMaxHoldSeconds,
      assessmentDate: assessmentDate ?? this.assessmentDate,
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
    if (currentLevel.present) {
      map['current_level'] = Variable<String>(currentLevel.value);
    }
    if (sessionsAtCurrentLevel.present) {
      map['sessions_at_current_level'] = Variable<int>(
        sessionsAtCurrentLevel.value,
      );
    }
    if (lastSessionAt.present) {
      map['last_session_at'] = Variable<DateTime>(lastSessionAt.value);
    }
    if (lastSessionVersion.present) {
      map['last_session_version'] = Variable<String>(lastSessionVersion.value);
    }
    if (totalSessionsCompleted.present) {
      map['total_sessions_completed'] = Variable<int>(
        totalSessionsCompleted.value,
      );
    }
    if (hasCompletedAssessment.present) {
      map['has_completed_assessment'] = Variable<bool>(
        hasCompletedAssessment.value,
      );
    }
    if (assessmentMaxHoldSeconds.present) {
      map['assessment_max_hold_seconds'] = Variable<int>(
        assessmentMaxHoldSeconds.value,
      );
    }
    if (assessmentDate.present) {
      map['assessment_date'] = Variable<DateTime>(assessmentDate.value);
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
    return (StringBuffer('UserTrainingProgressCompanion(')
          ..write('id: $id, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('sessionsAtCurrentLevel: $sessionsAtCurrentLevel, ')
          ..write('lastSessionAt: $lastSessionAt, ')
          ..write('lastSessionVersion: $lastSessionVersion, ')
          ..write('totalSessionsCompleted: $totalSessionsCompleted, ')
          ..write('hasCompletedAssessment: $hasCompletedAssessment, ')
          ..write('assessmentMaxHoldSeconds: $assessmentMaxHoldSeconds, ')
          ..write('assessmentDate: $assessmentDate, ')
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
  late final $OlyExerciseTypesTable olyExerciseTypes = $OlyExerciseTypesTable(
    this,
  );
  late final $OlySessionTemplatesTable olySessionTemplates =
      $OlySessionTemplatesTable(this);
  late final $OlySessionExercisesTable olySessionExercises =
      $OlySessionExercisesTable(this);
  late final $OlyTrainingLogsTable olyTrainingLogs = $OlyTrainingLogsTable(
    this,
  );
  late final $UserTrainingProgressTable userTrainingProgress =
      $UserTrainingProgressTable(this);
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
    olyExerciseTypes,
    olySessionTemplates,
    olySessionExercises,
    olyTrainingLogs,
    userTrainingProgress,
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
      Value<String> scoringType,
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
      Value<String> scoringType,
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

  ColumnFilters<String> get scoringType => $composableBuilder(
    column: $table.scoringType,
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

  ColumnOrderings<String> get scoringType => $composableBuilder(
    column: $table.scoringType,
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

  GeneratedColumn<String> get scoringType => $composableBuilder(
    column: $table.scoringType,
    builder: (column) => column,
  );

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
                Value<String> scoringType = const Value.absent(),
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
                scoringType: scoringType,
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
                Value<String> scoringType = const Value.absent(),
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
                scoringType: scoringType,
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
      Value<double> xMm,
      Value<double> yMm,
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
      Value<double> xMm,
      Value<double> yMm,
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

  ColumnFilters<double> get xMm => $composableBuilder(
    column: $table.xMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get yMm => $composableBuilder(
    column: $table.yMm,
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

  ColumnOrderings<double> get xMm => $composableBuilder(
    column: $table.xMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get yMm => $composableBuilder(
    column: $table.yMm,
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

  GeneratedColumn<double> get xMm =>
      $composableBuilder(column: $table.xMm, builder: (column) => column);

  GeneratedColumn<double> get yMm =>
      $composableBuilder(column: $table.yMm, builder: (column) => column);

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
                Value<double> xMm = const Value.absent(),
                Value<double> yMm = const Value.absent(),
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
                xMm: xMm,
                yMm: yMm,
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
                Value<double> xMm = const Value.absent(),
                Value<double> yMm = const Value.absent(),
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
                xMm: xMm,
                yMm: yMm,
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
      Value<String?> title,
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
      Value<String?> title,
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
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

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

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
                Value<String?> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VolumeEntriesCompanion(
                id: id,
                date: date,
                arrowCount: arrowCount,
                title: title,
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
                Value<String?> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VolumeEntriesCompanion.insert(
                id: id,
                date: date,
                arrowCount: arrowCount,
                title: title,
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
typedef $$OlyExerciseTypesTableCreateCompanionBuilder =
    OlyExerciseTypesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<double> intensity,
      Value<String> category,
      Value<String?> firstIntroducedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$OlyExerciseTypesTableUpdateCompanionBuilder =
    OlyExerciseTypesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<double> intensity,
      Value<String> category,
      Value<String?> firstIntroducedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$OlyExerciseTypesTableReferences
    extends
        BaseReferences<_$AppDatabase, $OlyExerciseTypesTable, OlyExerciseType> {
  $$OlyExerciseTypesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $OlySessionExercisesTable,
    List<OlySessionExercise>
  >
  _olySessionExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.olySessionExercises,
        aliasName: $_aliasNameGenerator(
          db.olyExerciseTypes.id,
          db.olySessionExercises.exerciseTypeId,
        ),
      );

  $$OlySessionExercisesTableProcessedTableManager get olySessionExercisesRefs {
    final manager = $$OlySessionExercisesTableTableManager(
      $_db,
      $_db.olySessionExercises,
    ).filter((f) => f.exerciseTypeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _olySessionExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OlyExerciseTypesTableFilterComposer
    extends Composer<_$AppDatabase, $OlyExerciseTypesTable> {
  $$OlyExerciseTypesTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstIntroducedAt => $composableBuilder(
    column: $table.firstIntroducedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> olySessionExercisesRefs(
    Expression<bool> Function($$OlySessionExercisesTableFilterComposer f) f,
  ) {
    final $$OlySessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.olySessionExercises,
      getReferencedColumn: (t) => t.exerciseTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OlySessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.olySessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OlyExerciseTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $OlyExerciseTypesTable> {
  $$OlyExerciseTypesTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstIntroducedAt => $composableBuilder(
    column: $table.firstIntroducedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OlyExerciseTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OlyExerciseTypesTable> {
  $$OlyExerciseTypesTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get firstIntroducedAt => $composableBuilder(
    column: $table.firstIntroducedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> olySessionExercisesRefs<T extends Object>(
    Expression<T> Function($$OlySessionExercisesTableAnnotationComposer a) f,
  ) {
    final $$OlySessionExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.olySessionExercises,
          getReferencedColumn: (t) => t.exerciseTypeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OlySessionExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.olySessionExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$OlyExerciseTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OlyExerciseTypesTable,
          OlyExerciseType,
          $$OlyExerciseTypesTableFilterComposer,
          $$OlyExerciseTypesTableOrderingComposer,
          $$OlyExerciseTypesTableAnnotationComposer,
          $$OlyExerciseTypesTableCreateCompanionBuilder,
          $$OlyExerciseTypesTableUpdateCompanionBuilder,
          (OlyExerciseType, $$OlyExerciseTypesTableReferences),
          OlyExerciseType,
          PrefetchHooks Function({bool olySessionExercisesRefs})
        > {
  $$OlyExerciseTypesTableTableManager(
    _$AppDatabase db,
    $OlyExerciseTypesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OlyExerciseTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OlyExerciseTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OlyExerciseTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> intensity = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> firstIntroducedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OlyExerciseTypesCompanion(
                id: id,
                name: name,
                description: description,
                intensity: intensity,
                category: category,
                firstIntroducedAt: firstIntroducedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<double> intensity = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> firstIntroducedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OlyExerciseTypesCompanion.insert(
                id: id,
                name: name,
                description: description,
                intensity: intensity,
                category: category,
                firstIntroducedAt: firstIntroducedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OlyExerciseTypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({olySessionExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (olySessionExercisesRefs) db.olySessionExercises,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (olySessionExercisesRefs)
                    await $_getPrefetchedData<
                      OlyExerciseType,
                      $OlyExerciseTypesTable,
                      OlySessionExercise
                    >(
                      currentTable: table,
                      referencedTable: $$OlyExerciseTypesTableReferences
                          ._olySessionExercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$OlyExerciseTypesTableReferences(
                            db,
                            table,
                            p0,
                          ).olySessionExercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.exerciseTypeId == item.id,
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

typedef $$OlyExerciseTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OlyExerciseTypesTable,
      OlyExerciseType,
      $$OlyExerciseTypesTableFilterComposer,
      $$OlyExerciseTypesTableOrderingComposer,
      $$OlyExerciseTypesTableAnnotationComposer,
      $$OlyExerciseTypesTableCreateCompanionBuilder,
      $$OlyExerciseTypesTableUpdateCompanionBuilder,
      (OlyExerciseType, $$OlyExerciseTypesTableReferences),
      OlyExerciseType,
      PrefetchHooks Function({bool olySessionExercisesRefs})
    >;
typedef $$OlySessionTemplatesTableCreateCompanionBuilder =
    OlySessionTemplatesCompanion Function({
      required String id,
      required String version,
      required String name,
      Value<String?> focus,
      required int durationMinutes,
      required int volumeLoad,
      required int adjustedVolumeLoad,
      required double workRatio,
      required double adjustedWorkRatio,
      Value<String?> requirements,
      Value<String> equipment,
      Value<String?> notes,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$OlySessionTemplatesTableUpdateCompanionBuilder =
    OlySessionTemplatesCompanion Function({
      Value<String> id,
      Value<String> version,
      Value<String> name,
      Value<String?> focus,
      Value<int> durationMinutes,
      Value<int> volumeLoad,
      Value<int> adjustedVolumeLoad,
      Value<double> workRatio,
      Value<double> adjustedWorkRatio,
      Value<String?> requirements,
      Value<String> equipment,
      Value<String?> notes,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$OlySessionTemplatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OlySessionTemplatesTable,
          OlySessionTemplate
        > {
  $$OlySessionTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $OlySessionExercisesTable,
    List<OlySessionExercise>
  >
  _olySessionExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.olySessionExercises,
        aliasName: $_aliasNameGenerator(
          db.olySessionTemplates.id,
          db.olySessionExercises.sessionTemplateId,
        ),
      );

  $$OlySessionExercisesTableProcessedTableManager get olySessionExercisesRefs {
    final manager =
        $$OlySessionExercisesTableTableManager(
          $_db,
          $_db.olySessionExercises,
        ).filter(
          (f) => f.sessionTemplateId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _olySessionExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OlySessionTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $OlySessionTemplatesTable> {
  $$OlySessionTemplatesTableFilterComposer({
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

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get focus => $composableBuilder(
    column: $table.focus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volumeLoad => $composableBuilder(
    column: $table.volumeLoad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adjustedVolumeLoad => $composableBuilder(
    column: $table.adjustedVolumeLoad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get workRatio => $composableBuilder(
    column: $table.workRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get adjustedWorkRatio => $composableBuilder(
    column: $table.adjustedWorkRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requirements => $composableBuilder(
    column: $table.requirements,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> olySessionExercisesRefs(
    Expression<bool> Function($$OlySessionExercisesTableFilterComposer f) f,
  ) {
    final $$OlySessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.olySessionExercises,
      getReferencedColumn: (t) => t.sessionTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OlySessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.olySessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OlySessionTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $OlySessionTemplatesTable> {
  $$OlySessionTemplatesTableOrderingComposer({
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

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get focus => $composableBuilder(
    column: $table.focus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volumeLoad => $composableBuilder(
    column: $table.volumeLoad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adjustedVolumeLoad => $composableBuilder(
    column: $table.adjustedVolumeLoad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get workRatio => $composableBuilder(
    column: $table.workRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get adjustedWorkRatio => $composableBuilder(
    column: $table.adjustedWorkRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requirements => $composableBuilder(
    column: $table.requirements,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OlySessionTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OlySessionTemplatesTable> {
  $$OlySessionTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get focus =>
      $composableBuilder(column: $table.focus, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get volumeLoad => $composableBuilder(
    column: $table.volumeLoad,
    builder: (column) => column,
  );

  GeneratedColumn<int> get adjustedVolumeLoad => $composableBuilder(
    column: $table.adjustedVolumeLoad,
    builder: (column) => column,
  );

  GeneratedColumn<double> get workRatio =>
      $composableBuilder(column: $table.workRatio, builder: (column) => column);

  GeneratedColumn<double> get adjustedWorkRatio => $composableBuilder(
    column: $table.adjustedWorkRatio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requirements => $composableBuilder(
    column: $table.requirements,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> olySessionExercisesRefs<T extends Object>(
    Expression<T> Function($$OlySessionExercisesTableAnnotationComposer a) f,
  ) {
    final $$OlySessionExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.olySessionExercises,
          getReferencedColumn: (t) => t.sessionTemplateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OlySessionExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.olySessionExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$OlySessionTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OlySessionTemplatesTable,
          OlySessionTemplate,
          $$OlySessionTemplatesTableFilterComposer,
          $$OlySessionTemplatesTableOrderingComposer,
          $$OlySessionTemplatesTableAnnotationComposer,
          $$OlySessionTemplatesTableCreateCompanionBuilder,
          $$OlySessionTemplatesTableUpdateCompanionBuilder,
          (OlySessionTemplate, $$OlySessionTemplatesTableReferences),
          OlySessionTemplate,
          PrefetchHooks Function({bool olySessionExercisesRefs})
        > {
  $$OlySessionTemplatesTableTableManager(
    _$AppDatabase db,
    $OlySessionTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OlySessionTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OlySessionTemplatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OlySessionTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> focus = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> volumeLoad = const Value.absent(),
                Value<int> adjustedVolumeLoad = const Value.absent(),
                Value<double> workRatio = const Value.absent(),
                Value<double> adjustedWorkRatio = const Value.absent(),
                Value<String?> requirements = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OlySessionTemplatesCompanion(
                id: id,
                version: version,
                name: name,
                focus: focus,
                durationMinutes: durationMinutes,
                volumeLoad: volumeLoad,
                adjustedVolumeLoad: adjustedVolumeLoad,
                workRatio: workRatio,
                adjustedWorkRatio: adjustedWorkRatio,
                requirements: requirements,
                equipment: equipment,
                notes: notes,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String version,
                required String name,
                Value<String?> focus = const Value.absent(),
                required int durationMinutes,
                required int volumeLoad,
                required int adjustedVolumeLoad,
                required double workRatio,
                required double adjustedWorkRatio,
                Value<String?> requirements = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OlySessionTemplatesCompanion.insert(
                id: id,
                version: version,
                name: name,
                focus: focus,
                durationMinutes: durationMinutes,
                volumeLoad: volumeLoad,
                adjustedVolumeLoad: adjustedVolumeLoad,
                workRatio: workRatio,
                adjustedWorkRatio: adjustedWorkRatio,
                requirements: requirements,
                equipment: equipment,
                notes: notes,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OlySessionTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({olySessionExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (olySessionExercisesRefs) db.olySessionExercises,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (olySessionExercisesRefs)
                    await $_getPrefetchedData<
                      OlySessionTemplate,
                      $OlySessionTemplatesTable,
                      OlySessionExercise
                    >(
                      currentTable: table,
                      referencedTable: $$OlySessionTemplatesTableReferences
                          ._olySessionExercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$OlySessionTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).olySessionExercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.sessionTemplateId == item.id,
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

typedef $$OlySessionTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OlySessionTemplatesTable,
      OlySessionTemplate,
      $$OlySessionTemplatesTableFilterComposer,
      $$OlySessionTemplatesTableOrderingComposer,
      $$OlySessionTemplatesTableAnnotationComposer,
      $$OlySessionTemplatesTableCreateCompanionBuilder,
      $$OlySessionTemplatesTableUpdateCompanionBuilder,
      (OlySessionTemplate, $$OlySessionTemplatesTableReferences),
      OlySessionTemplate,
      PrefetchHooks Function({bool olySessionExercisesRefs})
    >;
typedef $$OlySessionExercisesTableCreateCompanionBuilder =
    OlySessionExercisesCompanion Function({
      required String id,
      required String sessionTemplateId,
      required String exerciseTypeId,
      required int exerciseOrder,
      required int reps,
      required int workSeconds,
      required int restSeconds,
      Value<String?> details,
      Value<double?> intensityOverride,
      Value<int> rowid,
    });
typedef $$OlySessionExercisesTableUpdateCompanionBuilder =
    OlySessionExercisesCompanion Function({
      Value<String> id,
      Value<String> sessionTemplateId,
      Value<String> exerciseTypeId,
      Value<int> exerciseOrder,
      Value<int> reps,
      Value<int> workSeconds,
      Value<int> restSeconds,
      Value<String?> details,
      Value<double?> intensityOverride,
      Value<int> rowid,
    });

final class $$OlySessionExercisesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OlySessionExercisesTable,
          OlySessionExercise
        > {
  $$OlySessionExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OlySessionTemplatesTable _sessionTemplateIdTable(_$AppDatabase db) =>
      db.olySessionTemplates.createAlias(
        $_aliasNameGenerator(
          db.olySessionExercises.sessionTemplateId,
          db.olySessionTemplates.id,
        ),
      );

  $$OlySessionTemplatesTableProcessedTableManager get sessionTemplateId {
    final $_column = $_itemColumn<String>('session_template_id')!;

    final manager = $$OlySessionTemplatesTableTableManager(
      $_db,
      $_db.olySessionTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionTemplateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $OlyExerciseTypesTable _exerciseTypeIdTable(_$AppDatabase db) =>
      db.olyExerciseTypes.createAlias(
        $_aliasNameGenerator(
          db.olySessionExercises.exerciseTypeId,
          db.olyExerciseTypes.id,
        ),
      );

  $$OlyExerciseTypesTableProcessedTableManager get exerciseTypeId {
    final $_column = $_itemColumn<String>('exercise_type_id')!;

    final manager = $$OlyExerciseTypesTableTableManager(
      $_db,
      $_db.olyExerciseTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OlySessionExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $OlySessionExercisesTable> {
  $$OlySessionExercisesTableFilterComposer({
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

  ColumnFilters<int> get exerciseOrder => $composableBuilder(
    column: $table.exerciseOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workSeconds => $composableBuilder(
    column: $table.workSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intensityOverride => $composableBuilder(
    column: $table.intensityOverride,
    builder: (column) => ColumnFilters(column),
  );

  $$OlySessionTemplatesTableFilterComposer get sessionTemplateId {
    final $$OlySessionTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionTemplateId,
      referencedTable: $db.olySessionTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OlySessionTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.olySessionTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OlyExerciseTypesTableFilterComposer get exerciseTypeId {
    final $$OlyExerciseTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseTypeId,
      referencedTable: $db.olyExerciseTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OlyExerciseTypesTableFilterComposer(
            $db: $db,
            $table: $db.olyExerciseTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OlySessionExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $OlySessionExercisesTable> {
  $$OlySessionExercisesTableOrderingComposer({
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

  ColumnOrderings<int> get exerciseOrder => $composableBuilder(
    column: $table.exerciseOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workSeconds => $composableBuilder(
    column: $table.workSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intensityOverride => $composableBuilder(
    column: $table.intensityOverride,
    builder: (column) => ColumnOrderings(column),
  );

  $$OlySessionTemplatesTableOrderingComposer get sessionTemplateId {
    final $$OlySessionTemplatesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionTemplateId,
          referencedTable: $db.olySessionTemplates,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OlySessionTemplatesTableOrderingComposer(
                $db: $db,
                $table: $db.olySessionTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$OlyExerciseTypesTableOrderingComposer get exerciseTypeId {
    final $$OlyExerciseTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseTypeId,
      referencedTable: $db.olyExerciseTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OlyExerciseTypesTableOrderingComposer(
            $db: $db,
            $table: $db.olyExerciseTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OlySessionExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OlySessionExercisesTable> {
  $$OlySessionExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get exerciseOrder => $composableBuilder(
    column: $table.exerciseOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get workSeconds => $composableBuilder(
    column: $table.workSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<double> get intensityOverride => $composableBuilder(
    column: $table.intensityOverride,
    builder: (column) => column,
  );

  $$OlySessionTemplatesTableAnnotationComposer get sessionTemplateId {
    final $$OlySessionTemplatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionTemplateId,
          referencedTable: $db.olySessionTemplates,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OlySessionTemplatesTableAnnotationComposer(
                $db: $db,
                $table: $db.olySessionTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$OlyExerciseTypesTableAnnotationComposer get exerciseTypeId {
    final $$OlyExerciseTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseTypeId,
      referencedTable: $db.olyExerciseTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OlyExerciseTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.olyExerciseTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OlySessionExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OlySessionExercisesTable,
          OlySessionExercise,
          $$OlySessionExercisesTableFilterComposer,
          $$OlySessionExercisesTableOrderingComposer,
          $$OlySessionExercisesTableAnnotationComposer,
          $$OlySessionExercisesTableCreateCompanionBuilder,
          $$OlySessionExercisesTableUpdateCompanionBuilder,
          (OlySessionExercise, $$OlySessionExercisesTableReferences),
          OlySessionExercise,
          PrefetchHooks Function({bool sessionTemplateId, bool exerciseTypeId})
        > {
  $$OlySessionExercisesTableTableManager(
    _$AppDatabase db,
    $OlySessionExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OlySessionExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OlySessionExercisesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OlySessionExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionTemplateId = const Value.absent(),
                Value<String> exerciseTypeId = const Value.absent(),
                Value<int> exerciseOrder = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> workSeconds = const Value.absent(),
                Value<int> restSeconds = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<double?> intensityOverride = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OlySessionExercisesCompanion(
                id: id,
                sessionTemplateId: sessionTemplateId,
                exerciseTypeId: exerciseTypeId,
                exerciseOrder: exerciseOrder,
                reps: reps,
                workSeconds: workSeconds,
                restSeconds: restSeconds,
                details: details,
                intensityOverride: intensityOverride,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionTemplateId,
                required String exerciseTypeId,
                required int exerciseOrder,
                required int reps,
                required int workSeconds,
                required int restSeconds,
                Value<String?> details = const Value.absent(),
                Value<double?> intensityOverride = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OlySessionExercisesCompanion.insert(
                id: id,
                sessionTemplateId: sessionTemplateId,
                exerciseTypeId: exerciseTypeId,
                exerciseOrder: exerciseOrder,
                reps: reps,
                workSeconds: workSeconds,
                restSeconds: restSeconds,
                details: details,
                intensityOverride: intensityOverride,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OlySessionExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionTemplateId = false, exerciseTypeId = false}) {
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
                        if (sessionTemplateId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionTemplateId,
                                    referencedTable:
                                        $$OlySessionExercisesTableReferences
                                            ._sessionTemplateIdTable(db),
                                    referencedColumn:
                                        $$OlySessionExercisesTableReferences
                                            ._sessionTemplateIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (exerciseTypeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exerciseTypeId,
                                    referencedTable:
                                        $$OlySessionExercisesTableReferences
                                            ._exerciseTypeIdTable(db),
                                    referencedColumn:
                                        $$OlySessionExercisesTableReferences
                                            ._exerciseTypeIdTable(db)
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

typedef $$OlySessionExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OlySessionExercisesTable,
      OlySessionExercise,
      $$OlySessionExercisesTableFilterComposer,
      $$OlySessionExercisesTableOrderingComposer,
      $$OlySessionExercisesTableAnnotationComposer,
      $$OlySessionExercisesTableCreateCompanionBuilder,
      $$OlySessionExercisesTableUpdateCompanionBuilder,
      (OlySessionExercise, $$OlySessionExercisesTableReferences),
      OlySessionExercise,
      PrefetchHooks Function({bool sessionTemplateId, bool exerciseTypeId})
    >;
typedef $$OlyTrainingLogsTableCreateCompanionBuilder =
    OlyTrainingLogsCompanion Function({
      required String id,
      Value<String?> sessionTemplateId,
      required String sessionVersion,
      required String sessionName,
      required int plannedDurationSeconds,
      required int actualDurationSeconds,
      required int plannedExercises,
      required int completedExercises,
      required int totalHoldSeconds,
      required int totalRestSeconds,
      Value<int?> feedbackShaking,
      Value<int?> feedbackStructure,
      Value<int?> feedbackRest,
      Value<String?> progressionSuggestion,
      Value<String?> suggestedNextVersion,
      Value<String?> notes,
      required DateTime startedAt,
      required DateTime completedAt,
      Value<int> rowid,
    });
typedef $$OlyTrainingLogsTableUpdateCompanionBuilder =
    OlyTrainingLogsCompanion Function({
      Value<String> id,
      Value<String?> sessionTemplateId,
      Value<String> sessionVersion,
      Value<String> sessionName,
      Value<int> plannedDurationSeconds,
      Value<int> actualDurationSeconds,
      Value<int> plannedExercises,
      Value<int> completedExercises,
      Value<int> totalHoldSeconds,
      Value<int> totalRestSeconds,
      Value<int?> feedbackShaking,
      Value<int?> feedbackStructure,
      Value<int?> feedbackRest,
      Value<String?> progressionSuggestion,
      Value<String?> suggestedNextVersion,
      Value<String?> notes,
      Value<DateTime> startedAt,
      Value<DateTime> completedAt,
      Value<int> rowid,
    });

class $$OlyTrainingLogsTableFilterComposer
    extends Composer<_$AppDatabase, $OlyTrainingLogsTable> {
  $$OlyTrainingLogsTableFilterComposer({
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

  ColumnFilters<String> get sessionTemplateId => $composableBuilder(
    column: $table.sessionTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionVersion => $composableBuilder(
    column: $table.sessionVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionName => $composableBuilder(
    column: $table.sessionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedDurationSeconds => $composableBuilder(
    column: $table.plannedDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualDurationSeconds => $composableBuilder(
    column: $table.actualDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedExercises => $composableBuilder(
    column: $table.plannedExercises,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedExercises => $composableBuilder(
    column: $table.completedExercises,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalHoldSeconds => $composableBuilder(
    column: $table.totalHoldSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalRestSeconds => $composableBuilder(
    column: $table.totalRestSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedbackShaking => $composableBuilder(
    column: $table.feedbackShaking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedbackStructure => $composableBuilder(
    column: $table.feedbackStructure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedbackRest => $composableBuilder(
    column: $table.feedbackRest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get progressionSuggestion => $composableBuilder(
    column: $table.progressionSuggestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggestedNextVersion => $composableBuilder(
    column: $table.suggestedNextVersion,
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
}

class $$OlyTrainingLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $OlyTrainingLogsTable> {
  $$OlyTrainingLogsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionTemplateId => $composableBuilder(
    column: $table.sessionTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionVersion => $composableBuilder(
    column: $table.sessionVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionName => $composableBuilder(
    column: $table.sessionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedDurationSeconds => $composableBuilder(
    column: $table.plannedDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualDurationSeconds => $composableBuilder(
    column: $table.actualDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedExercises => $composableBuilder(
    column: $table.plannedExercises,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedExercises => $composableBuilder(
    column: $table.completedExercises,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalHoldSeconds => $composableBuilder(
    column: $table.totalHoldSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalRestSeconds => $composableBuilder(
    column: $table.totalRestSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedbackShaking => $composableBuilder(
    column: $table.feedbackShaking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedbackStructure => $composableBuilder(
    column: $table.feedbackStructure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedbackRest => $composableBuilder(
    column: $table.feedbackRest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get progressionSuggestion => $composableBuilder(
    column: $table.progressionSuggestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestedNextVersion => $composableBuilder(
    column: $table.suggestedNextVersion,
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
}

class $$OlyTrainingLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OlyTrainingLogsTable> {
  $$OlyTrainingLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionTemplateId => $composableBuilder(
    column: $table.sessionTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionVersion => $composableBuilder(
    column: $table.sessionVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionName => $composableBuilder(
    column: $table.sessionName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedDurationSeconds => $composableBuilder(
    column: $table.plannedDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualDurationSeconds => $composableBuilder(
    column: $table.actualDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedExercises => $composableBuilder(
    column: $table.plannedExercises,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedExercises => $composableBuilder(
    column: $table.completedExercises,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalHoldSeconds => $composableBuilder(
    column: $table.totalHoldSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalRestSeconds => $composableBuilder(
    column: $table.totalRestSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get feedbackShaking => $composableBuilder(
    column: $table.feedbackShaking,
    builder: (column) => column,
  );

  GeneratedColumn<int> get feedbackStructure => $composableBuilder(
    column: $table.feedbackStructure,
    builder: (column) => column,
  );

  GeneratedColumn<int> get feedbackRest => $composableBuilder(
    column: $table.feedbackRest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get progressionSuggestion => $composableBuilder(
    column: $table.progressionSuggestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suggestedNextVersion => $composableBuilder(
    column: $table.suggestedNextVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$OlyTrainingLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OlyTrainingLogsTable,
          OlyTrainingLog,
          $$OlyTrainingLogsTableFilterComposer,
          $$OlyTrainingLogsTableOrderingComposer,
          $$OlyTrainingLogsTableAnnotationComposer,
          $$OlyTrainingLogsTableCreateCompanionBuilder,
          $$OlyTrainingLogsTableUpdateCompanionBuilder,
          (
            OlyTrainingLog,
            BaseReferences<
              _$AppDatabase,
              $OlyTrainingLogsTable,
              OlyTrainingLog
            >,
          ),
          OlyTrainingLog,
          PrefetchHooks Function()
        > {
  $$OlyTrainingLogsTableTableManager(
    _$AppDatabase db,
    $OlyTrainingLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OlyTrainingLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OlyTrainingLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OlyTrainingLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> sessionTemplateId = const Value.absent(),
                Value<String> sessionVersion = const Value.absent(),
                Value<String> sessionName = const Value.absent(),
                Value<int> plannedDurationSeconds = const Value.absent(),
                Value<int> actualDurationSeconds = const Value.absent(),
                Value<int> plannedExercises = const Value.absent(),
                Value<int> completedExercises = const Value.absent(),
                Value<int> totalHoldSeconds = const Value.absent(),
                Value<int> totalRestSeconds = const Value.absent(),
                Value<int?> feedbackShaking = const Value.absent(),
                Value<int?> feedbackStructure = const Value.absent(),
                Value<int?> feedbackRest = const Value.absent(),
                Value<String?> progressionSuggestion = const Value.absent(),
                Value<String?> suggestedNextVersion = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OlyTrainingLogsCompanion(
                id: id,
                sessionTemplateId: sessionTemplateId,
                sessionVersion: sessionVersion,
                sessionName: sessionName,
                plannedDurationSeconds: plannedDurationSeconds,
                actualDurationSeconds: actualDurationSeconds,
                plannedExercises: plannedExercises,
                completedExercises: completedExercises,
                totalHoldSeconds: totalHoldSeconds,
                totalRestSeconds: totalRestSeconds,
                feedbackShaking: feedbackShaking,
                feedbackStructure: feedbackStructure,
                feedbackRest: feedbackRest,
                progressionSuggestion: progressionSuggestion,
                suggestedNextVersion: suggestedNextVersion,
                notes: notes,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> sessionTemplateId = const Value.absent(),
                required String sessionVersion,
                required String sessionName,
                required int plannedDurationSeconds,
                required int actualDurationSeconds,
                required int plannedExercises,
                required int completedExercises,
                required int totalHoldSeconds,
                required int totalRestSeconds,
                Value<int?> feedbackShaking = const Value.absent(),
                Value<int?> feedbackStructure = const Value.absent(),
                Value<int?> feedbackRest = const Value.absent(),
                Value<String?> progressionSuggestion = const Value.absent(),
                Value<String?> suggestedNextVersion = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime startedAt,
                required DateTime completedAt,
                Value<int> rowid = const Value.absent(),
              }) => OlyTrainingLogsCompanion.insert(
                id: id,
                sessionTemplateId: sessionTemplateId,
                sessionVersion: sessionVersion,
                sessionName: sessionName,
                plannedDurationSeconds: plannedDurationSeconds,
                actualDurationSeconds: actualDurationSeconds,
                plannedExercises: plannedExercises,
                completedExercises: completedExercises,
                totalHoldSeconds: totalHoldSeconds,
                totalRestSeconds: totalRestSeconds,
                feedbackShaking: feedbackShaking,
                feedbackStructure: feedbackStructure,
                feedbackRest: feedbackRest,
                progressionSuggestion: progressionSuggestion,
                suggestedNextVersion: suggestedNextVersion,
                notes: notes,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OlyTrainingLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OlyTrainingLogsTable,
      OlyTrainingLog,
      $$OlyTrainingLogsTableFilterComposer,
      $$OlyTrainingLogsTableOrderingComposer,
      $$OlyTrainingLogsTableAnnotationComposer,
      $$OlyTrainingLogsTableCreateCompanionBuilder,
      $$OlyTrainingLogsTableUpdateCompanionBuilder,
      (
        OlyTrainingLog,
        BaseReferences<_$AppDatabase, $OlyTrainingLogsTable, OlyTrainingLog>,
      ),
      OlyTrainingLog,
      PrefetchHooks Function()
    >;
typedef $$UserTrainingProgressTableCreateCompanionBuilder =
    UserTrainingProgressCompanion Function({
      required String id,
      Value<String> currentLevel,
      Value<int> sessionsAtCurrentLevel,
      Value<DateTime?> lastSessionAt,
      Value<String?> lastSessionVersion,
      Value<int> totalSessionsCompleted,
      Value<bool> hasCompletedAssessment,
      Value<int?> assessmentMaxHoldSeconds,
      Value<DateTime?> assessmentDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserTrainingProgressTableUpdateCompanionBuilder =
    UserTrainingProgressCompanion Function({
      Value<String> id,
      Value<String> currentLevel,
      Value<int> sessionsAtCurrentLevel,
      Value<DateTime?> lastSessionAt,
      Value<String?> lastSessionVersion,
      Value<int> totalSessionsCompleted,
      Value<bool> hasCompletedAssessment,
      Value<int?> assessmentMaxHoldSeconds,
      Value<DateTime?> assessmentDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserTrainingProgressTableFilterComposer
    extends Composer<_$AppDatabase, $UserTrainingProgressTable> {
  $$UserTrainingProgressTableFilterComposer({
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

  ColumnFilters<String> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionsAtCurrentLevel => $composableBuilder(
    column: $table.sessionsAtCurrentLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSessionAt => $composableBuilder(
    column: $table.lastSessionAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSessionVersion => $composableBuilder(
    column: $table.lastSessionVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSessionsCompleted => $composableBuilder(
    column: $table.totalSessionsCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasCompletedAssessment => $composableBuilder(
    column: $table.hasCompletedAssessment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assessmentMaxHoldSeconds => $composableBuilder(
    column: $table.assessmentMaxHoldSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get assessmentDate => $composableBuilder(
    column: $table.assessmentDate,
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

class $$UserTrainingProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $UserTrainingProgressTable> {
  $$UserTrainingProgressTableOrderingComposer({
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

  ColumnOrderings<String> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionsAtCurrentLevel => $composableBuilder(
    column: $table.sessionsAtCurrentLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSessionAt => $composableBuilder(
    column: $table.lastSessionAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSessionVersion => $composableBuilder(
    column: $table.lastSessionVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSessionsCompleted => $composableBuilder(
    column: $table.totalSessionsCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasCompletedAssessment => $composableBuilder(
    column: $table.hasCompletedAssessment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assessmentMaxHoldSeconds => $composableBuilder(
    column: $table.assessmentMaxHoldSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get assessmentDate => $composableBuilder(
    column: $table.assessmentDate,
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

class $$UserTrainingProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserTrainingProgressTable> {
  $$UserTrainingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sessionsAtCurrentLevel => $composableBuilder(
    column: $table.sessionsAtCurrentLevel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSessionAt => $composableBuilder(
    column: $table.lastSessionAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSessionVersion => $composableBuilder(
    column: $table.lastSessionVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSessionsCompleted => $composableBuilder(
    column: $table.totalSessionsCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasCompletedAssessment => $composableBuilder(
    column: $table.hasCompletedAssessment,
    builder: (column) => column,
  );

  GeneratedColumn<int> get assessmentMaxHoldSeconds => $composableBuilder(
    column: $table.assessmentMaxHoldSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get assessmentDate => $composableBuilder(
    column: $table.assessmentDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserTrainingProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserTrainingProgressTable,
          UserTrainingProgressData,
          $$UserTrainingProgressTableFilterComposer,
          $$UserTrainingProgressTableOrderingComposer,
          $$UserTrainingProgressTableAnnotationComposer,
          $$UserTrainingProgressTableCreateCompanionBuilder,
          $$UserTrainingProgressTableUpdateCompanionBuilder,
          (
            UserTrainingProgressData,
            BaseReferences<
              _$AppDatabase,
              $UserTrainingProgressTable,
              UserTrainingProgressData
            >,
          ),
          UserTrainingProgressData,
          PrefetchHooks Function()
        > {
  $$UserTrainingProgressTableTableManager(
    _$AppDatabase db,
    $UserTrainingProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserTrainingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserTrainingProgressTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserTrainingProgressTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> currentLevel = const Value.absent(),
                Value<int> sessionsAtCurrentLevel = const Value.absent(),
                Value<DateTime?> lastSessionAt = const Value.absent(),
                Value<String?> lastSessionVersion = const Value.absent(),
                Value<int> totalSessionsCompleted = const Value.absent(),
                Value<bool> hasCompletedAssessment = const Value.absent(),
                Value<int?> assessmentMaxHoldSeconds = const Value.absent(),
                Value<DateTime?> assessmentDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserTrainingProgressCompanion(
                id: id,
                currentLevel: currentLevel,
                sessionsAtCurrentLevel: sessionsAtCurrentLevel,
                lastSessionAt: lastSessionAt,
                lastSessionVersion: lastSessionVersion,
                totalSessionsCompleted: totalSessionsCompleted,
                hasCompletedAssessment: hasCompletedAssessment,
                assessmentMaxHoldSeconds: assessmentMaxHoldSeconds,
                assessmentDate: assessmentDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> currentLevel = const Value.absent(),
                Value<int> sessionsAtCurrentLevel = const Value.absent(),
                Value<DateTime?> lastSessionAt = const Value.absent(),
                Value<String?> lastSessionVersion = const Value.absent(),
                Value<int> totalSessionsCompleted = const Value.absent(),
                Value<bool> hasCompletedAssessment = const Value.absent(),
                Value<int?> assessmentMaxHoldSeconds = const Value.absent(),
                Value<DateTime?> assessmentDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserTrainingProgressCompanion.insert(
                id: id,
                currentLevel: currentLevel,
                sessionsAtCurrentLevel: sessionsAtCurrentLevel,
                lastSessionAt: lastSessionAt,
                lastSessionVersion: lastSessionVersion,
                totalSessionsCompleted: totalSessionsCompleted,
                hasCompletedAssessment: hasCompletedAssessment,
                assessmentMaxHoldSeconds: assessmentMaxHoldSeconds,
                assessmentDate: assessmentDate,
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

typedef $$UserTrainingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserTrainingProgressTable,
      UserTrainingProgressData,
      $$UserTrainingProgressTableFilterComposer,
      $$UserTrainingProgressTableOrderingComposer,
      $$UserTrainingProgressTableAnnotationComposer,
      $$UserTrainingProgressTableCreateCompanionBuilder,
      $$UserTrainingProgressTableUpdateCompanionBuilder,
      (
        UserTrainingProgressData,
        BaseReferences<
          _$AppDatabase,
          $UserTrainingProgressTable,
          UserTrainingProgressData
        >,
      ),
      UserTrainingProgressData,
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
  $$OlyExerciseTypesTableTableManager get olyExerciseTypes =>
      $$OlyExerciseTypesTableTableManager(_db, _db.olyExerciseTypes);
  $$OlySessionTemplatesTableTableManager get olySessionTemplates =>
      $$OlySessionTemplatesTableTableManager(_db, _db.olySessionTemplates);
  $$OlySessionExercisesTableTableManager get olySessionExercises =>
      $$OlySessionExercisesTableTableManager(_db, _db.olySessionExercises);
  $$OlyTrainingLogsTableTableManager get olyTrainingLogs =>
      $$OlyTrainingLogsTableTableManager(_db, _db.olyTrainingLogs);
  $$UserTrainingProgressTableTableManager get userTrainingProgress =>
      $$UserTrainingProgressTableTableManager(_db, _db.userTrainingProgress);
}
