// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift.database.dart';

// ignore_for_file: type=lint
class Signatures extends Table with TableInfo<Signatures, SignatureRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Signatures(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(Signatures.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(Signatures.$converterupdatedAt);
  static const VerificationMeta _pseudoMeta = const VerificationMeta('pseudo');
  late final GeneratedColumn<String> pseudo = GeneratedColumn<String>(
    'pseudo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<List<String>, String> avatarFrames = GeneratedColumn<String>(
    'avatar_frames',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<String>>(Signatures.$converteravatarFrames);
  static const VerificationMeta _colorArgbMeta = const VerificationMeta('colorArgb');
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ghostSpeedMeta = const VerificationMeta('ghostSpeed');
  late final GeneratedColumn<double> ghostSpeed = GeneratedColumn<double>(
    'ghost_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _avatarFrameSpeedMeta = const VerificationMeta('avatarFrameSpeed');
  late final GeneratedColumn<double> avatarFrameSpeed = GeneratedColumn<double>(
    'avatar_frame_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<Map<int, String>, String> socialLinks = GeneratedColumn<String>(
    'social_links',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<Map<int, String>>(Signatures.$convertersocialLinks);
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _bioFontMeta = const VerificationMeta('bioFont');
  late final GeneratedColumn<int> bioFont = GeneratedColumn<int>(
    'bio_font',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    pseudo,
    avatarFrames,
    colorArgb,
    ghostSpeed,
    avatarFrameSpeed,
    socialLinks,
    bio,
    bioFont,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signatures';
  @override
  VerificationContext validateIntegrity(Insertable<SignatureRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pseudo')) {
      context.handle(_pseudoMeta, pseudo.isAcceptableOrUnknown(data['pseudo']!, _pseudoMeta));
    } else if (isInserting) {
      context.missing(_pseudoMeta);
    }
    if (data.containsKey('color_argb')) {
      context.handle(_colorArgbMeta, colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta));
    }
    if (data.containsKey('ghost_speed')) {
      context.handle(_ghostSpeedMeta, ghostSpeed.isAcceptableOrUnknown(data['ghost_speed']!, _ghostSpeedMeta));
    } else if (isInserting) {
      context.missing(_ghostSpeedMeta);
    }
    if (data.containsKey('avatar_frame_speed')) {
      context.handle(
        _avatarFrameSpeedMeta,
        avatarFrameSpeed.isAcceptableOrUnknown(data['avatar_frame_speed']!, _avatarFrameSpeedMeta),
      );
    } else if (isInserting) {
      context.missing(_avatarFrameSpeedMeta);
    }
    if (data.containsKey('bio')) {
      context.handle(_bioMeta, bio.isAcceptableOrUnknown(data['bio']!, _bioMeta));
    }
    if (data.containsKey('bio_font')) {
      context.handle(_bioFontMeta, bioFont.isAcceptableOrUnknown(data['bio_font']!, _bioFontMeta));
    } else if (isInserting) {
      context.missing(_bioFontMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignatureRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignatureRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: Signatures.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: Signatures.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      pseudo: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pseudo'])!,
      avatarFrames: Signatures.$converteravatarFrames.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}avatar_frames'])!,
      ),
      colorArgb: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color_argb']),
      ghostSpeed: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}ghost_speed'])!,
      avatarFrameSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avatar_frame_speed'],
      )!,
      socialLinks: Signatures.$convertersocialLinks.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}social_links'])!,
      ),
      bio: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}bio']),
      bioFont: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bio_font'])!,
    );
  }

  @override
  Signatures createAlias(String alias) {
    return Signatures(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const MillisDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt = const MillisDateTimeConverter();
  static TypeConverter<List<String>, String> $converteravatarFrames = const StringListConverter();
  static TypeConverter<Map<int, String>, String> $convertersocialLinks = const IntStringMapConverter();
  @override
  bool get dontWriteConstraints => true;
}

class SignatureRow extends DataClass implements Insertable<SignatureRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String pseudo;
  final List<String> avatarFrames;
  final int? colorArgb;
  final double ghostSpeed;
  final double avatarFrameSpeed;
  final Map<int, String> socialLinks;
  final String? bio;
  final int bioFont;
  const SignatureRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.pseudo,
    required this.avatarFrames,
    this.colorArgb,
    required this.ghostSpeed,
    required this.avatarFrameSpeed,
    required this.socialLinks,
    this.bio,
    required this.bioFont,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['created_at'] = Variable<int>(Signatures.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(Signatures.$converterupdatedAt.toSql(updatedAt));
    }
    map['pseudo'] = Variable<String>(pseudo);
    {
      map['avatar_frames'] = Variable<String>(Signatures.$converteravatarFrames.toSql(avatarFrames));
    }
    if (!nullToAbsent || colorArgb != null) {
      map['color_argb'] = Variable<int>(colorArgb);
    }
    map['ghost_speed'] = Variable<double>(ghostSpeed);
    map['avatar_frame_speed'] = Variable<double>(avatarFrameSpeed);
    {
      map['social_links'] = Variable<String>(Signatures.$convertersocialLinks.toSql(socialLinks));
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    map['bio_font'] = Variable<int>(bioFont);
    return map;
  }

  SignaturesCompanion toCompanion(bool nullToAbsent) {
    return SignaturesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pseudo: Value(pseudo),
      avatarFrames: Value(avatarFrames),
      colorArgb: colorArgb == null && nullToAbsent ? const Value.absent() : Value(colorArgb),
      ghostSpeed: Value(ghostSpeed),
      avatarFrameSpeed: Value(avatarFrameSpeed),
      socialLinks: Value(socialLinks),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      bioFont: Value(bioFont),
    );
  }

  factory SignatureRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignatureRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      pseudo: serializer.fromJson<String>(json['pseudo']),
      avatarFrames: serializer.fromJson<List<String>>(json['avatar_frames']),
      colorArgb: serializer.fromJson<int?>(json['color_argb']),
      ghostSpeed: serializer.fromJson<double>(json['ghost_speed']),
      avatarFrameSpeed: serializer.fromJson<double>(json['avatar_frame_speed']),
      socialLinks: serializer.fromJson<Map<int, String>>(json['social_links']),
      bio: serializer.fromJson<String?>(json['bio']),
      bioFont: serializer.fromJson<int>(json['bio_font']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'pseudo': serializer.toJson<String>(pseudo),
      'avatar_frames': serializer.toJson<List<String>>(avatarFrames),
      'color_argb': serializer.toJson<int?>(colorArgb),
      'ghost_speed': serializer.toJson<double>(ghostSpeed),
      'avatar_frame_speed': serializer.toJson<double>(avatarFrameSpeed),
      'social_links': serializer.toJson<Map<int, String>>(socialLinks),
      'bio': serializer.toJson<String?>(bio),
      'bio_font': serializer.toJson<int>(bioFont),
    };
  }

  SignatureRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? pseudo,
    List<String>? avatarFrames,
    Value<int?> colorArgb = const Value.absent(),
    double? ghostSpeed,
    double? avatarFrameSpeed,
    Map<int, String>? socialLinks,
    Value<String?> bio = const Value.absent(),
    int? bioFont,
  }) => SignatureRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pseudo: pseudo ?? this.pseudo,
    avatarFrames: avatarFrames ?? this.avatarFrames,
    colorArgb: colorArgb.present ? colorArgb.value : this.colorArgb,
    ghostSpeed: ghostSpeed ?? this.ghostSpeed,
    avatarFrameSpeed: avatarFrameSpeed ?? this.avatarFrameSpeed,
    socialLinks: socialLinks ?? this.socialLinks,
    bio: bio.present ? bio.value : this.bio,
    bioFont: bioFont ?? this.bioFont,
  );
  SignatureRow copyWithCompanion(SignaturesCompanion data) {
    return SignatureRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pseudo: data.pseudo.present ? data.pseudo.value : this.pseudo,
      avatarFrames: data.avatarFrames.present ? data.avatarFrames.value : this.avatarFrames,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
      ghostSpeed: data.ghostSpeed.present ? data.ghostSpeed.value : this.ghostSpeed,
      avatarFrameSpeed: data.avatarFrameSpeed.present ? data.avatarFrameSpeed.value : this.avatarFrameSpeed,
      socialLinks: data.socialLinks.present ? data.socialLinks.value : this.socialLinks,
      bio: data.bio.present ? data.bio.value : this.bio,
      bioFont: data.bioFont.present ? data.bioFont.value : this.bioFont,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignatureRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pseudo: $pseudo, ')
          ..write('avatarFrames: $avatarFrames, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('ghostSpeed: $ghostSpeed, ')
          ..write('avatarFrameSpeed: $avatarFrameSpeed, ')
          ..write('socialLinks: $socialLinks, ')
          ..write('bio: $bio, ')
          ..write('bioFont: $bioFont')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    pseudo,
    avatarFrames,
    colorArgb,
    ghostSpeed,
    avatarFrameSpeed,
    socialLinks,
    bio,
    bioFont,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignatureRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pseudo == this.pseudo &&
          other.avatarFrames == this.avatarFrames &&
          other.colorArgb == this.colorArgb &&
          other.ghostSpeed == this.ghostSpeed &&
          other.avatarFrameSpeed == this.avatarFrameSpeed &&
          other.socialLinks == this.socialLinks &&
          other.bio == this.bio &&
          other.bioFont == this.bioFont);
}

class SignaturesCompanion extends UpdateCompanion<SignatureRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> pseudo;
  final Value<List<String>> avatarFrames;
  final Value<int?> colorArgb;
  final Value<double> ghostSpeed;
  final Value<double> avatarFrameSpeed;
  final Value<Map<int, String>> socialLinks;
  final Value<String?> bio;
  final Value<int> bioFont;
  final Value<int> rowid;
  const SignaturesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pseudo = const Value.absent(),
    this.avatarFrames = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.ghostSpeed = const Value.absent(),
    this.avatarFrameSpeed = const Value.absent(),
    this.socialLinks = const Value.absent(),
    this.bio = const Value.absent(),
    this.bioFont = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignaturesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String pseudo,
    required List<String> avatarFrames,
    this.colorArgb = const Value.absent(),
    required double ghostSpeed,
    required double avatarFrameSpeed,
    required Map<int, String> socialLinks,
    this.bio = const Value.absent(),
    required int bioFont,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       pseudo = Value(pseudo),
       avatarFrames = Value(avatarFrames),
       ghostSpeed = Value(ghostSpeed),
       avatarFrameSpeed = Value(avatarFrameSpeed),
       socialLinks = Value(socialLinks),
       bioFont = Value(bioFont);
  static Insertable<SignatureRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? pseudo,
    Expression<String>? avatarFrames,
    Expression<int>? colorArgb,
    Expression<double>? ghostSpeed,
    Expression<double>? avatarFrameSpeed,
    Expression<String>? socialLinks,
    Expression<String>? bio,
    Expression<int>? bioFont,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pseudo != null) 'pseudo': pseudo,
      if (avatarFrames != null) 'avatar_frames': avatarFrames,
      if (colorArgb != null) 'color_argb': colorArgb,
      if (ghostSpeed != null) 'ghost_speed': ghostSpeed,
      if (avatarFrameSpeed != null) 'avatar_frame_speed': avatarFrameSpeed,
      if (socialLinks != null) 'social_links': socialLinks,
      if (bio != null) 'bio': bio,
      if (bioFont != null) 'bio_font': bioFont,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignaturesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? pseudo,
    Value<List<String>>? avatarFrames,
    Value<int?>? colorArgb,
    Value<double>? ghostSpeed,
    Value<double>? avatarFrameSpeed,
    Value<Map<int, String>>? socialLinks,
    Value<String?>? bio,
    Value<int>? bioFont,
    Value<int>? rowid,
  }) {
    return SignaturesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pseudo: pseudo ?? this.pseudo,
      avatarFrames: avatarFrames ?? this.avatarFrames,
      colorArgb: colorArgb ?? this.colorArgb,
      ghostSpeed: ghostSpeed ?? this.ghostSpeed,
      avatarFrameSpeed: avatarFrameSpeed ?? this.avatarFrameSpeed,
      socialLinks: socialLinks ?? this.socialLinks,
      bio: bio ?? this.bio,
      bioFont: bioFont ?? this.bioFont,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(Signatures.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(Signatures.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (pseudo.present) {
      map['pseudo'] = Variable<String>(pseudo.value);
    }
    if (avatarFrames.present) {
      map['avatar_frames'] = Variable<String>(Signatures.$converteravatarFrames.toSql(avatarFrames.value));
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    if (ghostSpeed.present) {
      map['ghost_speed'] = Variable<double>(ghostSpeed.value);
    }
    if (avatarFrameSpeed.present) {
      map['avatar_frame_speed'] = Variable<double>(avatarFrameSpeed.value);
    }
    if (socialLinks.present) {
      map['social_links'] = Variable<String>(Signatures.$convertersocialLinks.toSql(socialLinks.value));
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (bioFont.present) {
      map['bio_font'] = Variable<int>(bioFont.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignaturesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pseudo: $pseudo, ')
          ..write('avatarFrames: $avatarFrames, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('ghostSpeed: $ghostSpeed, ')
          ..write('avatarFrameSpeed: $avatarFrameSpeed, ')
          ..write('socialLinks: $socialLinks, ')
          ..write('bio: $bio, ')
          ..write('bioFont: $bioFont, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class UserSettingsStore extends Table with TableInfo<UserSettingsStore, UserSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  UserSettingsStore(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final GeneratedColumnWithTypeConverter<List<String>, String> blockedUrls = GeneratedColumn<String>(
    'blocked_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<String>>(UserSettingsStore.$converterblockedUrls);
  late final GeneratedColumnWithTypeConverter<List<String>, String> blockedWords = GeneratedColumn<String>(
    'blocked_words',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<String>>(UserSettingsStore.$converterblockedWords);
  static const VerificationMeta _isAnonymousByDefaultMeta = const VerificationMeta('isAnonymousByDefault');
  late final GeneratedColumn<bool> isAnonymousByDefault = GeneratedColumn<bool>(
    'is_anonymous_by_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isExchangeEnabledMeta = const VerificationMeta('isExchangeEnabled');
  late final GeneratedColumn<bool> isExchangeEnabled = GeneratedColumn<bool>(
    'is_exchange_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, blockedUrls, blockedWords, isAnonymousByDefault, isExchangeEnabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings_store';
  @override
  VerificationContext validateIntegrity(Insertable<UserSettingsRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_anonymous_by_default')) {
      context.handle(
        _isAnonymousByDefaultMeta,
        isAnonymousByDefault.isAcceptableOrUnknown(data['is_anonymous_by_default']!, _isAnonymousByDefaultMeta),
      );
    } else if (isInserting) {
      context.missing(_isAnonymousByDefaultMeta);
    }
    if (data.containsKey('is_exchange_enabled')) {
      context.handle(
        _isExchangeEnabledMeta,
        isExchangeEnabled.isAcceptableOrUnknown(data['is_exchange_enabled']!, _isExchangeEnabledMeta),
      );
    } else if (isInserting) {
      context.missing(_isExchangeEnabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      blockedUrls: UserSettingsStore.$converterblockedUrls.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}blocked_urls'])!,
      ),
      blockedWords: UserSettingsStore.$converterblockedWords.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}blocked_words'])!,
      ),
      isAnonymousByDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_anonymous_by_default'],
      )!,
      isExchangeEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_exchange_enabled'],
      )!,
    );
  }

  @override
  UserSettingsStore createAlias(String alias) {
    return UserSettingsStore(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterblockedUrls = const StringListConverter();
  static TypeConverter<List<String>, String> $converterblockedWords = const StringListConverter();
  @override
  bool get dontWriteConstraints => true;
}

class UserSettingsRow extends DataClass implements Insertable<UserSettingsRow> {
  final int id;
  final List<String> blockedUrls;
  final List<String> blockedWords;
  final bool isAnonymousByDefault;
  final bool isExchangeEnabled;
  const UserSettingsRow({
    required this.id,
    required this.blockedUrls,
    required this.blockedWords,
    required this.isAnonymousByDefault,
    required this.isExchangeEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['blocked_urls'] = Variable<String>(UserSettingsStore.$converterblockedUrls.toSql(blockedUrls));
    }
    {
      map['blocked_words'] = Variable<String>(UserSettingsStore.$converterblockedWords.toSql(blockedWords));
    }
    map['is_anonymous_by_default'] = Variable<bool>(isAnonymousByDefault);
    map['is_exchange_enabled'] = Variable<bool>(isExchangeEnabled);
    return map;
  }

  UserSettingsStoreCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsStoreCompanion(
      id: Value(id),
      blockedUrls: Value(blockedUrls),
      blockedWords: Value(blockedWords),
      isAnonymousByDefault: Value(isAnonymousByDefault),
      isExchangeEnabled: Value(isExchangeEnabled),
    );
  }

  factory UserSettingsRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      blockedUrls: serializer.fromJson<List<String>>(json['blocked_urls']),
      blockedWords: serializer.fromJson<List<String>>(json['blocked_words']),
      isAnonymousByDefault: serializer.fromJson<bool>(json['is_anonymous_by_default']),
      isExchangeEnabled: serializer.fromJson<bool>(json['is_exchange_enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'blocked_urls': serializer.toJson<List<String>>(blockedUrls),
      'blocked_words': serializer.toJson<List<String>>(blockedWords),
      'is_anonymous_by_default': serializer.toJson<bool>(isAnonymousByDefault),
      'is_exchange_enabled': serializer.toJson<bool>(isExchangeEnabled),
    };
  }

  UserSettingsRow copyWith({
    int? id,
    List<String>? blockedUrls,
    List<String>? blockedWords,
    bool? isAnonymousByDefault,
    bool? isExchangeEnabled,
  }) => UserSettingsRow(
    id: id ?? this.id,
    blockedUrls: blockedUrls ?? this.blockedUrls,
    blockedWords: blockedWords ?? this.blockedWords,
    isAnonymousByDefault: isAnonymousByDefault ?? this.isAnonymousByDefault,
    isExchangeEnabled: isExchangeEnabled ?? this.isExchangeEnabled,
  );
  UserSettingsRow copyWithCompanion(UserSettingsStoreCompanion data) {
    return UserSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      blockedUrls: data.blockedUrls.present ? data.blockedUrls.value : this.blockedUrls,
      blockedWords: data.blockedWords.present ? data.blockedWords.value : this.blockedWords,
      isAnonymousByDefault: data.isAnonymousByDefault.present
          ? data.isAnonymousByDefault.value
          : this.isAnonymousByDefault,
      isExchangeEnabled: data.isExchangeEnabled.present ? data.isExchangeEnabled.value : this.isExchangeEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsRow(')
          ..write('id: $id, ')
          ..write('blockedUrls: $blockedUrls, ')
          ..write('blockedWords: $blockedWords, ')
          ..write('isAnonymousByDefault: $isAnonymousByDefault, ')
          ..write('isExchangeEnabled: $isExchangeEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, blockedUrls, blockedWords, isAnonymousByDefault, isExchangeEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsRow &&
          other.id == this.id &&
          other.blockedUrls == this.blockedUrls &&
          other.blockedWords == this.blockedWords &&
          other.isAnonymousByDefault == this.isAnonymousByDefault &&
          other.isExchangeEnabled == this.isExchangeEnabled);
}

class UserSettingsStoreCompanion extends UpdateCompanion<UserSettingsRow> {
  final Value<int> id;
  final Value<List<String>> blockedUrls;
  final Value<List<String>> blockedWords;
  final Value<bool> isAnonymousByDefault;
  final Value<bool> isExchangeEnabled;
  const UserSettingsStoreCompanion({
    this.id = const Value.absent(),
    this.blockedUrls = const Value.absent(),
    this.blockedWords = const Value.absent(),
    this.isAnonymousByDefault = const Value.absent(),
    this.isExchangeEnabled = const Value.absent(),
  });
  UserSettingsStoreCompanion.insert({
    this.id = const Value.absent(),
    required List<String> blockedUrls,
    required List<String> blockedWords,
    required bool isAnonymousByDefault,
    required bool isExchangeEnabled,
  }) : blockedUrls = Value(blockedUrls),
       blockedWords = Value(blockedWords),
       isAnonymousByDefault = Value(isAnonymousByDefault),
       isExchangeEnabled = Value(isExchangeEnabled);
  static Insertable<UserSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? blockedUrls,
    Expression<String>? blockedWords,
    Expression<bool>? isAnonymousByDefault,
    Expression<bool>? isExchangeEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (blockedUrls != null) 'blocked_urls': blockedUrls,
      if (blockedWords != null) 'blocked_words': blockedWords,
      if (isAnonymousByDefault != null) 'is_anonymous_by_default': isAnonymousByDefault,
      if (isExchangeEnabled != null) 'is_exchange_enabled': isExchangeEnabled,
    });
  }

  UserSettingsStoreCompanion copyWith({
    Value<int>? id,
    Value<List<String>>? blockedUrls,
    Value<List<String>>? blockedWords,
    Value<bool>? isAnonymousByDefault,
    Value<bool>? isExchangeEnabled,
  }) {
    return UserSettingsStoreCompanion(
      id: id ?? this.id,
      blockedUrls: blockedUrls ?? this.blockedUrls,
      blockedWords: blockedWords ?? this.blockedWords,
      isAnonymousByDefault: isAnonymousByDefault ?? this.isAnonymousByDefault,
      isExchangeEnabled: isExchangeEnabled ?? this.isExchangeEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (blockedUrls.present) {
      map['blocked_urls'] = Variable<String>(UserSettingsStore.$converterblockedUrls.toSql(blockedUrls.value));
    }
    if (blockedWords.present) {
      map['blocked_words'] = Variable<String>(UserSettingsStore.$converterblockedWords.toSql(blockedWords.value));
    }
    if (isAnonymousByDefault.present) {
      map['is_anonymous_by_default'] = Variable<bool>(isAnonymousByDefault.value);
    }
    if (isExchangeEnabled.present) {
      map['is_exchange_enabled'] = Variable<bool>(isExchangeEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsStoreCompanion(')
          ..write('id: $id, ')
          ..write('blockedUrls: $blockedUrls, ')
          ..write('blockedWords: $blockedWords, ')
          ..write('isAnonymousByDefault: $isAnonymousByDefault, ')
          ..write('isExchangeEnabled: $isExchangeEnabled')
          ..write(')'))
        .toString();
  }
}

class ExchangeLogs extends Table with TableInfo<ExchangeLogs, ExchangeLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExchangeLogs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(ExchangeLogs.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(ExchangeLogs.$converterupdatedAt);
  static const VerificationMeta _peerAddressMeta = const VerificationMeta('peerAddress');
  late final GeneratedColumn<String> peerAddress = GeneratedColumn<String>(
    'peer_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta('outcome');
  late final GeneratedColumn<int> outcome = GeneratedColumn<int>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isInitiatorMeta = const VerificationMeta('isInitiator');
  late final GeneratedColumn<bool> isInitiator = GeneratedColumn<bool>(
    'is_initiator',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _durationInMillisMeta = const VerificationMeta('durationInMillis');
  late final GeneratedColumn<int> durationInMillis = GeneratedColumn<int>(
    'duration_in_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _awaitedStepMeta = const VerificationMeta('awaitedStep');
  late final GeneratedColumn<int> awaitedStep = GeneratedColumn<int>(
    'awaited_step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _sentBytesMeta = const VerificationMeta('sentBytes');
  late final GeneratedColumn<int> sentBytes = GeneratedColumn<int>(
    'sent_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _receivedBytesMeta = const VerificationMeta('receivedBytes');
  late final GeneratedColumn<int> receivedBytes = GeneratedColumn<int>(
    'received_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _importedContentsMeta = const VerificationMeta('importedContents');
  late final GeneratedColumn<int> importedContents = GeneratedColumn<int>(
    'imported_contents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _rejectedContentsMeta = const VerificationMeta('rejectedContents');
  late final GeneratedColumn<int> rejectedContents = GeneratedColumn<int>(
    'rejected_contents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _importedReactionsMeta = const VerificationMeta('importedReactions');
  late final GeneratedColumn<int> importedReactions = GeneratedColumn<int>(
    'imported_reactions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _rejectedReactionsMeta = const VerificationMeta('rejectedReactions');
  late final GeneratedColumn<int> rejectedReactions = GeneratedColumn<int>(
    'rejected_reactions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _removedContentsMeta = const VerificationMeta('removedContents');
  late final GeneratedColumn<int> removedContents = GeneratedColumn<int>(
    'removed_contents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    peerAddress,
    outcome,
    isInitiator,
    durationInMillis,
    awaitedStep,
    sentBytes,
    receivedBytes,
    importedContents,
    rejectedContents,
    importedReactions,
    rejectedReactions,
    removedContents,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ExchangeLogRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('peer_address')) {
      context.handle(_peerAddressMeta, peerAddress.isAcceptableOrUnknown(data['peer_address']!, _peerAddressMeta));
    } else if (isInserting) {
      context.missing(_peerAddressMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(_outcomeMeta, outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta));
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('is_initiator')) {
      context.handle(_isInitiatorMeta, isInitiator.isAcceptableOrUnknown(data['is_initiator']!, _isInitiatorMeta));
    }
    if (data.containsKey('duration_in_millis')) {
      context.handle(
        _durationInMillisMeta,
        durationInMillis.isAcceptableOrUnknown(data['duration_in_millis']!, _durationInMillisMeta),
      );
    } else if (isInserting) {
      context.missing(_durationInMillisMeta);
    }
    if (data.containsKey('awaited_step')) {
      context.handle(_awaitedStepMeta, awaitedStep.isAcceptableOrUnknown(data['awaited_step']!, _awaitedStepMeta));
    }
    if (data.containsKey('sent_bytes')) {
      context.handle(_sentBytesMeta, sentBytes.isAcceptableOrUnknown(data['sent_bytes']!, _sentBytesMeta));
    } else if (isInserting) {
      context.missing(_sentBytesMeta);
    }
    if (data.containsKey('received_bytes')) {
      context.handle(
        _receivedBytesMeta,
        receivedBytes.isAcceptableOrUnknown(data['received_bytes']!, _receivedBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedBytesMeta);
    }
    if (data.containsKey('imported_contents')) {
      context.handle(
        _importedContentsMeta,
        importedContents.isAcceptableOrUnknown(data['imported_contents']!, _importedContentsMeta),
      );
    } else if (isInserting) {
      context.missing(_importedContentsMeta);
    }
    if (data.containsKey('rejected_contents')) {
      context.handle(
        _rejectedContentsMeta,
        rejectedContents.isAcceptableOrUnknown(data['rejected_contents']!, _rejectedContentsMeta),
      );
    } else if (isInserting) {
      context.missing(_rejectedContentsMeta);
    }
    if (data.containsKey('imported_reactions')) {
      context.handle(
        _importedReactionsMeta,
        importedReactions.isAcceptableOrUnknown(data['imported_reactions']!, _importedReactionsMeta),
      );
    } else if (isInserting) {
      context.missing(_importedReactionsMeta);
    }
    if (data.containsKey('rejected_reactions')) {
      context.handle(
        _rejectedReactionsMeta,
        rejectedReactions.isAcceptableOrUnknown(data['rejected_reactions']!, _rejectedReactionsMeta),
      );
    } else if (isInserting) {
      context.missing(_rejectedReactionsMeta);
    }
    if (data.containsKey('removed_contents')) {
      context.handle(
        _removedContentsMeta,
        removedContents.isAcceptableOrUnknown(data['removed_contents']!, _removedContentsMeta),
      );
    } else if (isInserting) {
      context.missing(_removedContentsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExchangeLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeLogRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: ExchangeLogs.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: ExchangeLogs.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      peerAddress: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}peer_address'])!,
      outcome: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}outcome'])!,
      isInitiator: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_initiator']),
      durationInMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_in_millis'],
      )!,
      awaitedStep: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}awaited_step']),
      sentBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sent_bytes'])!,
      receivedBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}received_bytes'])!,
      importedContents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imported_contents'],
      )!,
      rejectedContents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rejected_contents'],
      )!,
      importedReactions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imported_reactions'],
      )!,
      rejectedReactions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rejected_reactions'],
      )!,
      removedContents: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}removed_contents'])!,
    );
  }

  @override
  ExchangeLogs createAlias(String alias) {
    return ExchangeLogs(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const MillisDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt = const MillisDateTimeConverter();
  @override
  bool get dontWriteConstraints => true;
}

class ExchangeLogRow extends DataClass implements Insertable<ExchangeLogRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String peerAddress;
  final int outcome;
  final bool? isInitiator;
  final int durationInMillis;
  final int? awaitedStep;
  final int sentBytes;
  final int receivedBytes;
  final int importedContents;
  final int rejectedContents;
  final int importedReactions;
  final int rejectedReactions;
  final int removedContents;
  const ExchangeLogRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.peerAddress,
    required this.outcome,
    this.isInitiator,
    required this.durationInMillis,
    this.awaitedStep,
    required this.sentBytes,
    required this.receivedBytes,
    required this.importedContents,
    required this.rejectedContents,
    required this.importedReactions,
    required this.rejectedReactions,
    required this.removedContents,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['created_at'] = Variable<int>(ExchangeLogs.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(ExchangeLogs.$converterupdatedAt.toSql(updatedAt));
    }
    map['peer_address'] = Variable<String>(peerAddress);
    map['outcome'] = Variable<int>(outcome);
    if (!nullToAbsent || isInitiator != null) {
      map['is_initiator'] = Variable<bool>(isInitiator);
    }
    map['duration_in_millis'] = Variable<int>(durationInMillis);
    if (!nullToAbsent || awaitedStep != null) {
      map['awaited_step'] = Variable<int>(awaitedStep);
    }
    map['sent_bytes'] = Variable<int>(sentBytes);
    map['received_bytes'] = Variable<int>(receivedBytes);
    map['imported_contents'] = Variable<int>(importedContents);
    map['rejected_contents'] = Variable<int>(rejectedContents);
    map['imported_reactions'] = Variable<int>(importedReactions);
    map['rejected_reactions'] = Variable<int>(rejectedReactions);
    map['removed_contents'] = Variable<int>(removedContents);
    return map;
  }

  ExchangeLogsCompanion toCompanion(bool nullToAbsent) {
    return ExchangeLogsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      peerAddress: Value(peerAddress),
      outcome: Value(outcome),
      isInitiator: isInitiator == null && nullToAbsent ? const Value.absent() : Value(isInitiator),
      durationInMillis: Value(durationInMillis),
      awaitedStep: awaitedStep == null && nullToAbsent ? const Value.absent() : Value(awaitedStep),
      sentBytes: Value(sentBytes),
      receivedBytes: Value(receivedBytes),
      importedContents: Value(importedContents),
      rejectedContents: Value(rejectedContents),
      importedReactions: Value(importedReactions),
      rejectedReactions: Value(rejectedReactions),
      removedContents: Value(removedContents),
    );
  }

  factory ExchangeLogRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeLogRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      peerAddress: serializer.fromJson<String>(json['peer_address']),
      outcome: serializer.fromJson<int>(json['outcome']),
      isInitiator: serializer.fromJson<bool?>(json['is_initiator']),
      durationInMillis: serializer.fromJson<int>(json['duration_in_millis']),
      awaitedStep: serializer.fromJson<int?>(json['awaited_step']),
      sentBytes: serializer.fromJson<int>(json['sent_bytes']),
      receivedBytes: serializer.fromJson<int>(json['received_bytes']),
      importedContents: serializer.fromJson<int>(json['imported_contents']),
      rejectedContents: serializer.fromJson<int>(json['rejected_contents']),
      importedReactions: serializer.fromJson<int>(json['imported_reactions']),
      rejectedReactions: serializer.fromJson<int>(json['rejected_reactions']),
      removedContents: serializer.fromJson<int>(json['removed_contents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'peer_address': serializer.toJson<String>(peerAddress),
      'outcome': serializer.toJson<int>(outcome),
      'is_initiator': serializer.toJson<bool?>(isInitiator),
      'duration_in_millis': serializer.toJson<int>(durationInMillis),
      'awaited_step': serializer.toJson<int?>(awaitedStep),
      'sent_bytes': serializer.toJson<int>(sentBytes),
      'received_bytes': serializer.toJson<int>(receivedBytes),
      'imported_contents': serializer.toJson<int>(importedContents),
      'rejected_contents': serializer.toJson<int>(rejectedContents),
      'imported_reactions': serializer.toJson<int>(importedReactions),
      'rejected_reactions': serializer.toJson<int>(rejectedReactions),
      'removed_contents': serializer.toJson<int>(removedContents),
    };
  }

  ExchangeLogRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? peerAddress,
    int? outcome,
    Value<bool?> isInitiator = const Value.absent(),
    int? durationInMillis,
    Value<int?> awaitedStep = const Value.absent(),
    int? sentBytes,
    int? receivedBytes,
    int? importedContents,
    int? rejectedContents,
    int? importedReactions,
    int? rejectedReactions,
    int? removedContents,
  }) => ExchangeLogRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    peerAddress: peerAddress ?? this.peerAddress,
    outcome: outcome ?? this.outcome,
    isInitiator: isInitiator.present ? isInitiator.value : this.isInitiator,
    durationInMillis: durationInMillis ?? this.durationInMillis,
    awaitedStep: awaitedStep.present ? awaitedStep.value : this.awaitedStep,
    sentBytes: sentBytes ?? this.sentBytes,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    importedContents: importedContents ?? this.importedContents,
    rejectedContents: rejectedContents ?? this.rejectedContents,
    importedReactions: importedReactions ?? this.importedReactions,
    rejectedReactions: rejectedReactions ?? this.rejectedReactions,
    removedContents: removedContents ?? this.removedContents,
  );
  ExchangeLogRow copyWithCompanion(ExchangeLogsCompanion data) {
    return ExchangeLogRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      peerAddress: data.peerAddress.present ? data.peerAddress.value : this.peerAddress,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      isInitiator: data.isInitiator.present ? data.isInitiator.value : this.isInitiator,
      durationInMillis: data.durationInMillis.present ? data.durationInMillis.value : this.durationInMillis,
      awaitedStep: data.awaitedStep.present ? data.awaitedStep.value : this.awaitedStep,
      sentBytes: data.sentBytes.present ? data.sentBytes.value : this.sentBytes,
      receivedBytes: data.receivedBytes.present ? data.receivedBytes.value : this.receivedBytes,
      importedContents: data.importedContents.present ? data.importedContents.value : this.importedContents,
      rejectedContents: data.rejectedContents.present ? data.rejectedContents.value : this.rejectedContents,
      importedReactions: data.importedReactions.present ? data.importedReactions.value : this.importedReactions,
      rejectedReactions: data.rejectedReactions.present ? data.rejectedReactions.value : this.rejectedReactions,
      removedContents: data.removedContents.present ? data.removedContents.value : this.removedContents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeLogRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('peerAddress: $peerAddress, ')
          ..write('outcome: $outcome, ')
          ..write('isInitiator: $isInitiator, ')
          ..write('durationInMillis: $durationInMillis, ')
          ..write('awaitedStep: $awaitedStep, ')
          ..write('sentBytes: $sentBytes, ')
          ..write('receivedBytes: $receivedBytes, ')
          ..write('importedContents: $importedContents, ')
          ..write('rejectedContents: $rejectedContents, ')
          ..write('importedReactions: $importedReactions, ')
          ..write('rejectedReactions: $rejectedReactions, ')
          ..write('removedContents: $removedContents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    peerAddress,
    outcome,
    isInitiator,
    durationInMillis,
    awaitedStep,
    sentBytes,
    receivedBytes,
    importedContents,
    rejectedContents,
    importedReactions,
    rejectedReactions,
    removedContents,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeLogRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.peerAddress == this.peerAddress &&
          other.outcome == this.outcome &&
          other.isInitiator == this.isInitiator &&
          other.durationInMillis == this.durationInMillis &&
          other.awaitedStep == this.awaitedStep &&
          other.sentBytes == this.sentBytes &&
          other.receivedBytes == this.receivedBytes &&
          other.importedContents == this.importedContents &&
          other.rejectedContents == this.rejectedContents &&
          other.importedReactions == this.importedReactions &&
          other.rejectedReactions == this.rejectedReactions &&
          other.removedContents == this.removedContents);
}

class ExchangeLogsCompanion extends UpdateCompanion<ExchangeLogRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> peerAddress;
  final Value<int> outcome;
  final Value<bool?> isInitiator;
  final Value<int> durationInMillis;
  final Value<int?> awaitedStep;
  final Value<int> sentBytes;
  final Value<int> receivedBytes;
  final Value<int> importedContents;
  final Value<int> rejectedContents;
  final Value<int> importedReactions;
  final Value<int> rejectedReactions;
  final Value<int> removedContents;
  final Value<int> rowid;
  const ExchangeLogsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.peerAddress = const Value.absent(),
    this.outcome = const Value.absent(),
    this.isInitiator = const Value.absent(),
    this.durationInMillis = const Value.absent(),
    this.awaitedStep = const Value.absent(),
    this.sentBytes = const Value.absent(),
    this.receivedBytes = const Value.absent(),
    this.importedContents = const Value.absent(),
    this.rejectedContents = const Value.absent(),
    this.importedReactions = const Value.absent(),
    this.rejectedReactions = const Value.absent(),
    this.removedContents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeLogsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String peerAddress,
    required int outcome,
    this.isInitiator = const Value.absent(),
    required int durationInMillis,
    this.awaitedStep = const Value.absent(),
    required int sentBytes,
    required int receivedBytes,
    required int importedContents,
    required int rejectedContents,
    required int importedReactions,
    required int rejectedReactions,
    required int removedContents,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       peerAddress = Value(peerAddress),
       outcome = Value(outcome),
       durationInMillis = Value(durationInMillis),
       sentBytes = Value(sentBytes),
       receivedBytes = Value(receivedBytes),
       importedContents = Value(importedContents),
       rejectedContents = Value(rejectedContents),
       importedReactions = Value(importedReactions),
       rejectedReactions = Value(rejectedReactions),
       removedContents = Value(removedContents);
  static Insertable<ExchangeLogRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? peerAddress,
    Expression<int>? outcome,
    Expression<bool>? isInitiator,
    Expression<int>? durationInMillis,
    Expression<int>? awaitedStep,
    Expression<int>? sentBytes,
    Expression<int>? receivedBytes,
    Expression<int>? importedContents,
    Expression<int>? rejectedContents,
    Expression<int>? importedReactions,
    Expression<int>? rejectedReactions,
    Expression<int>? removedContents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (peerAddress != null) 'peer_address': peerAddress,
      if (outcome != null) 'outcome': outcome,
      if (isInitiator != null) 'is_initiator': isInitiator,
      if (durationInMillis != null) 'duration_in_millis': durationInMillis,
      if (awaitedStep != null) 'awaited_step': awaitedStep,
      if (sentBytes != null) 'sent_bytes': sentBytes,
      if (receivedBytes != null) 'received_bytes': receivedBytes,
      if (importedContents != null) 'imported_contents': importedContents,
      if (rejectedContents != null) 'rejected_contents': rejectedContents,
      if (importedReactions != null) 'imported_reactions': importedReactions,
      if (rejectedReactions != null) 'rejected_reactions': rejectedReactions,
      if (removedContents != null) 'removed_contents': removedContents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeLogsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? peerAddress,
    Value<int>? outcome,
    Value<bool?>? isInitiator,
    Value<int>? durationInMillis,
    Value<int?>? awaitedStep,
    Value<int>? sentBytes,
    Value<int>? receivedBytes,
    Value<int>? importedContents,
    Value<int>? rejectedContents,
    Value<int>? importedReactions,
    Value<int>? rejectedReactions,
    Value<int>? removedContents,
    Value<int>? rowid,
  }) {
    return ExchangeLogsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      peerAddress: peerAddress ?? this.peerAddress,
      outcome: outcome ?? this.outcome,
      isInitiator: isInitiator ?? this.isInitiator,
      durationInMillis: durationInMillis ?? this.durationInMillis,
      awaitedStep: awaitedStep ?? this.awaitedStep,
      sentBytes: sentBytes ?? this.sentBytes,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      importedContents: importedContents ?? this.importedContents,
      rejectedContents: rejectedContents ?? this.rejectedContents,
      importedReactions: importedReactions ?? this.importedReactions,
      rejectedReactions: rejectedReactions ?? this.rejectedReactions,
      removedContents: removedContents ?? this.removedContents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(ExchangeLogs.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(ExchangeLogs.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (peerAddress.present) {
      map['peer_address'] = Variable<String>(peerAddress.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<int>(outcome.value);
    }
    if (isInitiator.present) {
      map['is_initiator'] = Variable<bool>(isInitiator.value);
    }
    if (durationInMillis.present) {
      map['duration_in_millis'] = Variable<int>(durationInMillis.value);
    }
    if (awaitedStep.present) {
      map['awaited_step'] = Variable<int>(awaitedStep.value);
    }
    if (sentBytes.present) {
      map['sent_bytes'] = Variable<int>(sentBytes.value);
    }
    if (receivedBytes.present) {
      map['received_bytes'] = Variable<int>(receivedBytes.value);
    }
    if (importedContents.present) {
      map['imported_contents'] = Variable<int>(importedContents.value);
    }
    if (rejectedContents.present) {
      map['rejected_contents'] = Variable<int>(rejectedContents.value);
    }
    if (importedReactions.present) {
      map['imported_reactions'] = Variable<int>(importedReactions.value);
    }
    if (rejectedReactions.present) {
      map['rejected_reactions'] = Variable<int>(rejectedReactions.value);
    }
    if (removedContents.present) {
      map['removed_contents'] = Variable<int>(removedContents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeLogsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('peerAddress: $peerAddress, ')
          ..write('outcome: $outcome, ')
          ..write('isInitiator: $isInitiator, ')
          ..write('durationInMillis: $durationInMillis, ')
          ..write('awaitedStep: $awaitedStep, ')
          ..write('sentBytes: $sentBytes, ')
          ..write('receivedBytes: $receivedBytes, ')
          ..write('importedContents: $importedContents, ')
          ..write('rejectedContents: $rejectedContents, ')
          ..write('importedReactions: $importedReactions, ')
          ..write('rejectedReactions: $rejectedReactions, ')
          ..write('removedContents: $removedContents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ErrorLogs extends Table with TableInfo<ErrorLogs, ErrorLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ErrorLogs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(ErrorLogs.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(ErrorLogs.$converterupdatedAt);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _errorTypeMeta = const VerificationMeta('errorType');
  late final GeneratedColumn<String> errorType = GeneratedColumn<String>(
    'error_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _messageMeta = const VerificationMeta('message');
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stackTraceMeta = const VerificationMeta('stackTrace');
  late final GeneratedColumn<String> stackTrace = GeneratedColumn<String>(
    'stack_trace',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, source, errorType, message, stackTrace];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'error_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ErrorLogRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta, source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('error_type')) {
      context.handle(_errorTypeMeta, errorType.isAcceptableOrUnknown(data['error_type']!, _errorTypeMeta));
    } else if (isInserting) {
      context.missing(_errorTypeMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta, message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('stack_trace')) {
      context.handle(_stackTraceMeta, stackTrace.isAcceptableOrUnknown(data['stack_trace']!, _stackTraceMeta));
    } else if (isInserting) {
      context.missing(_stackTraceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ErrorLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ErrorLogRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: ErrorLogs.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: ErrorLogs.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      source: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      errorType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}error_type'])!,
      message: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      stackTrace: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}stack_trace'])!,
    );
  }

  @override
  ErrorLogs createAlias(String alias) {
    return ErrorLogs(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const MillisDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt = const MillisDateTimeConverter();
  @override
  bool get dontWriteConstraints => true;
}

class ErrorLogRow extends DataClass implements Insertable<ErrorLogRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source;
  final String errorType;
  final String message;
  final String stackTrace;
  const ErrorLogRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.source,
    required this.errorType,
    required this.message,
    required this.stackTrace,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['created_at'] = Variable<int>(ErrorLogs.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(ErrorLogs.$converterupdatedAt.toSql(updatedAt));
    }
    map['source'] = Variable<String>(source);
    map['error_type'] = Variable<String>(errorType);
    map['message'] = Variable<String>(message);
    map['stack_trace'] = Variable<String>(stackTrace);
    return map;
  }

  ErrorLogsCompanion toCompanion(bool nullToAbsent) {
    return ErrorLogsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      source: Value(source),
      errorType: Value(errorType),
      message: Value(message),
      stackTrace: Value(stackTrace),
    );
  }

  factory ErrorLogRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ErrorLogRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      source: serializer.fromJson<String>(json['source']),
      errorType: serializer.fromJson<String>(json['error_type']),
      message: serializer.fromJson<String>(json['message']),
      stackTrace: serializer.fromJson<String>(json['stack_trace']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'source': serializer.toJson<String>(source),
      'error_type': serializer.toJson<String>(errorType),
      'message': serializer.toJson<String>(message),
      'stack_trace': serializer.toJson<String>(stackTrace),
    };
  }

  ErrorLogRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
    String? errorType,
    String? message,
    String? stackTrace,
  }) => ErrorLogRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    source: source ?? this.source,
    errorType: errorType ?? this.errorType,
    message: message ?? this.message,
    stackTrace: stackTrace ?? this.stackTrace,
  );
  ErrorLogRow copyWithCompanion(ErrorLogsCompanion data) {
    return ErrorLogRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      source: data.source.present ? data.source.value : this.source,
      errorType: data.errorType.present ? data.errorType.value : this.errorType,
      message: data.message.present ? data.message.value : this.message,
      stackTrace: data.stackTrace.present ? data.stackTrace.value : this.stackTrace,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ErrorLogRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source, ')
          ..write('errorType: $errorType, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, source, errorType, message, stackTrace);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ErrorLogRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.source == this.source &&
          other.errorType == this.errorType &&
          other.message == this.message &&
          other.stackTrace == this.stackTrace);
}

class ErrorLogsCompanion extends UpdateCompanion<ErrorLogRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> source;
  final Value<String> errorType;
  final Value<String> message;
  final Value<String> stackTrace;
  final Value<int> rowid;
  const ErrorLogsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.errorType = const Value.absent(),
    this.message = const Value.absent(),
    this.stackTrace = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ErrorLogsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String source,
    required String errorType,
    required String message,
    required String stackTrace,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       source = Value(source),
       errorType = Value(errorType),
       message = Value(message),
       stackTrace = Value(stackTrace);
  static Insertable<ErrorLogRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? source,
    Expression<String>? errorType,
    Expression<String>? message,
    Expression<String>? stackTrace,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (source != null) 'source': source,
      if (errorType != null) 'error_type': errorType,
      if (message != null) 'message': message,
      if (stackTrace != null) 'stack_trace': stackTrace,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ErrorLogsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? source,
    Value<String>? errorType,
    Value<String>? message,
    Value<String>? stackTrace,
    Value<int>? rowid,
  }) {
    return ErrorLogsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      errorType: errorType ?? this.errorType,
      message: message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(ErrorLogs.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(ErrorLogs.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (errorType.present) {
      map['error_type'] = Variable<String>(errorType.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (stackTrace.present) {
      map['stack_trace'] = Variable<String>(stackTrace.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ErrorLogsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source, ')
          ..write('errorType: $errorType, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Contents extends Table with TableInfo<Contents, ContentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Contents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(Contents.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(Contents.$converterupdatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> storedAt = GeneratedColumn<int>(
    'stored_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(Contents.$converterstoredAt);
  static const VerificationMeta _signatureIdMeta = const VerificationMeta('signatureId');
  late final GeneratedColumn<String> signatureId = GeneratedColumn<String>(
    'signature_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  late final GeneratedColumn<int> origin = GeneratedColumn<int>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bounceMeta = const VerificationMeta('bounce');
  late final GeneratedColumn<int> bounce = GeneratedColumn<int>(
    'bounce',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _searchTitleMeta = const VerificationMeta('searchTitle');
  late final GeneratedColumn<String> searchTitle = GeneratedColumn<String>(
    'search_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _flairMeta = const VerificationMeta('flair');
  late final GeneratedColumn<String> flair = GeneratedColumn<String>(
    'flair',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sizeInBytesMeta = const VerificationMeta('sizeInBytes');
  late final GeneratedColumn<int> sizeInBytes = GeneratedColumn<int>(
    'size_in_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _ogImageUrlMeta = const VerificationMeta('ogImageUrl');
  late final GeneratedColumn<String> ogImageUrl = GeneratedColumn<String>(
    'og_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ogTitleMeta = const VerificationMeta('ogTitle');
  late final GeneratedColumn<String> ogTitle = GeneratedColumn<String>(
    'og_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ogDescriptionMeta = const VerificationMeta('ogDescription');
  late final GeneratedColumn<String> ogDescription = GeneratedColumn<String>(
    'og_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _broadcastScoreMeta = const VerificationMeta('broadcastScore');
  late final GeneratedColumn<double> broadcastScore = GeneratedColumn<double>(
    'broadcast_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _survivalScoreMeta = const VerificationMeta('survivalScore');
  late final GeneratedColumn<double> survivalScore = GeneratedColumn<double>(
    'survival_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _displayScoreMeta = const VerificationMeta('displayScore');
  late final GeneratedColumn<double> displayScore = GeneratedColumn<double>(
    'display_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<List<int>, String> tagValues = GeneratedColumn<String>(
    'tag_values',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<int>>(Contents.$convertertagValues);
  late final GeneratedColumnWithTypeConverter<List<String>, String> mediaUrls = GeneratedColumn<String>(
    'media_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<String>>(Contents.$convertermediaUrls);
  late final GeneratedColumnWithTypeConverter<List<int>, String> mediaKinds = GeneratedColumn<String>(
    'media_kinds',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<int>>(Contents.$convertermediaKinds);
  static const VerificationMeta _drawingDataMeta = const VerificationMeta('drawingData');
  late final GeneratedColumn<Uint8List> drawingData = GeneratedColumn<Uint8List>(
    'drawing_data',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    storedAt,
    signatureId,
    type,
    origin,
    bounce,
    title,
    searchTitle,
    body,
    url,
    flair,
    sizeInBytes,
    ogImageUrl,
    ogTitle,
    ogDescription,
    broadcastScore,
    survivalScore,
    displayScore,
    tagValues,
    mediaUrls,
    mediaKinds,
    drawingData,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contents';
  @override
  VerificationContext validateIntegrity(Insertable<ContentRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('signature_id')) {
      context.handle(_signatureIdMeta, signatureId.isAcceptableOrUnknown(data['signature_id']!, _signatureIdMeta));
    } else if (isInserting) {
      context.missing(_signatureIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(_originMeta, origin.isAcceptableOrUnknown(data['origin']!, _originMeta));
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('bounce')) {
      context.handle(_bounceMeta, bounce.isAcceptableOrUnknown(data['bounce']!, _bounceMeta));
    } else if (isInserting) {
      context.missing(_bounceMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('search_title')) {
      context.handle(_searchTitleMeta, searchTitle.isAcceptableOrUnknown(data['search_title']!, _searchTitleMeta));
    } else if (isInserting) {
      context.missing(_searchTitleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('url')) {
      context.handle(_urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('flair')) {
      context.handle(_flairMeta, flair.isAcceptableOrUnknown(data['flair']!, _flairMeta));
    } else if (isInserting) {
      context.missing(_flairMeta);
    }
    if (data.containsKey('size_in_bytes')) {
      context.handle(_sizeInBytesMeta, sizeInBytes.isAcceptableOrUnknown(data['size_in_bytes']!, _sizeInBytesMeta));
    } else if (isInserting) {
      context.missing(_sizeInBytesMeta);
    }
    if (data.containsKey('og_image_url')) {
      context.handle(_ogImageUrlMeta, ogImageUrl.isAcceptableOrUnknown(data['og_image_url']!, _ogImageUrlMeta));
    }
    if (data.containsKey('og_title')) {
      context.handle(_ogTitleMeta, ogTitle.isAcceptableOrUnknown(data['og_title']!, _ogTitleMeta));
    }
    if (data.containsKey('og_description')) {
      context.handle(
        _ogDescriptionMeta,
        ogDescription.isAcceptableOrUnknown(data['og_description']!, _ogDescriptionMeta),
      );
    }
    if (data.containsKey('broadcast_score')) {
      context.handle(
        _broadcastScoreMeta,
        broadcastScore.isAcceptableOrUnknown(data['broadcast_score']!, _broadcastScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_broadcastScoreMeta);
    }
    if (data.containsKey('survival_score')) {
      context.handle(
        _survivalScoreMeta,
        survivalScore.isAcceptableOrUnknown(data['survival_score']!, _survivalScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_survivalScoreMeta);
    }
    if (data.containsKey('display_score')) {
      context.handle(_displayScoreMeta, displayScore.isAcceptableOrUnknown(data['display_score']!, _displayScoreMeta));
    } else if (isInserting) {
      context.missing(_displayScoreMeta);
    }
    if (data.containsKey('drawing_data')) {
      context.handle(_drawingDataMeta, drawingData.isAcceptableOrUnknown(data['drawing_data']!, _drawingDataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: Contents.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: Contents.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      storedAt: Contents.$converterstoredAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}stored_at'])!,
      ),
      signatureId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}signature_id'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}type'])!,
      origin: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}origin'])!,
      bounce: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bounce'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title']),
      searchTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}search_title'])!,
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}body']),
      url: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}url']),
      flair: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}flair'])!,
      sizeInBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size_in_bytes'])!,
      ogImageUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}og_image_url']),
      ogTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}og_title']),
      ogDescription: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}og_description']),
      broadcastScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}broadcast_score'],
      )!,
      survivalScore: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}survival_score'])!,
      displayScore: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}display_score'])!,
      tagValues: Contents.$convertertagValues.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tag_values'])!,
      ),
      mediaUrls: Contents.$convertermediaUrls.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}media_urls'])!,
      ),
      mediaKinds: Contents.$convertermediaKinds.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}media_kinds'])!,
      ),
      drawingData: attachedDatabase.typeMapping.read(DriftSqlType.blob, data['${effectivePrefix}drawing_data']),
    );
  }

  @override
  Contents createAlias(String alias) {
    return Contents(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const MillisDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt = const MillisDateTimeConverter();
  static TypeConverter<DateTime, int> $converterstoredAt = const MillisDateTimeConverter();
  static TypeConverter<List<int>, String> $convertertagValues = const IntListConverter();
  static TypeConverter<List<String>, String> $convertermediaUrls = const StringListConverter();
  static TypeConverter<List<int>, String> $convertermediaKinds = const IntListConverter();
  @override
  bool get dontWriteConstraints => true;
}

class ContentRow extends DataClass implements Insertable<ContentRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Date d'enregistrement sur ce téléphone, à ne pas confondre avec [created_at], la date de l'auteur d'origine : le
  /// fil d'accueil s'en sert pour figer les contenus d'une session de lecture.
  final DateTime storedAt;

  /// Pas de clé étrangère : un contenu peut être anonyme, ou signé par la signature locale avant qu'elle existe.
  final String signatureId;
  final int type;
  final int origin;
  final int bounce;
  final String? title;

  /// Titre en minuscules, calculé en Dart à l'écriture : la recherche y cherche la saisie sans dépendre de `lower()`
  /// de SQLite, qui ignore les lettres non ASCII.
  final String searchTitle;
  final String? body;
  final String? url;
  final String flair;
  final int sizeInBytes;
  final String? ogImageUrl;
  final String? ogTitle;
  final String? ogDescription;
  final double broadcastScore;
  final double survivalScore;
  final double displayScore;
  final List<int> tagValues;
  final List<String> mediaUrls;
  final List<int> mediaKinds;

  /// Dernière colonne : SQLite ne lit les pages de débordement d'un gros dessin que si la requête demande cette colonne.
  final Uint8List? drawingData;
  const ContentRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.storedAt,
    required this.signatureId,
    required this.type,
    required this.origin,
    required this.bounce,
    this.title,
    required this.searchTitle,
    this.body,
    this.url,
    required this.flair,
    required this.sizeInBytes,
    this.ogImageUrl,
    this.ogTitle,
    this.ogDescription,
    required this.broadcastScore,
    required this.survivalScore,
    required this.displayScore,
    required this.tagValues,
    required this.mediaUrls,
    required this.mediaKinds,
    this.drawingData,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['created_at'] = Variable<int>(Contents.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(Contents.$converterupdatedAt.toSql(updatedAt));
    }
    {
      map['stored_at'] = Variable<int>(Contents.$converterstoredAt.toSql(storedAt));
    }
    map['signature_id'] = Variable<String>(signatureId);
    map['type'] = Variable<int>(type);
    map['origin'] = Variable<int>(origin);
    map['bounce'] = Variable<int>(bounce);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['search_title'] = Variable<String>(searchTitle);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['flair'] = Variable<String>(flair);
    map['size_in_bytes'] = Variable<int>(sizeInBytes);
    if (!nullToAbsent || ogImageUrl != null) {
      map['og_image_url'] = Variable<String>(ogImageUrl);
    }
    if (!nullToAbsent || ogTitle != null) {
      map['og_title'] = Variable<String>(ogTitle);
    }
    if (!nullToAbsent || ogDescription != null) {
      map['og_description'] = Variable<String>(ogDescription);
    }
    map['broadcast_score'] = Variable<double>(broadcastScore);
    map['survival_score'] = Variable<double>(survivalScore);
    map['display_score'] = Variable<double>(displayScore);
    {
      map['tag_values'] = Variable<String>(Contents.$convertertagValues.toSql(tagValues));
    }
    {
      map['media_urls'] = Variable<String>(Contents.$convertermediaUrls.toSql(mediaUrls));
    }
    {
      map['media_kinds'] = Variable<String>(Contents.$convertermediaKinds.toSql(mediaKinds));
    }
    if (!nullToAbsent || drawingData != null) {
      map['drawing_data'] = Variable<Uint8List>(drawingData);
    }
    return map;
  }

  ContentsCompanion toCompanion(bool nullToAbsent) {
    return ContentsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      storedAt: Value(storedAt),
      signatureId: Value(signatureId),
      type: Value(type),
      origin: Value(origin),
      bounce: Value(bounce),
      title: title == null && nullToAbsent ? const Value.absent() : Value(title),
      searchTitle: Value(searchTitle),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      flair: Value(flair),
      sizeInBytes: Value(sizeInBytes),
      ogImageUrl: ogImageUrl == null && nullToAbsent ? const Value.absent() : Value(ogImageUrl),
      ogTitle: ogTitle == null && nullToAbsent ? const Value.absent() : Value(ogTitle),
      ogDescription: ogDescription == null && nullToAbsent ? const Value.absent() : Value(ogDescription),
      broadcastScore: Value(broadcastScore),
      survivalScore: Value(survivalScore),
      displayScore: Value(displayScore),
      tagValues: Value(tagValues),
      mediaUrls: Value(mediaUrls),
      mediaKinds: Value(mediaKinds),
      drawingData: drawingData == null && nullToAbsent ? const Value.absent() : Value(drawingData),
    );
  }

  factory ContentRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      storedAt: serializer.fromJson<DateTime>(json['stored_at']),
      signatureId: serializer.fromJson<String>(json['signature_id']),
      type: serializer.fromJson<int>(json['type']),
      origin: serializer.fromJson<int>(json['origin']),
      bounce: serializer.fromJson<int>(json['bounce']),
      title: serializer.fromJson<String?>(json['title']),
      searchTitle: serializer.fromJson<String>(json['search_title']),
      body: serializer.fromJson<String?>(json['body']),
      url: serializer.fromJson<String?>(json['url']),
      flair: serializer.fromJson<String>(json['flair']),
      sizeInBytes: serializer.fromJson<int>(json['size_in_bytes']),
      ogImageUrl: serializer.fromJson<String?>(json['og_image_url']),
      ogTitle: serializer.fromJson<String?>(json['og_title']),
      ogDescription: serializer.fromJson<String?>(json['og_description']),
      broadcastScore: serializer.fromJson<double>(json['broadcast_score']),
      survivalScore: serializer.fromJson<double>(json['survival_score']),
      displayScore: serializer.fromJson<double>(json['display_score']),
      tagValues: serializer.fromJson<List<int>>(json['tag_values']),
      mediaUrls: serializer.fromJson<List<String>>(json['media_urls']),
      mediaKinds: serializer.fromJson<List<int>>(json['media_kinds']),
      drawingData: serializer.fromJson<Uint8List?>(json['drawing_data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'stored_at': serializer.toJson<DateTime>(storedAt),
      'signature_id': serializer.toJson<String>(signatureId),
      'type': serializer.toJson<int>(type),
      'origin': serializer.toJson<int>(origin),
      'bounce': serializer.toJson<int>(bounce),
      'title': serializer.toJson<String?>(title),
      'search_title': serializer.toJson<String>(searchTitle),
      'body': serializer.toJson<String?>(body),
      'url': serializer.toJson<String?>(url),
      'flair': serializer.toJson<String>(flair),
      'size_in_bytes': serializer.toJson<int>(sizeInBytes),
      'og_image_url': serializer.toJson<String?>(ogImageUrl),
      'og_title': serializer.toJson<String?>(ogTitle),
      'og_description': serializer.toJson<String?>(ogDescription),
      'broadcast_score': serializer.toJson<double>(broadcastScore),
      'survival_score': serializer.toJson<double>(survivalScore),
      'display_score': serializer.toJson<double>(displayScore),
      'tag_values': serializer.toJson<List<int>>(tagValues),
      'media_urls': serializer.toJson<List<String>>(mediaUrls),
      'media_kinds': serializer.toJson<List<int>>(mediaKinds),
      'drawing_data': serializer.toJson<Uint8List?>(drawingData),
    };
  }

  ContentRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? storedAt,
    String? signatureId,
    int? type,
    int? origin,
    int? bounce,
    Value<String?> title = const Value.absent(),
    String? searchTitle,
    Value<String?> body = const Value.absent(),
    Value<String?> url = const Value.absent(),
    String? flair,
    int? sizeInBytes,
    Value<String?> ogImageUrl = const Value.absent(),
    Value<String?> ogTitle = const Value.absent(),
    Value<String?> ogDescription = const Value.absent(),
    double? broadcastScore,
    double? survivalScore,
    double? displayScore,
    List<int>? tagValues,
    List<String>? mediaUrls,
    List<int>? mediaKinds,
    Value<Uint8List?> drawingData = const Value.absent(),
  }) => ContentRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    storedAt: storedAt ?? this.storedAt,
    signatureId: signatureId ?? this.signatureId,
    type: type ?? this.type,
    origin: origin ?? this.origin,
    bounce: bounce ?? this.bounce,
    title: title.present ? title.value : this.title,
    searchTitle: searchTitle ?? this.searchTitle,
    body: body.present ? body.value : this.body,
    url: url.present ? url.value : this.url,
    flair: flair ?? this.flair,
    sizeInBytes: sizeInBytes ?? this.sizeInBytes,
    ogImageUrl: ogImageUrl.present ? ogImageUrl.value : this.ogImageUrl,
    ogTitle: ogTitle.present ? ogTitle.value : this.ogTitle,
    ogDescription: ogDescription.present ? ogDescription.value : this.ogDescription,
    broadcastScore: broadcastScore ?? this.broadcastScore,
    survivalScore: survivalScore ?? this.survivalScore,
    displayScore: displayScore ?? this.displayScore,
    tagValues: tagValues ?? this.tagValues,
    mediaUrls: mediaUrls ?? this.mediaUrls,
    mediaKinds: mediaKinds ?? this.mediaKinds,
    drawingData: drawingData.present ? drawingData.value : this.drawingData,
  );
  ContentRow copyWithCompanion(ContentsCompanion data) {
    return ContentRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      storedAt: data.storedAt.present ? data.storedAt.value : this.storedAt,
      signatureId: data.signatureId.present ? data.signatureId.value : this.signatureId,
      type: data.type.present ? data.type.value : this.type,
      origin: data.origin.present ? data.origin.value : this.origin,
      bounce: data.bounce.present ? data.bounce.value : this.bounce,
      title: data.title.present ? data.title.value : this.title,
      searchTitle: data.searchTitle.present ? data.searchTitle.value : this.searchTitle,
      body: data.body.present ? data.body.value : this.body,
      url: data.url.present ? data.url.value : this.url,
      flair: data.flair.present ? data.flair.value : this.flair,
      sizeInBytes: data.sizeInBytes.present ? data.sizeInBytes.value : this.sizeInBytes,
      ogImageUrl: data.ogImageUrl.present ? data.ogImageUrl.value : this.ogImageUrl,
      ogTitle: data.ogTitle.present ? data.ogTitle.value : this.ogTitle,
      ogDescription: data.ogDescription.present ? data.ogDescription.value : this.ogDescription,
      broadcastScore: data.broadcastScore.present ? data.broadcastScore.value : this.broadcastScore,
      survivalScore: data.survivalScore.present ? data.survivalScore.value : this.survivalScore,
      displayScore: data.displayScore.present ? data.displayScore.value : this.displayScore,
      tagValues: data.tagValues.present ? data.tagValues.value : this.tagValues,
      mediaUrls: data.mediaUrls.present ? data.mediaUrls.value : this.mediaUrls,
      mediaKinds: data.mediaKinds.present ? data.mediaKinds.value : this.mediaKinds,
      drawingData: data.drawingData.present ? data.drawingData.value : this.drawingData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('storedAt: $storedAt, ')
          ..write('signatureId: $signatureId, ')
          ..write('type: $type, ')
          ..write('origin: $origin, ')
          ..write('bounce: $bounce, ')
          ..write('title: $title, ')
          ..write('searchTitle: $searchTitle, ')
          ..write('body: $body, ')
          ..write('url: $url, ')
          ..write('flair: $flair, ')
          ..write('sizeInBytes: $sizeInBytes, ')
          ..write('ogImageUrl: $ogImageUrl, ')
          ..write('ogTitle: $ogTitle, ')
          ..write('ogDescription: $ogDescription, ')
          ..write('broadcastScore: $broadcastScore, ')
          ..write('survivalScore: $survivalScore, ')
          ..write('displayScore: $displayScore, ')
          ..write('tagValues: $tagValues, ')
          ..write('mediaUrls: $mediaUrls, ')
          ..write('mediaKinds: $mediaKinds, ')
          ..write('drawingData: $drawingData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    storedAt,
    signatureId,
    type,
    origin,
    bounce,
    title,
    searchTitle,
    body,
    url,
    flair,
    sizeInBytes,
    ogImageUrl,
    ogTitle,
    ogDescription,
    broadcastScore,
    survivalScore,
    displayScore,
    tagValues,
    mediaUrls,
    mediaKinds,
    $driftBlobEquality.hash(drawingData),
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.storedAt == this.storedAt &&
          other.signatureId == this.signatureId &&
          other.type == this.type &&
          other.origin == this.origin &&
          other.bounce == this.bounce &&
          other.title == this.title &&
          other.searchTitle == this.searchTitle &&
          other.body == this.body &&
          other.url == this.url &&
          other.flair == this.flair &&
          other.sizeInBytes == this.sizeInBytes &&
          other.ogImageUrl == this.ogImageUrl &&
          other.ogTitle == this.ogTitle &&
          other.ogDescription == this.ogDescription &&
          other.broadcastScore == this.broadcastScore &&
          other.survivalScore == this.survivalScore &&
          other.displayScore == this.displayScore &&
          other.tagValues == this.tagValues &&
          other.mediaUrls == this.mediaUrls &&
          other.mediaKinds == this.mediaKinds &&
          $driftBlobEquality.equals(other.drawingData, this.drawingData));
}

class ContentsCompanion extends UpdateCompanion<ContentRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> storedAt;
  final Value<String> signatureId;
  final Value<int> type;
  final Value<int> origin;
  final Value<int> bounce;
  final Value<String?> title;
  final Value<String> searchTitle;
  final Value<String?> body;
  final Value<String?> url;
  final Value<String> flair;
  final Value<int> sizeInBytes;
  final Value<String?> ogImageUrl;
  final Value<String?> ogTitle;
  final Value<String?> ogDescription;
  final Value<double> broadcastScore;
  final Value<double> survivalScore;
  final Value<double> displayScore;
  final Value<List<int>> tagValues;
  final Value<List<String>> mediaUrls;
  final Value<List<int>> mediaKinds;
  final Value<Uint8List?> drawingData;
  final Value<int> rowid;
  const ContentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.storedAt = const Value.absent(),
    this.signatureId = const Value.absent(),
    this.type = const Value.absent(),
    this.origin = const Value.absent(),
    this.bounce = const Value.absent(),
    this.title = const Value.absent(),
    this.searchTitle = const Value.absent(),
    this.body = const Value.absent(),
    this.url = const Value.absent(),
    this.flair = const Value.absent(),
    this.sizeInBytes = const Value.absent(),
    this.ogImageUrl = const Value.absent(),
    this.ogTitle = const Value.absent(),
    this.ogDescription = const Value.absent(),
    this.broadcastScore = const Value.absent(),
    this.survivalScore = const Value.absent(),
    this.displayScore = const Value.absent(),
    this.tagValues = const Value.absent(),
    this.mediaUrls = const Value.absent(),
    this.mediaKinds = const Value.absent(),
    this.drawingData = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime storedAt,
    required String signatureId,
    required int type,
    required int origin,
    required int bounce,
    this.title = const Value.absent(),
    required String searchTitle,
    this.body = const Value.absent(),
    this.url = const Value.absent(),
    required String flair,
    required int sizeInBytes,
    this.ogImageUrl = const Value.absent(),
    this.ogTitle = const Value.absent(),
    this.ogDescription = const Value.absent(),
    required double broadcastScore,
    required double survivalScore,
    required double displayScore,
    required List<int> tagValues,
    required List<String> mediaUrls,
    required List<int> mediaKinds,
    this.drawingData = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       storedAt = Value(storedAt),
       signatureId = Value(signatureId),
       type = Value(type),
       origin = Value(origin),
       bounce = Value(bounce),
       searchTitle = Value(searchTitle),
       flair = Value(flair),
       sizeInBytes = Value(sizeInBytes),
       broadcastScore = Value(broadcastScore),
       survivalScore = Value(survivalScore),
       displayScore = Value(displayScore),
       tagValues = Value(tagValues),
       mediaUrls = Value(mediaUrls),
       mediaKinds = Value(mediaKinds);
  static Insertable<ContentRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? storedAt,
    Expression<String>? signatureId,
    Expression<int>? type,
    Expression<int>? origin,
    Expression<int>? bounce,
    Expression<String>? title,
    Expression<String>? searchTitle,
    Expression<String>? body,
    Expression<String>? url,
    Expression<String>? flair,
    Expression<int>? sizeInBytes,
    Expression<String>? ogImageUrl,
    Expression<String>? ogTitle,
    Expression<String>? ogDescription,
    Expression<double>? broadcastScore,
    Expression<double>? survivalScore,
    Expression<double>? displayScore,
    Expression<String>? tagValues,
    Expression<String>? mediaUrls,
    Expression<String>? mediaKinds,
    Expression<Uint8List>? drawingData,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (storedAt != null) 'stored_at': storedAt,
      if (signatureId != null) 'signature_id': signatureId,
      if (type != null) 'type': type,
      if (origin != null) 'origin': origin,
      if (bounce != null) 'bounce': bounce,
      if (title != null) 'title': title,
      if (searchTitle != null) 'search_title': searchTitle,
      if (body != null) 'body': body,
      if (url != null) 'url': url,
      if (flair != null) 'flair': flair,
      if (sizeInBytes != null) 'size_in_bytes': sizeInBytes,
      if (ogImageUrl != null) 'og_image_url': ogImageUrl,
      if (ogTitle != null) 'og_title': ogTitle,
      if (ogDescription != null) 'og_description': ogDescription,
      if (broadcastScore != null) 'broadcast_score': broadcastScore,
      if (survivalScore != null) 'survival_score': survivalScore,
      if (displayScore != null) 'display_score': displayScore,
      if (tagValues != null) 'tag_values': tagValues,
      if (mediaUrls != null) 'media_urls': mediaUrls,
      if (mediaKinds != null) 'media_kinds': mediaKinds,
      if (drawingData != null) 'drawing_data': drawingData,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? storedAt,
    Value<String>? signatureId,
    Value<int>? type,
    Value<int>? origin,
    Value<int>? bounce,
    Value<String?>? title,
    Value<String>? searchTitle,
    Value<String?>? body,
    Value<String?>? url,
    Value<String>? flair,
    Value<int>? sizeInBytes,
    Value<String?>? ogImageUrl,
    Value<String?>? ogTitle,
    Value<String?>? ogDescription,
    Value<double>? broadcastScore,
    Value<double>? survivalScore,
    Value<double>? displayScore,
    Value<List<int>>? tagValues,
    Value<List<String>>? mediaUrls,
    Value<List<int>>? mediaKinds,
    Value<Uint8List?>? drawingData,
    Value<int>? rowid,
  }) {
    return ContentsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      storedAt: storedAt ?? this.storedAt,
      signatureId: signatureId ?? this.signatureId,
      type: type ?? this.type,
      origin: origin ?? this.origin,
      bounce: bounce ?? this.bounce,
      title: title ?? this.title,
      searchTitle: searchTitle ?? this.searchTitle,
      body: body ?? this.body,
      url: url ?? this.url,
      flair: flair ?? this.flair,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      ogImageUrl: ogImageUrl ?? this.ogImageUrl,
      ogTitle: ogTitle ?? this.ogTitle,
      ogDescription: ogDescription ?? this.ogDescription,
      broadcastScore: broadcastScore ?? this.broadcastScore,
      survivalScore: survivalScore ?? this.survivalScore,
      displayScore: displayScore ?? this.displayScore,
      tagValues: tagValues ?? this.tagValues,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaKinds: mediaKinds ?? this.mediaKinds,
      drawingData: drawingData ?? this.drawingData,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(Contents.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(Contents.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (storedAt.present) {
      map['stored_at'] = Variable<int>(Contents.$converterstoredAt.toSql(storedAt.value));
    }
    if (signatureId.present) {
      map['signature_id'] = Variable<String>(signatureId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (origin.present) {
      map['origin'] = Variable<int>(origin.value);
    }
    if (bounce.present) {
      map['bounce'] = Variable<int>(bounce.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (searchTitle.present) {
      map['search_title'] = Variable<String>(searchTitle.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (flair.present) {
      map['flair'] = Variable<String>(flair.value);
    }
    if (sizeInBytes.present) {
      map['size_in_bytes'] = Variable<int>(sizeInBytes.value);
    }
    if (ogImageUrl.present) {
      map['og_image_url'] = Variable<String>(ogImageUrl.value);
    }
    if (ogTitle.present) {
      map['og_title'] = Variable<String>(ogTitle.value);
    }
    if (ogDescription.present) {
      map['og_description'] = Variable<String>(ogDescription.value);
    }
    if (broadcastScore.present) {
      map['broadcast_score'] = Variable<double>(broadcastScore.value);
    }
    if (survivalScore.present) {
      map['survival_score'] = Variable<double>(survivalScore.value);
    }
    if (displayScore.present) {
      map['display_score'] = Variable<double>(displayScore.value);
    }
    if (tagValues.present) {
      map['tag_values'] = Variable<String>(Contents.$convertertagValues.toSql(tagValues.value));
    }
    if (mediaUrls.present) {
      map['media_urls'] = Variable<String>(Contents.$convertermediaUrls.toSql(mediaUrls.value));
    }
    if (mediaKinds.present) {
      map['media_kinds'] = Variable<String>(Contents.$convertermediaKinds.toSql(mediaKinds.value));
    }
    if (drawingData.present) {
      map['drawing_data'] = Variable<Uint8List>(drawingData.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('storedAt: $storedAt, ')
          ..write('signatureId: $signatureId, ')
          ..write('type: $type, ')
          ..write('origin: $origin, ')
          ..write('bounce: $bounce, ')
          ..write('title: $title, ')
          ..write('searchTitle: $searchTitle, ')
          ..write('body: $body, ')
          ..write('url: $url, ')
          ..write('flair: $flair, ')
          ..write('sizeInBytes: $sizeInBytes, ')
          ..write('ogImageUrl: $ogImageUrl, ')
          ..write('ogTitle: $ogTitle, ')
          ..write('ogDescription: $ogDescription, ')
          ..write('broadcastScore: $broadcastScore, ')
          ..write('survivalScore: $survivalScore, ')
          ..write('displayScore: $displayScore, ')
          ..write('tagValues: $tagValues, ')
          ..write('mediaUrls: $mediaUrls, ')
          ..write('mediaKinds: $mediaKinds, ')
          ..write('drawingData: $drawingData, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ViewedContents extends Table with TableInfo<ViewedContents, ViewedContentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ViewedContents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES contents(id)ON DELETE CASCADE',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(ViewedContents.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(ViewedContents.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'viewed_contents';
  @override
  VerificationContext validateIntegrity(Insertable<ViewedContentRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ViewedContentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ViewedContentRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: ViewedContents.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: ViewedContents.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
    );
  }

  @override
  ViewedContents createAlias(String alias) {
    return ViewedContents(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const MillisDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt = const MillisDateTimeConverter();
  @override
  bool get dontWriteConstraints => true;
}

class ViewedContentRow extends DataClass implements Insertable<ViewedContentRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ViewedContentRow({required this.id, required this.createdAt, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['created_at'] = Variable<int>(ViewedContents.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(ViewedContents.$converterupdatedAt.toSql(updatedAt));
    }
    return map;
  }

  ViewedContentsCompanion toCompanion(bool nullToAbsent) {
    return ViewedContentsCompanion(id: Value(id), createdAt: Value(createdAt), updatedAt: Value(updatedAt));
  }

  factory ViewedContentRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ViewedContentRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ViewedContentRow copyWith({String? id, DateTime? createdAt, DateTime? updatedAt}) => ViewedContentRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ViewedContentRow copyWithCompanion(ViewedContentsCompanion data) {
    return ViewedContentRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ViewedContentRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ViewedContentRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ViewedContentsCompanion extends UpdateCompanion<ViewedContentRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ViewedContentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ViewedContentsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ViewedContentRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ViewedContentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ViewedContentsCompanion(
      id: id ?? this.id,
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
    if (createdAt.present) {
      map['created_at'] = Variable<int>(ViewedContents.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(ViewedContents.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ViewedContentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TrustSettingsStore extends Table with TableInfo<TrustSettingsStore, TrustSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TrustSettingsStore(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final GeneratedColumnWithTypeConverter<List<String>, String> mediaTrustedPatterns = GeneratedColumn<String>(
    'media_trusted_patterns',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<String>>(TrustSettingsStore.$convertermediaTrustedPatterns);
  late final GeneratedColumnWithTypeConverter<List<String>, String> mediaGreyPatterns = GeneratedColumn<String>(
    'media_grey_patterns',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<String>>(TrustSettingsStore.$convertermediaGreyPatterns);
  late final GeneratedColumnWithTypeConverter<List<String>, String> linkTrustedPatterns = GeneratedColumn<String>(
    'link_trusted_patterns',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<String>>(TrustSettingsStore.$converterlinkTrustedPatterns);
  late final GeneratedColumnWithTypeConverter<List<String>, String> linkGreyPatterns = GeneratedColumn<String>(
    'link_grey_patterns',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<String>>(TrustSettingsStore.$converterlinkGreyPatterns);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaTrustedPatterns,
    mediaGreyPatterns,
    linkTrustedPatterns,
    linkGreyPatterns,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trust_settings_store';
  @override
  VerificationContext validateIntegrity(Insertable<TrustSettingsRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrustSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrustSettingsRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      mediaTrustedPatterns: TrustSettingsStore.$convertermediaTrustedPatterns.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}media_trusted_patterns'])!,
      ),
      mediaGreyPatterns: TrustSettingsStore.$convertermediaGreyPatterns.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}media_grey_patterns'])!,
      ),
      linkTrustedPatterns: TrustSettingsStore.$converterlinkTrustedPatterns.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}link_trusted_patterns'])!,
      ),
      linkGreyPatterns: TrustSettingsStore.$converterlinkGreyPatterns.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}link_grey_patterns'])!,
      ),
    );
  }

  @override
  TrustSettingsStore createAlias(String alias) {
    return TrustSettingsStore(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertermediaTrustedPatterns = const StringListConverter();
  static TypeConverter<List<String>, String> $convertermediaGreyPatterns = const StringListConverter();
  static TypeConverter<List<String>, String> $converterlinkTrustedPatterns = const StringListConverter();
  static TypeConverter<List<String>, String> $converterlinkGreyPatterns = const StringListConverter();
  @override
  bool get dontWriteConstraints => true;
}

class TrustSettingsRow extends DataClass implements Insertable<TrustSettingsRow> {
  final int id;
  final List<String> mediaTrustedPatterns;
  final List<String> mediaGreyPatterns;
  final List<String> linkTrustedPatterns;
  final List<String> linkGreyPatterns;
  const TrustSettingsRow({
    required this.id,
    required this.mediaTrustedPatterns,
    required this.mediaGreyPatterns,
    required this.linkTrustedPatterns,
    required this.linkGreyPatterns,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['media_trusted_patterns'] = Variable<String>(
        TrustSettingsStore.$convertermediaTrustedPatterns.toSql(mediaTrustedPatterns),
      );
    }
    {
      map['media_grey_patterns'] = Variable<String>(
        TrustSettingsStore.$convertermediaGreyPatterns.toSql(mediaGreyPatterns),
      );
    }
    {
      map['link_trusted_patterns'] = Variable<String>(
        TrustSettingsStore.$converterlinkTrustedPatterns.toSql(linkTrustedPatterns),
      );
    }
    {
      map['link_grey_patterns'] = Variable<String>(
        TrustSettingsStore.$converterlinkGreyPatterns.toSql(linkGreyPatterns),
      );
    }
    return map;
  }

  TrustSettingsStoreCompanion toCompanion(bool nullToAbsent) {
    return TrustSettingsStoreCompanion(
      id: Value(id),
      mediaTrustedPatterns: Value(mediaTrustedPatterns),
      mediaGreyPatterns: Value(mediaGreyPatterns),
      linkTrustedPatterns: Value(linkTrustedPatterns),
      linkGreyPatterns: Value(linkGreyPatterns),
    );
  }

  factory TrustSettingsRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrustSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      mediaTrustedPatterns: serializer.fromJson<List<String>>(json['media_trusted_patterns']),
      mediaGreyPatterns: serializer.fromJson<List<String>>(json['media_grey_patterns']),
      linkTrustedPatterns: serializer.fromJson<List<String>>(json['link_trusted_patterns']),
      linkGreyPatterns: serializer.fromJson<List<String>>(json['link_grey_patterns']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'media_trusted_patterns': serializer.toJson<List<String>>(mediaTrustedPatterns),
      'media_grey_patterns': serializer.toJson<List<String>>(mediaGreyPatterns),
      'link_trusted_patterns': serializer.toJson<List<String>>(linkTrustedPatterns),
      'link_grey_patterns': serializer.toJson<List<String>>(linkGreyPatterns),
    };
  }

  TrustSettingsRow copyWith({
    int? id,
    List<String>? mediaTrustedPatterns,
    List<String>? mediaGreyPatterns,
    List<String>? linkTrustedPatterns,
    List<String>? linkGreyPatterns,
  }) => TrustSettingsRow(
    id: id ?? this.id,
    mediaTrustedPatterns: mediaTrustedPatterns ?? this.mediaTrustedPatterns,
    mediaGreyPatterns: mediaGreyPatterns ?? this.mediaGreyPatterns,
    linkTrustedPatterns: linkTrustedPatterns ?? this.linkTrustedPatterns,
    linkGreyPatterns: linkGreyPatterns ?? this.linkGreyPatterns,
  );
  TrustSettingsRow copyWithCompanion(TrustSettingsStoreCompanion data) {
    return TrustSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      mediaTrustedPatterns: data.mediaTrustedPatterns.present
          ? data.mediaTrustedPatterns.value
          : this.mediaTrustedPatterns,
      mediaGreyPatterns: data.mediaGreyPatterns.present ? data.mediaGreyPatterns.value : this.mediaGreyPatterns,
      linkTrustedPatterns: data.linkTrustedPatterns.present ? data.linkTrustedPatterns.value : this.linkTrustedPatterns,
      linkGreyPatterns: data.linkGreyPatterns.present ? data.linkGreyPatterns.value : this.linkGreyPatterns,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrustSettingsRow(')
          ..write('id: $id, ')
          ..write('mediaTrustedPatterns: $mediaTrustedPatterns, ')
          ..write('mediaGreyPatterns: $mediaGreyPatterns, ')
          ..write('linkTrustedPatterns: $linkTrustedPatterns, ')
          ..write('linkGreyPatterns: $linkGreyPatterns')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mediaTrustedPatterns, mediaGreyPatterns, linkTrustedPatterns, linkGreyPatterns);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrustSettingsRow &&
          other.id == this.id &&
          other.mediaTrustedPatterns == this.mediaTrustedPatterns &&
          other.mediaGreyPatterns == this.mediaGreyPatterns &&
          other.linkTrustedPatterns == this.linkTrustedPatterns &&
          other.linkGreyPatterns == this.linkGreyPatterns);
}

class TrustSettingsStoreCompanion extends UpdateCompanion<TrustSettingsRow> {
  final Value<int> id;
  final Value<List<String>> mediaTrustedPatterns;
  final Value<List<String>> mediaGreyPatterns;
  final Value<List<String>> linkTrustedPatterns;
  final Value<List<String>> linkGreyPatterns;
  const TrustSettingsStoreCompanion({
    this.id = const Value.absent(),
    this.mediaTrustedPatterns = const Value.absent(),
    this.mediaGreyPatterns = const Value.absent(),
    this.linkTrustedPatterns = const Value.absent(),
    this.linkGreyPatterns = const Value.absent(),
  });
  TrustSettingsStoreCompanion.insert({
    this.id = const Value.absent(),
    required List<String> mediaTrustedPatterns,
    required List<String> mediaGreyPatterns,
    required List<String> linkTrustedPatterns,
    required List<String> linkGreyPatterns,
  }) : mediaTrustedPatterns = Value(mediaTrustedPatterns),
       mediaGreyPatterns = Value(mediaGreyPatterns),
       linkTrustedPatterns = Value(linkTrustedPatterns),
       linkGreyPatterns = Value(linkGreyPatterns);
  static Insertable<TrustSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? mediaTrustedPatterns,
    Expression<String>? mediaGreyPatterns,
    Expression<String>? linkTrustedPatterns,
    Expression<String>? linkGreyPatterns,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaTrustedPatterns != null) 'media_trusted_patterns': mediaTrustedPatterns,
      if (mediaGreyPatterns != null) 'media_grey_patterns': mediaGreyPatterns,
      if (linkTrustedPatterns != null) 'link_trusted_patterns': linkTrustedPatterns,
      if (linkGreyPatterns != null) 'link_grey_patterns': linkGreyPatterns,
    });
  }

  TrustSettingsStoreCompanion copyWith({
    Value<int>? id,
    Value<List<String>>? mediaTrustedPatterns,
    Value<List<String>>? mediaGreyPatterns,
    Value<List<String>>? linkTrustedPatterns,
    Value<List<String>>? linkGreyPatterns,
  }) {
    return TrustSettingsStoreCompanion(
      id: id ?? this.id,
      mediaTrustedPatterns: mediaTrustedPatterns ?? this.mediaTrustedPatterns,
      mediaGreyPatterns: mediaGreyPatterns ?? this.mediaGreyPatterns,
      linkTrustedPatterns: linkTrustedPatterns ?? this.linkTrustedPatterns,
      linkGreyPatterns: linkGreyPatterns ?? this.linkGreyPatterns,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mediaTrustedPatterns.present) {
      map['media_trusted_patterns'] = Variable<String>(
        TrustSettingsStore.$convertermediaTrustedPatterns.toSql(mediaTrustedPatterns.value),
      );
    }
    if (mediaGreyPatterns.present) {
      map['media_grey_patterns'] = Variable<String>(
        TrustSettingsStore.$convertermediaGreyPatterns.toSql(mediaGreyPatterns.value),
      );
    }
    if (linkTrustedPatterns.present) {
      map['link_trusted_patterns'] = Variable<String>(
        TrustSettingsStore.$converterlinkTrustedPatterns.toSql(linkTrustedPatterns.value),
      );
    }
    if (linkGreyPatterns.present) {
      map['link_grey_patterns'] = Variable<String>(
        TrustSettingsStore.$converterlinkGreyPatterns.toSql(linkGreyPatterns.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrustSettingsStoreCompanion(')
          ..write('id: $id, ')
          ..write('mediaTrustedPatterns: $mediaTrustedPatterns, ')
          ..write('mediaGreyPatterns: $mediaGreyPatterns, ')
          ..write('linkTrustedPatterns: $linkTrustedPatterns, ')
          ..write('linkGreyPatterns: $linkGreyPatterns')
          ..write(')'))
        .toString();
  }
}

class StorageSettings extends Table with TableInfo<StorageSettings, StorageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StorageSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _maxSizeInBytesMeta = const VerificationMeta('maxSizeInBytes');
  late final GeneratedColumn<int> maxSizeInBytes = GeneratedColumn<int>(
    'max_size_in_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _strategyMeta = const VerificationMeta('strategy');
  late final GeneratedColumn<int> strategy = GeneratedColumn<int>(
    'strategy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, maxSizeInBytes, strategy];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storage_settings';
  @override
  VerificationContext validateIntegrity(Insertable<StorageRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('max_size_in_bytes')) {
      context.handle(
        _maxSizeInBytesMeta,
        maxSizeInBytes.isAcceptableOrUnknown(data['max_size_in_bytes']!, _maxSizeInBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_maxSizeInBytesMeta);
    }
    if (data.containsKey('strategy')) {
      context.handle(_strategyMeta, strategy.isAcceptableOrUnknown(data['strategy']!, _strategyMeta));
    } else if (isInserting) {
      context.missing(_strategyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StorageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      maxSizeInBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}max_size_in_bytes'])!,
      strategy: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}strategy'])!,
    );
  }

  @override
  StorageSettings createAlias(String alias) {
    return StorageSettings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class StorageRow extends DataClass implements Insertable<StorageRow> {
  final int id;
  final int maxSizeInBytes;
  final int strategy;
  const StorageRow({required this.id, required this.maxSizeInBytes, required this.strategy});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['max_size_in_bytes'] = Variable<int>(maxSizeInBytes);
    map['strategy'] = Variable<int>(strategy);
    return map;
  }

  StorageSettingsCompanion toCompanion(bool nullToAbsent) {
    return StorageSettingsCompanion(id: Value(id), maxSizeInBytes: Value(maxSizeInBytes), strategy: Value(strategy));
  }

  factory StorageRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageRow(
      id: serializer.fromJson<int>(json['id']),
      maxSizeInBytes: serializer.fromJson<int>(json['max_size_in_bytes']),
      strategy: serializer.fromJson<int>(json['strategy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'max_size_in_bytes': serializer.toJson<int>(maxSizeInBytes),
      'strategy': serializer.toJson<int>(strategy),
    };
  }

  StorageRow copyWith({int? id, int? maxSizeInBytes, int? strategy}) => StorageRow(
    id: id ?? this.id,
    maxSizeInBytes: maxSizeInBytes ?? this.maxSizeInBytes,
    strategy: strategy ?? this.strategy,
  );
  StorageRow copyWithCompanion(StorageSettingsCompanion data) {
    return StorageRow(
      id: data.id.present ? data.id.value : this.id,
      maxSizeInBytes: data.maxSizeInBytes.present ? data.maxSizeInBytes.value : this.maxSizeInBytes,
      strategy: data.strategy.present ? data.strategy.value : this.strategy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorageRow(')
          ..write('id: $id, ')
          ..write('maxSizeInBytes: $maxSizeInBytes, ')
          ..write('strategy: $strategy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, maxSizeInBytes, strategy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageRow &&
          other.id == this.id &&
          other.maxSizeInBytes == this.maxSizeInBytes &&
          other.strategy == this.strategy);
}

class StorageSettingsCompanion extends UpdateCompanion<StorageRow> {
  final Value<int> id;
  final Value<int> maxSizeInBytes;
  final Value<int> strategy;
  const StorageSettingsCompanion({
    this.id = const Value.absent(),
    this.maxSizeInBytes = const Value.absent(),
    this.strategy = const Value.absent(),
  });
  StorageSettingsCompanion.insert({this.id = const Value.absent(), required int maxSizeInBytes, required int strategy})
    : maxSizeInBytes = Value(maxSizeInBytes),
      strategy = Value(strategy);
  static Insertable<StorageRow> custom({
    Expression<int>? id,
    Expression<int>? maxSizeInBytes,
    Expression<int>? strategy,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (maxSizeInBytes != null) 'max_size_in_bytes': maxSizeInBytes,
      if (strategy != null) 'strategy': strategy,
    });
  }

  StorageSettingsCompanion copyWith({Value<int>? id, Value<int>? maxSizeInBytes, Value<int>? strategy}) {
    return StorageSettingsCompanion(
      id: id ?? this.id,
      maxSizeInBytes: maxSizeInBytes ?? this.maxSizeInBytes,
      strategy: strategy ?? this.strategy,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (maxSizeInBytes.present) {
      map['max_size_in_bytes'] = Variable<int>(maxSizeInBytes.value);
    }
    if (strategy.present) {
      map['strategy'] = Variable<int>(strategy.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageSettingsCompanion(')
          ..write('id: $id, ')
          ..write('maxSizeInBytes: $maxSizeInBytes, ')
          ..write('strategy: $strategy')
          ..write(')'))
        .toString();
  }
}

class SeenContents extends Table with TableInfo<SeenContents, SeenContentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SeenContents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(SeenContents.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(SeenContents.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seen_contents';
  @override
  VerificationContext validateIntegrity(Insertable<SeenContentRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeenContentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeenContentRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: SeenContents.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: SeenContents.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
    );
  }

  @override
  SeenContents createAlias(String alias) {
    return SeenContents(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const MillisDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt = const MillisDateTimeConverter();
  @override
  bool get dontWriteConstraints => true;
}

class SeenContentRow extends DataClass implements Insertable<SeenContentRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SeenContentRow({required this.id, required this.createdAt, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['created_at'] = Variable<int>(SeenContents.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(SeenContents.$converterupdatedAt.toSql(updatedAt));
    }
    return map;
  }

  SeenContentsCompanion toCompanion(bool nullToAbsent) {
    return SeenContentsCompanion(id: Value(id), createdAt: Value(createdAt), updatedAt: Value(updatedAt));
  }

  factory SeenContentRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeenContentRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SeenContentRow copyWith({String? id, DateTime? createdAt, DateTime? updatedAt}) =>
      SeenContentRow(id: id ?? this.id, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt);
  SeenContentRow copyWithCompanion(SeenContentsCompanion data) {
    return SeenContentRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeenContentRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeenContentRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SeenContentsCompanion extends UpdateCompanion<SeenContentRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SeenContentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeenContentsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SeenContentRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeenContentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SeenContentsCompanion(
      id: id ?? this.id,
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
    if (createdAt.present) {
      map['created_at'] = Variable<int>(SeenContents.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(SeenContents.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeenContentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Reactions extends Table with TableInfo<Reactions, ReactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Reactions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(Reactions.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(Reactions.$converterupdatedAt);
  static const VerificationMeta _contentIdMeta = const VerificationMeta('contentId');
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES contents(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta('authorId');
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<List<String>, String> avatarFrames = GeneratedColumn<String>(
    'avatar_frames',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<List<String>>(Reactions.$converteravatarFrames);
  static const VerificationMeta _bubbleTextMeta = const VerificationMeta('bubbleText');
  late final GeneratedColumn<String> bubbleText = GeneratedColumn<String>(
    'bubble_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _colorArgbMeta = const VerificationMeta('colorArgb');
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ghostSpeedMeta = const VerificationMeta('ghostSpeed');
  late final GeneratedColumn<double> ghostSpeed = GeneratedColumn<double>(
    'ghost_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _avatarFrameSpeedMeta = const VerificationMeta('avatarFrameSpeed');
  late final GeneratedColumn<double> avatarFrameSpeed = GeneratedColumn<double>(
    'avatar_frame_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bubbleFontMeta = const VerificationMeta('bubbleFont');
  late final GeneratedColumn<int> bubbleFont = GeneratedColumn<int>(
    'bubble_font',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    contentId,
    authorId,
    avatarFrames,
    bubbleText,
    colorArgb,
    ghostSpeed,
    avatarFrameSpeed,
    bubbleFont,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reactions';
  @override
  VerificationContext validateIntegrity(Insertable<ReactionRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content_id')) {
      context.handle(_contentIdMeta, contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta));
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(_authorIdMeta, authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta));
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('bubble_text')) {
      context.handle(_bubbleTextMeta, bubbleText.isAcceptableOrUnknown(data['bubble_text']!, _bubbleTextMeta));
    }
    if (data.containsKey('color_argb')) {
      context.handle(_colorArgbMeta, colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta));
    }
    if (data.containsKey('ghost_speed')) {
      context.handle(_ghostSpeedMeta, ghostSpeed.isAcceptableOrUnknown(data['ghost_speed']!, _ghostSpeedMeta));
    } else if (isInserting) {
      context.missing(_ghostSpeedMeta);
    }
    if (data.containsKey('avatar_frame_speed')) {
      context.handle(
        _avatarFrameSpeedMeta,
        avatarFrameSpeed.isAcceptableOrUnknown(data['avatar_frame_speed']!, _avatarFrameSpeedMeta),
      );
    } else if (isInserting) {
      context.missing(_avatarFrameSpeedMeta);
    }
    if (data.containsKey('bubble_font')) {
      context.handle(_bubbleFontMeta, bubbleFont.isAcceptableOrUnknown(data['bubble_font']!, _bubbleFontMeta));
    } else if (isInserting) {
      context.missing(_bubbleFontMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReactionRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: Reactions.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: Reactions.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      contentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content_id'])!,
      authorId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}author_id'])!,
      avatarFrames: Reactions.$converteravatarFrames.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}avatar_frames'])!,
      ),
      bubbleText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}bubble_text']),
      colorArgb: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color_argb']),
      ghostSpeed: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}ghost_speed'])!,
      avatarFrameSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avatar_frame_speed'],
      )!,
      bubbleFont: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bubble_font'])!,
    );
  }

  @override
  Reactions createAlias(String alias) {
    return Reactions(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const MillisDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt = const MillisDateTimeConverter();
  static TypeConverter<List<String>, String> $converteravatarFrames = const StringListConverter();
  @override
  bool get dontWriteConstraints => true;
}

class ReactionRow extends DataClass implements Insertable<ReactionRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String contentId;
  final String authorId;
  final List<String> avatarFrames;
  final String? bubbleText;
  final int? colorArgb;
  final double ghostSpeed;
  final double avatarFrameSpeed;
  final int bubbleFont;
  const ReactionRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.contentId,
    required this.authorId,
    required this.avatarFrames,
    this.bubbleText,
    this.colorArgb,
    required this.ghostSpeed,
    required this.avatarFrameSpeed,
    required this.bubbleFont,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['created_at'] = Variable<int>(Reactions.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(Reactions.$converterupdatedAt.toSql(updatedAt));
    }
    map['content_id'] = Variable<String>(contentId);
    map['author_id'] = Variable<String>(authorId);
    {
      map['avatar_frames'] = Variable<String>(Reactions.$converteravatarFrames.toSql(avatarFrames));
    }
    if (!nullToAbsent || bubbleText != null) {
      map['bubble_text'] = Variable<String>(bubbleText);
    }
    if (!nullToAbsent || colorArgb != null) {
      map['color_argb'] = Variable<int>(colorArgb);
    }
    map['ghost_speed'] = Variable<double>(ghostSpeed);
    map['avatar_frame_speed'] = Variable<double>(avatarFrameSpeed);
    map['bubble_font'] = Variable<int>(bubbleFont);
    return map;
  }

  ReactionsCompanion toCompanion(bool nullToAbsent) {
    return ReactionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      contentId: Value(contentId),
      authorId: Value(authorId),
      avatarFrames: Value(avatarFrames),
      bubbleText: bubbleText == null && nullToAbsent ? const Value.absent() : Value(bubbleText),
      colorArgb: colorArgb == null && nullToAbsent ? const Value.absent() : Value(colorArgb),
      ghostSpeed: Value(ghostSpeed),
      avatarFrameSpeed: Value(avatarFrameSpeed),
      bubbleFont: Value(bubbleFont),
    );
  }

  factory ReactionRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReactionRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      contentId: serializer.fromJson<String>(json['content_id']),
      authorId: serializer.fromJson<String>(json['author_id']),
      avatarFrames: serializer.fromJson<List<String>>(json['avatar_frames']),
      bubbleText: serializer.fromJson<String?>(json['bubble_text']),
      colorArgb: serializer.fromJson<int?>(json['color_argb']),
      ghostSpeed: serializer.fromJson<double>(json['ghost_speed']),
      avatarFrameSpeed: serializer.fromJson<double>(json['avatar_frame_speed']),
      bubbleFont: serializer.fromJson<int>(json['bubble_font']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'content_id': serializer.toJson<String>(contentId),
      'author_id': serializer.toJson<String>(authorId),
      'avatar_frames': serializer.toJson<List<String>>(avatarFrames),
      'bubble_text': serializer.toJson<String?>(bubbleText),
      'color_argb': serializer.toJson<int?>(colorArgb),
      'ghost_speed': serializer.toJson<double>(ghostSpeed),
      'avatar_frame_speed': serializer.toJson<double>(avatarFrameSpeed),
      'bubble_font': serializer.toJson<int>(bubbleFont),
    };
  }

  ReactionRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contentId,
    String? authorId,
    List<String>? avatarFrames,
    Value<String?> bubbleText = const Value.absent(),
    Value<int?> colorArgb = const Value.absent(),
    double? ghostSpeed,
    double? avatarFrameSpeed,
    int? bubbleFont,
  }) => ReactionRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    contentId: contentId ?? this.contentId,
    authorId: authorId ?? this.authorId,
    avatarFrames: avatarFrames ?? this.avatarFrames,
    bubbleText: bubbleText.present ? bubbleText.value : this.bubbleText,
    colorArgb: colorArgb.present ? colorArgb.value : this.colorArgb,
    ghostSpeed: ghostSpeed ?? this.ghostSpeed,
    avatarFrameSpeed: avatarFrameSpeed ?? this.avatarFrameSpeed,
    bubbleFont: bubbleFont ?? this.bubbleFont,
  );
  ReactionRow copyWithCompanion(ReactionsCompanion data) {
    return ReactionRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      avatarFrames: data.avatarFrames.present ? data.avatarFrames.value : this.avatarFrames,
      bubbleText: data.bubbleText.present ? data.bubbleText.value : this.bubbleText,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
      ghostSpeed: data.ghostSpeed.present ? data.ghostSpeed.value : this.ghostSpeed,
      avatarFrameSpeed: data.avatarFrameSpeed.present ? data.avatarFrameSpeed.value : this.avatarFrameSpeed,
      bubbleFont: data.bubbleFont.present ? data.bubbleFont.value : this.bubbleFont,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReactionRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('contentId: $contentId, ')
          ..write('authorId: $authorId, ')
          ..write('avatarFrames: $avatarFrames, ')
          ..write('bubbleText: $bubbleText, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('ghostSpeed: $ghostSpeed, ')
          ..write('avatarFrameSpeed: $avatarFrameSpeed, ')
          ..write('bubbleFont: $bubbleFont')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    contentId,
    authorId,
    avatarFrames,
    bubbleText,
    colorArgb,
    ghostSpeed,
    avatarFrameSpeed,
    bubbleFont,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReactionRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.contentId == this.contentId &&
          other.authorId == this.authorId &&
          other.avatarFrames == this.avatarFrames &&
          other.bubbleText == this.bubbleText &&
          other.colorArgb == this.colorArgb &&
          other.ghostSpeed == this.ghostSpeed &&
          other.avatarFrameSpeed == this.avatarFrameSpeed &&
          other.bubbleFont == this.bubbleFont);
}

class ReactionsCompanion extends UpdateCompanion<ReactionRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> contentId;
  final Value<String> authorId;
  final Value<List<String>> avatarFrames;
  final Value<String?> bubbleText;
  final Value<int?> colorArgb;
  final Value<double> ghostSpeed;
  final Value<double> avatarFrameSpeed;
  final Value<int> bubbleFont;
  final Value<int> rowid;
  const ReactionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.contentId = const Value.absent(),
    this.authorId = const Value.absent(),
    this.avatarFrames = const Value.absent(),
    this.bubbleText = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.ghostSpeed = const Value.absent(),
    this.avatarFrameSpeed = const Value.absent(),
    this.bubbleFont = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReactionsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String contentId,
    required String authorId,
    required List<String> avatarFrames,
    this.bubbleText = const Value.absent(),
    this.colorArgb = const Value.absent(),
    required double ghostSpeed,
    required double avatarFrameSpeed,
    required int bubbleFont,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       contentId = Value(contentId),
       authorId = Value(authorId),
       avatarFrames = Value(avatarFrames),
       ghostSpeed = Value(ghostSpeed),
       avatarFrameSpeed = Value(avatarFrameSpeed),
       bubbleFont = Value(bubbleFont);
  static Insertable<ReactionRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? contentId,
    Expression<String>? authorId,
    Expression<String>? avatarFrames,
    Expression<String>? bubbleText,
    Expression<int>? colorArgb,
    Expression<double>? ghostSpeed,
    Expression<double>? avatarFrameSpeed,
    Expression<int>? bubbleFont,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (contentId != null) 'content_id': contentId,
      if (authorId != null) 'author_id': authorId,
      if (avatarFrames != null) 'avatar_frames': avatarFrames,
      if (bubbleText != null) 'bubble_text': bubbleText,
      if (colorArgb != null) 'color_argb': colorArgb,
      if (ghostSpeed != null) 'ghost_speed': ghostSpeed,
      if (avatarFrameSpeed != null) 'avatar_frame_speed': avatarFrameSpeed,
      if (bubbleFont != null) 'bubble_font': bubbleFont,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReactionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? contentId,
    Value<String>? authorId,
    Value<List<String>>? avatarFrames,
    Value<String?>? bubbleText,
    Value<int?>? colorArgb,
    Value<double>? ghostSpeed,
    Value<double>? avatarFrameSpeed,
    Value<int>? bubbleFont,
    Value<int>? rowid,
  }) {
    return ReactionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentId: contentId ?? this.contentId,
      authorId: authorId ?? this.authorId,
      avatarFrames: avatarFrames ?? this.avatarFrames,
      bubbleText: bubbleText ?? this.bubbleText,
      colorArgb: colorArgb ?? this.colorArgb,
      ghostSpeed: ghostSpeed ?? this.ghostSpeed,
      avatarFrameSpeed: avatarFrameSpeed ?? this.avatarFrameSpeed,
      bubbleFont: bubbleFont ?? this.bubbleFont,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(Reactions.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(Reactions.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (avatarFrames.present) {
      map['avatar_frames'] = Variable<String>(Reactions.$converteravatarFrames.toSql(avatarFrames.value));
    }
    if (bubbleText.present) {
      map['bubble_text'] = Variable<String>(bubbleText.value);
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    if (ghostSpeed.present) {
      map['ghost_speed'] = Variable<double>(ghostSpeed.value);
    }
    if (avatarFrameSpeed.present) {
      map['avatar_frame_speed'] = Variable<double>(avatarFrameSpeed.value);
    }
    if (bubbleFont.present) {
      map['bubble_font'] = Variable<int>(bubbleFont.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReactionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('contentId: $contentId, ')
          ..write('authorId: $authorId, ')
          ..write('avatarFrames: $avatarFrames, ')
          ..write('bubbleText: $bubbleText, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('ghostSpeed: $ghostSpeed, ')
          ..write('avatarFrameSpeed: $avatarFrameSpeed, ')
          ..write('bubbleFont: $bubbleFont, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DrawingDrafts extends Table with TableInfo<DrawingDrafts, DrawingDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DrawingDrafts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drawing_drafts';
  @override
  VerificationContext validateIntegrity(Insertable<DrawingDraftRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('data')) {
      context.handle(_dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DrawingDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrawingDraftRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping.read(DriftSqlType.blob, data['${effectivePrefix}data'])!,
    );
  }

  @override
  DrawingDrafts createAlias(String alias) {
    return DrawingDrafts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DrawingDraftRow extends DataClass implements Insertable<DrawingDraftRow> {
  final int id;
  final Uint8List data;
  const DrawingDraftRow({required this.id, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['data'] = Variable<Uint8List>(data);
    return map;
  }

  DrawingDraftsCompanion toCompanion(bool nullToAbsent) {
    return DrawingDraftsCompanion(id: Value(id), data: Value(data));
  }

  factory DrawingDraftRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrawingDraftRow(
      id: serializer.fromJson<int>(json['id']),
      data: serializer.fromJson<Uint8List>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id), 'data': serializer.toJson<Uint8List>(data)};
  }

  DrawingDraftRow copyWith({int? id, Uint8List? data}) => DrawingDraftRow(id: id ?? this.id, data: data ?? this.data);
  DrawingDraftRow copyWithCompanion(DrawingDraftsCompanion data) {
    return DrawingDraftRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DrawingDraftRow(')
          ..write('id: $id, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, $driftBlobEquality.hash(data));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrawingDraftRow && other.id == this.id && $driftBlobEquality.equals(other.data, this.data));
}

class DrawingDraftsCompanion extends UpdateCompanion<DrawingDraftRow> {
  final Value<int> id;
  final Value<Uint8List> data;
  const DrawingDraftsCompanion({this.id = const Value.absent(), this.data = const Value.absent()});
  DrawingDraftsCompanion.insert({this.id = const Value.absent(), required Uint8List data}) : data = Value(data);
  static Insertable<DrawingDraftRow> custom({Expression<int>? id, Expression<Uint8List>? data}) {
    return RawValuesInsertable({if (id != null) 'id': id, if (data != null) 'data': data});
  }

  DrawingDraftsCompanion copyWith({Value<int>? id, Value<Uint8List>? data}) {
    return DrawingDraftsCompanion(id: id ?? this.id, data: data ?? this.data);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrawingDraftsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class Comments extends Table with TableInfo<Comments, CommentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Comments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(Comments.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  ).withConverter<DateTime>(Comments.$converterupdatedAt);
  static const VerificationMeta _contentIdMeta = const VerificationMeta('contentId');
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES contents(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _signatureIdMeta = const VerificationMeta('signatureId');
  late final GeneratedColumn<String> signatureId = GeneratedColumn<String>(
    'signature_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, contentId, signatureId, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comments';
  @override
  VerificationContext validateIntegrity(Insertable<CommentRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content_id')) {
      context.handle(_contentIdMeta, contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta));
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('signature_id')) {
      context.handle(_signatureIdMeta, signatureId.isAcceptableOrUnknown(data['signature_id']!, _signatureIdMeta));
    } else if (isInserting) {
      context.missing(_signatureIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommentRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: Comments.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: Comments.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      contentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content_id'])!,
      signatureId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}signature_id'])!,
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}body'])!,
    );
  }

  @override
  Comments createAlias(String alias) {
    return Comments(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const MillisDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt = const MillisDateTimeConverter();
  @override
  bool get dontWriteConstraints => true;
}

class CommentRow extends DataClass implements Insertable<CommentRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String contentId;
  final String signatureId;
  final String body;
  const CommentRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.contentId,
    required this.signatureId,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['created_at'] = Variable<int>(Comments.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(Comments.$converterupdatedAt.toSql(updatedAt));
    }
    map['content_id'] = Variable<String>(contentId);
    map['signature_id'] = Variable<String>(signatureId);
    map['body'] = Variable<String>(body);
    return map;
  }

  CommentsCompanion toCompanion(bool nullToAbsent) {
    return CommentsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      contentId: Value(contentId),
      signatureId: Value(signatureId),
      body: Value(body),
    );
  }

  factory CommentRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommentRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      contentId: serializer.fromJson<String>(json['content_id']),
      signatureId: serializer.fromJson<String>(json['signature_id']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'content_id': serializer.toJson<String>(contentId),
      'signature_id': serializer.toJson<String>(signatureId),
      'body': serializer.toJson<String>(body),
    };
  }

  CommentRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contentId,
    String? signatureId,
    String? body,
  }) => CommentRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    contentId: contentId ?? this.contentId,
    signatureId: signatureId ?? this.signatureId,
    body: body ?? this.body,
  );
  CommentRow copyWithCompanion(CommentsCompanion data) {
    return CommentRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      signatureId: data.signatureId.present ? data.signatureId.value : this.signatureId,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommentRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('contentId: $contentId, ')
          ..write('signatureId: $signatureId, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, contentId, signatureId, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommentRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.contentId == this.contentId &&
          other.signatureId == this.signatureId &&
          other.body == this.body);
}

class CommentsCompanion extends UpdateCompanion<CommentRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> contentId;
  final Value<String> signatureId;
  final Value<String> body;
  final Value<int> rowid;
  const CommentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.contentId = const Value.absent(),
    this.signatureId = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommentsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String contentId,
    required String signatureId,
    required String body,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       contentId = Value(contentId),
       signatureId = Value(signatureId),
       body = Value(body);
  static Insertable<CommentRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? contentId,
    Expression<String>? signatureId,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (contentId != null) 'content_id': contentId,
      if (signatureId != null) 'signature_id': signatureId,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? contentId,
    Value<String>? signatureId,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return CommentsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentId: contentId ?? this.contentId,
      signatureId: signatureId ?? this.signatureId,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(Comments.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(Comments.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (signatureId.present) {
      map['signature_id'] = Variable<String>(signatureId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('contentId: $contentId, ')
          ..write('signatureId: $signatureId, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Signatures signatures = Signatures(this);
  late final Index signaturesPseudo = Index(
    'signatures_pseudo',
    'CREATE INDEX signatures_pseudo ON signatures (pseudo COLLATE NOCASE)',
  );
  late final UserSettingsStore userSettingsStore = UserSettingsStore(this);
  late final ExchangeLogs exchangeLogs = ExchangeLogs(this);
  late final Index exchangeLogsCreatedAt = Index(
    'exchange_logs_created_at',
    'CREATE INDEX exchange_logs_created_at ON exchange_logs (created_at DESC)',
  );
  late final ErrorLogs errorLogs = ErrorLogs(this);
  late final Index errorLogsCreatedAt = Index(
    'error_logs_created_at',
    'CREATE INDEX error_logs_created_at ON error_logs (created_at)',
  );
  late final Contents contents = Contents(this);
  late final ViewedContents viewedContents = ViewedContents(this);
  late final TrustSettingsStore trustSettingsStore = TrustSettingsStore(this);
  late final StorageSettings storageSettings = StorageSettings(this);
  late final SeenContents seenContents = SeenContents(this);
  late final Index seenContentsCreatedAt = Index(
    'seen_contents_created_at',
    'CREATE INDEX seen_contents_created_at ON seen_contents (created_at)',
  );
  late final Reactions reactions = Reactions(this);
  late final Index reactionsContentId = Index(
    'reactions_content_id',
    'CREATE INDEX reactions_content_id ON reactions (content_id, updated_at)',
  );
  late final DrawingDrafts drawingDrafts = DrawingDrafts(this);
  late final Index contentsDisplayScore = Index(
    'contents_display_score',
    'CREATE INDEX contents_display_score ON contents (display_score DESC, id)',
  );
  late final Index contentsBroadcastScore = Index(
    'contents_broadcast_score',
    'CREATE INDEX contents_broadcast_score ON contents (broadcast_score DESC)',
  );
  late final Index contentsSurvivalScore = Index(
    'contents_survival_score',
    'CREATE INDEX contents_survival_score ON contents (survival_score, created_at)',
  );
  late final Index contentsFlair = Index('contents_flair', 'CREATE INDEX contents_flair ON contents (flair)');
  late final Index contentsSignatureId = Index(
    'contents_signature_id',
    'CREATE INDEX contents_signature_id ON contents (signature_id)',
  );
  late final Index contentsOrigin = Index(
    'contents_origin',
    'CREATE INDEX contents_origin ON contents (origin, created_at DESC)',
  );
  late final Comments comments = Comments(this);
  late final Index commentsContentId = Index(
    'comments_content_id',
    'CREATE INDEX comments_content_id ON comments (content_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    signatures,
    signaturesPseudo,
    userSettingsStore,
    exchangeLogs,
    exchangeLogsCreatedAt,
    errorLogs,
    errorLogsCreatedAt,
    contents,
    viewedContents,
    trustSettingsStore,
    storageSettings,
    seenContents,
    seenContentsCreatedAt,
    reactions,
    reactionsContentId,
    drawingDrafts,
    contentsDisplayScore,
    contentsBroadcastScore,
    contentsSurvivalScore,
    contentsFlair,
    contentsSignatureId,
    contentsOrigin,
    comments,
    commentsContentId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('contents', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('viewed_contents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('contents', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('reactions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('contents', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('comments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $SignaturesCreateCompanionBuilder = SignaturesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String pseudo,
  required List<String> avatarFrames,
  Value<int?> colorArgb,
  required double ghostSpeed,
  required double avatarFrameSpeed,
  required Map<int, String> socialLinks,
  Value<String?> bio,
  required int bioFont,
  Value<int> rowid,
});
typedef $SignaturesUpdateCompanionBuilder = SignaturesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> pseudo,
  Value<List<String>> avatarFrames,
  Value<int?> colorArgb,
  Value<double> ghostSpeed,
  Value<double> avatarFrameSpeed,
  Value<Map<int, String>> socialLinks,
  Value<String?> bio,
  Value<int> bioFont,
  Value<int> rowid,
});

class $SignaturesFilterComposer extends Composer<_$AppDatabase, Signatures> {
  $SignaturesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get pseudo =>
      $composableBuilder(column: $table.pseudo, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get avatarFrames =>
      $composableBuilder(column: $table.avatarFrames, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ghostSpeed =>
      $composableBuilder(column: $table.ghostSpeed, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avatarFrameSpeed =>
      $composableBuilder(column: $table.avatarFrameSpeed, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Map<int, String>, Map<int, String>, String> get socialLinks =>
      $composableBuilder(column: $table.socialLinks, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get bio => $composableBuilder(column: $table.bio, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bioFont =>
      $composableBuilder(column: $table.bioFont, builder: (column) => ColumnFilters(column));
}

class $SignaturesOrderingComposer extends Composer<_$AppDatabase, Signatures> {
  $SignaturesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pseudo =>
      $composableBuilder(column: $table.pseudo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarFrames =>
      $composableBuilder(column: $table.avatarFrames, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ghostSpeed =>
      $composableBuilder(column: $table.ghostSpeed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avatarFrameSpeed =>
      $composableBuilder(column: $table.avatarFrameSpeed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get socialLinks =>
      $composableBuilder(column: $table.socialLinks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bioFont =>
      $composableBuilder(column: $table.bioFont, builder: (column) => ColumnOrderings(column));
}

class $SignaturesAnnotationComposer extends Composer<_$AppDatabase, Signatures> {
  $SignaturesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get pseudo => $composableBuilder(column: $table.pseudo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get avatarFrames =>
      $composableBuilder(column: $table.avatarFrames, builder: (column) => column);

  GeneratedColumn<int> get colorArgb => $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  GeneratedColumn<double> get ghostSpeed => $composableBuilder(column: $table.ghostSpeed, builder: (column) => column);

  GeneratedColumn<double> get avatarFrameSpeed =>
      $composableBuilder(column: $table.avatarFrameSpeed, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<int, String>, String> get socialLinks =>
      $composableBuilder(column: $table.socialLinks, builder: (column) => column);

  GeneratedColumn<String> get bio => $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<int> get bioFont => $composableBuilder(column: $table.bioFont, builder: (column) => column);
}

class $SignaturesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Signatures,
          SignatureRow,
          $SignaturesFilterComposer,
          $SignaturesOrderingComposer,
          $SignaturesAnnotationComposer,
          $SignaturesCreateCompanionBuilder,
          $SignaturesUpdateCompanionBuilder,
          (SignatureRow, BaseReferences<_$AppDatabase, Signatures, SignatureRow>),
          SignatureRow,
          PrefetchHooks Function()
        > {
  $SignaturesTableManager(_$AppDatabase db, Signatures table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $SignaturesFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $SignaturesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $SignaturesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> pseudo = const Value.absent(),
                Value<List<String>> avatarFrames = const Value.absent(),
                Value<int?> colorArgb = const Value.absent(),
                Value<double> ghostSpeed = const Value.absent(),
                Value<double> avatarFrameSpeed = const Value.absent(),
                Value<Map<int, String>> socialLinks = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<int> bioFont = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignaturesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pseudo: pseudo,
                avatarFrames: avatarFrames,
                colorArgb: colorArgb,
                ghostSpeed: ghostSpeed,
                avatarFrameSpeed: avatarFrameSpeed,
                socialLinks: socialLinks,
                bio: bio,
                bioFont: bioFont,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String pseudo,
                required List<String> avatarFrames,
                Value<int?> colorArgb = const Value.absent(),
                required double ghostSpeed,
                required double avatarFrameSpeed,
                required Map<int, String> socialLinks,
                Value<String?> bio = const Value.absent(),
                required int bioFont,
                Value<int> rowid = const Value.absent(),
              }) => SignaturesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pseudo: pseudo,
                avatarFrames: avatarFrames,
                colorArgb: colorArgb,
                ghostSpeed: ghostSpeed,
                avatarFrameSpeed: avatarFrameSpeed,
                socialLinks: socialLinks,
                bio: bio,
                bioFont: bioFont,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Signatures, SignatureRow>(table),
                  BaseReferences<_$AppDatabase, Signatures, SignatureRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SignaturesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Signatures,
      SignatureRow,
      $SignaturesFilterComposer,
      $SignaturesOrderingComposer,
      $SignaturesAnnotationComposer,
      $SignaturesCreateCompanionBuilder,
      $SignaturesUpdateCompanionBuilder,
      (SignatureRow, BaseReferences<_$AppDatabase, Signatures, SignatureRow>),
      SignatureRow,
      PrefetchHooks Function()
    >;
typedef $UserSettingsStoreCreateCompanionBuilder = UserSettingsStoreCompanion Function({
  Value<int> id,
  required List<String> blockedUrls,
  required List<String> blockedWords,
  required bool isAnonymousByDefault,
  required bool isExchangeEnabled,
});
typedef $UserSettingsStoreUpdateCompanionBuilder = UserSettingsStoreCompanion Function({
  Value<int> id,
  Value<List<String>> blockedUrls,
  Value<List<String>> blockedWords,
  Value<bool> isAnonymousByDefault,
  Value<bool> isExchangeEnabled,
});

class $UserSettingsStoreFilterComposer extends Composer<_$AppDatabase, UserSettingsStore> {
  $UserSettingsStoreFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get blockedUrls =>
      $composableBuilder(column: $table.blockedUrls, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get blockedWords =>
      $composableBuilder(column: $table.blockedWords, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isAnonymousByDefault =>
      $composableBuilder(column: $table.isAnonymousByDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isExchangeEnabled =>
      $composableBuilder(column: $table.isExchangeEnabled, builder: (column) => ColumnFilters(column));
}

class $UserSettingsStoreOrderingComposer extends Composer<_$AppDatabase, UserSettingsStore> {
  $UserSettingsStoreOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blockedUrls =>
      $composableBuilder(column: $table.blockedUrls, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blockedWords =>
      $composableBuilder(column: $table.blockedWords, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAnonymousByDefault =>
      $composableBuilder(column: $table.isAnonymousByDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isExchangeEnabled =>
      $composableBuilder(column: $table.isExchangeEnabled, builder: (column) => ColumnOrderings(column));
}

class $UserSettingsStoreAnnotationComposer extends Composer<_$AppDatabase, UserSettingsStore> {
  $UserSettingsStoreAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get blockedUrls =>
      $composableBuilder(column: $table.blockedUrls, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get blockedWords =>
      $composableBuilder(column: $table.blockedWords, builder: (column) => column);

  GeneratedColumn<bool> get isAnonymousByDefault =>
      $composableBuilder(column: $table.isAnonymousByDefault, builder: (column) => column);

  GeneratedColumn<bool> get isExchangeEnabled =>
      $composableBuilder(column: $table.isExchangeEnabled, builder: (column) => column);
}

class $UserSettingsStoreTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          UserSettingsStore,
          UserSettingsRow,
          $UserSettingsStoreFilterComposer,
          $UserSettingsStoreOrderingComposer,
          $UserSettingsStoreAnnotationComposer,
          $UserSettingsStoreCreateCompanionBuilder,
          $UserSettingsStoreUpdateCompanionBuilder,
          (UserSettingsRow, BaseReferences<_$AppDatabase, UserSettingsStore, UserSettingsRow>),
          UserSettingsRow,
          PrefetchHooks Function()
        > {
  $UserSettingsStoreTableManager(_$AppDatabase db, UserSettingsStore table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $UserSettingsStoreFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $UserSettingsStoreOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $UserSettingsStoreAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<List<String>> blockedUrls = const Value.absent(),
                Value<List<String>> blockedWords = const Value.absent(),
                Value<bool> isAnonymousByDefault = const Value.absent(),
                Value<bool> isExchangeEnabled = const Value.absent(),
              }) => UserSettingsStoreCompanion(
                id: id,
                blockedUrls: blockedUrls,
                blockedWords: blockedWords,
                isAnonymousByDefault: isAnonymousByDefault,
                isExchangeEnabled: isExchangeEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required List<String> blockedUrls,
                required List<String> blockedWords,
                required bool isAnonymousByDefault,
                required bool isExchangeEnabled,
              }) => UserSettingsStoreCompanion.insert(
                id: id,
                blockedUrls: blockedUrls,
                blockedWords: blockedWords,
                isAnonymousByDefault: isAnonymousByDefault,
                isExchangeEnabled: isExchangeEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<UserSettingsStore, UserSettingsRow>(table),
                  BaseReferences<_$AppDatabase, UserSettingsStore, UserSettingsRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $UserSettingsStoreProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      UserSettingsStore,
      UserSettingsRow,
      $UserSettingsStoreFilterComposer,
      $UserSettingsStoreOrderingComposer,
      $UserSettingsStoreAnnotationComposer,
      $UserSettingsStoreCreateCompanionBuilder,
      $UserSettingsStoreUpdateCompanionBuilder,
      (UserSettingsRow, BaseReferences<_$AppDatabase, UserSettingsStore, UserSettingsRow>),
      UserSettingsRow,
      PrefetchHooks Function()
    >;
typedef $ExchangeLogsCreateCompanionBuilder = ExchangeLogsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String peerAddress,
  required int outcome,
  Value<bool?> isInitiator,
  required int durationInMillis,
  Value<int?> awaitedStep,
  required int sentBytes,
  required int receivedBytes,
  required int importedContents,
  required int rejectedContents,
  required int importedReactions,
  required int rejectedReactions,
  required int removedContents,
  Value<int> rowid,
});
typedef $ExchangeLogsUpdateCompanionBuilder = ExchangeLogsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> peerAddress,
  Value<int> outcome,
  Value<bool?> isInitiator,
  Value<int> durationInMillis,
  Value<int?> awaitedStep,
  Value<int> sentBytes,
  Value<int> receivedBytes,
  Value<int> importedContents,
  Value<int> rejectedContents,
  Value<int> importedReactions,
  Value<int> rejectedReactions,
  Value<int> removedContents,
  Value<int> rowid,
});

class $ExchangeLogsFilterComposer extends Composer<_$AppDatabase, ExchangeLogs> {
  $ExchangeLogsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get peerAddress =>
      $composableBuilder(column: $table.peerAddress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isInitiator =>
      $composableBuilder(column: $table.isInitiator, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationInMillis =>
      $composableBuilder(column: $table.durationInMillis, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get awaitedStep =>
      $composableBuilder(column: $table.awaitedStep, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sentBytes =>
      $composableBuilder(column: $table.sentBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get receivedBytes =>
      $composableBuilder(column: $table.receivedBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importedContents =>
      $composableBuilder(column: $table.importedContents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rejectedContents =>
      $composableBuilder(column: $table.rejectedContents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importedReactions =>
      $composableBuilder(column: $table.importedReactions, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rejectedReactions =>
      $composableBuilder(column: $table.rejectedReactions, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get removedContents =>
      $composableBuilder(column: $table.removedContents, builder: (column) => ColumnFilters(column));
}

class $ExchangeLogsOrderingComposer extends Composer<_$AppDatabase, ExchangeLogs> {
  $ExchangeLogsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerAddress =>
      $composableBuilder(column: $table.peerAddress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isInitiator =>
      $composableBuilder(column: $table.isInitiator, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationInMillis =>
      $composableBuilder(column: $table.durationInMillis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get awaitedStep =>
      $composableBuilder(column: $table.awaitedStep, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sentBytes =>
      $composableBuilder(column: $table.sentBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get receivedBytes =>
      $composableBuilder(column: $table.receivedBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importedContents =>
      $composableBuilder(column: $table.importedContents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rejectedContents =>
      $composableBuilder(column: $table.rejectedContents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importedReactions =>
      $composableBuilder(column: $table.importedReactions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rejectedReactions =>
      $composableBuilder(column: $table.rejectedReactions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get removedContents =>
      $composableBuilder(column: $table.removedContents, builder: (column) => ColumnOrderings(column));
}

class $ExchangeLogsAnnotationComposer extends Composer<_$AppDatabase, ExchangeLogs> {
  $ExchangeLogsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get peerAddress =>
      $composableBuilder(column: $table.peerAddress, builder: (column) => column);

  GeneratedColumn<int> get outcome => $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<bool> get isInitiator => $composableBuilder(column: $table.isInitiator, builder: (column) => column);

  GeneratedColumn<int> get durationInMillis =>
      $composableBuilder(column: $table.durationInMillis, builder: (column) => column);

  GeneratedColumn<int> get awaitedStep => $composableBuilder(column: $table.awaitedStep, builder: (column) => column);

  GeneratedColumn<int> get sentBytes => $composableBuilder(column: $table.sentBytes, builder: (column) => column);

  GeneratedColumn<int> get receivedBytes =>
      $composableBuilder(column: $table.receivedBytes, builder: (column) => column);

  GeneratedColumn<int> get importedContents =>
      $composableBuilder(column: $table.importedContents, builder: (column) => column);

  GeneratedColumn<int> get rejectedContents =>
      $composableBuilder(column: $table.rejectedContents, builder: (column) => column);

  GeneratedColumn<int> get importedReactions =>
      $composableBuilder(column: $table.importedReactions, builder: (column) => column);

  GeneratedColumn<int> get rejectedReactions =>
      $composableBuilder(column: $table.rejectedReactions, builder: (column) => column);

  GeneratedColumn<int> get removedContents =>
      $composableBuilder(column: $table.removedContents, builder: (column) => column);
}

class $ExchangeLogsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ExchangeLogs,
          ExchangeLogRow,
          $ExchangeLogsFilterComposer,
          $ExchangeLogsOrderingComposer,
          $ExchangeLogsAnnotationComposer,
          $ExchangeLogsCreateCompanionBuilder,
          $ExchangeLogsUpdateCompanionBuilder,
          (ExchangeLogRow, BaseReferences<_$AppDatabase, ExchangeLogs, ExchangeLogRow>),
          ExchangeLogRow,
          PrefetchHooks Function()
        > {
  $ExchangeLogsTableManager(_$AppDatabase db, ExchangeLogs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $ExchangeLogsFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $ExchangeLogsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $ExchangeLogsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> peerAddress = const Value.absent(),
                Value<int> outcome = const Value.absent(),
                Value<bool?> isInitiator = const Value.absent(),
                Value<int> durationInMillis = const Value.absent(),
                Value<int?> awaitedStep = const Value.absent(),
                Value<int> sentBytes = const Value.absent(),
                Value<int> receivedBytes = const Value.absent(),
                Value<int> importedContents = const Value.absent(),
                Value<int> rejectedContents = const Value.absent(),
                Value<int> importedReactions = const Value.absent(),
                Value<int> rejectedReactions = const Value.absent(),
                Value<int> removedContents = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExchangeLogsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                peerAddress: peerAddress,
                outcome: outcome,
                isInitiator: isInitiator,
                durationInMillis: durationInMillis,
                awaitedStep: awaitedStep,
                sentBytes: sentBytes,
                receivedBytes: receivedBytes,
                importedContents: importedContents,
                rejectedContents: rejectedContents,
                importedReactions: importedReactions,
                rejectedReactions: rejectedReactions,
                removedContents: removedContents,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String peerAddress,
                required int outcome,
                Value<bool?> isInitiator = const Value.absent(),
                required int durationInMillis,
                Value<int?> awaitedStep = const Value.absent(),
                required int sentBytes,
                required int receivedBytes,
                required int importedContents,
                required int rejectedContents,
                required int importedReactions,
                required int rejectedReactions,
                required int removedContents,
                Value<int> rowid = const Value.absent(),
              }) => ExchangeLogsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                peerAddress: peerAddress,
                outcome: outcome,
                isInitiator: isInitiator,
                durationInMillis: durationInMillis,
                awaitedStep: awaitedStep,
                sentBytes: sentBytes,
                receivedBytes: receivedBytes,
                importedContents: importedContents,
                rejectedContents: rejectedContents,
                importedReactions: importedReactions,
                rejectedReactions: rejectedReactions,
                removedContents: removedContents,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExchangeLogs, ExchangeLogRow>(table),
                  BaseReferences<_$AppDatabase, ExchangeLogs, ExchangeLogRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ExchangeLogsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ExchangeLogs,
      ExchangeLogRow,
      $ExchangeLogsFilterComposer,
      $ExchangeLogsOrderingComposer,
      $ExchangeLogsAnnotationComposer,
      $ExchangeLogsCreateCompanionBuilder,
      $ExchangeLogsUpdateCompanionBuilder,
      (ExchangeLogRow, BaseReferences<_$AppDatabase, ExchangeLogs, ExchangeLogRow>),
      ExchangeLogRow,
      PrefetchHooks Function()
    >;
typedef $ErrorLogsCreateCompanionBuilder = ErrorLogsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String source,
  required String errorType,
  required String message,
  required String stackTrace,
  Value<int> rowid,
});
typedef $ErrorLogsUpdateCompanionBuilder = ErrorLogsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> source,
  Value<String> errorType,
  Value<String> message,
  Value<String> stackTrace,
  Value<int> rowid,
});

class $ErrorLogsFilterComposer extends Composer<_$AppDatabase, ErrorLogs> {
  $ErrorLogsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorType =>
      $composableBuilder(column: $table.errorType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stackTrace =>
      $composableBuilder(column: $table.stackTrace, builder: (column) => ColumnFilters(column));
}

class $ErrorLogsOrderingComposer extends Composer<_$AppDatabase, ErrorLogs> {
  $ErrorLogsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorType =>
      $composableBuilder(column: $table.errorType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stackTrace =>
      $composableBuilder(column: $table.stackTrace, builder: (column) => ColumnOrderings(column));
}

class $ErrorLogsAnnotationComposer extends Composer<_$AppDatabase, ErrorLogs> {
  $ErrorLogsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get source => $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get errorType => $composableBuilder(column: $table.errorType, builder: (column) => column);

  GeneratedColumn<String> get message => $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get stackTrace => $composableBuilder(column: $table.stackTrace, builder: (column) => column);
}

class $ErrorLogsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ErrorLogs,
          ErrorLogRow,
          $ErrorLogsFilterComposer,
          $ErrorLogsOrderingComposer,
          $ErrorLogsAnnotationComposer,
          $ErrorLogsCreateCompanionBuilder,
          $ErrorLogsUpdateCompanionBuilder,
          (ErrorLogRow, BaseReferences<_$AppDatabase, ErrorLogs, ErrorLogRow>),
          ErrorLogRow,
          PrefetchHooks Function()
        > {
  $ErrorLogsTableManager(_$AppDatabase db, ErrorLogs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $ErrorLogsFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $ErrorLogsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $ErrorLogsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> errorType = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> stackTrace = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ErrorLogsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                source: source,
                errorType: errorType,
                message: message,
                stackTrace: stackTrace,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String source,
                required String errorType,
                required String message,
                required String stackTrace,
                Value<int> rowid = const Value.absent(),
              }) => ErrorLogsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                source: source,
                errorType: errorType,
                message: message,
                stackTrace: stackTrace,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ErrorLogs, ErrorLogRow>(table),
                  BaseReferences<_$AppDatabase, ErrorLogs, ErrorLogRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ErrorLogsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ErrorLogs,
      ErrorLogRow,
      $ErrorLogsFilterComposer,
      $ErrorLogsOrderingComposer,
      $ErrorLogsAnnotationComposer,
      $ErrorLogsCreateCompanionBuilder,
      $ErrorLogsUpdateCompanionBuilder,
      (ErrorLogRow, BaseReferences<_$AppDatabase, ErrorLogs, ErrorLogRow>),
      ErrorLogRow,
      PrefetchHooks Function()
    >;
typedef $ContentsCreateCompanionBuilder = ContentsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required DateTime storedAt,
  required String signatureId,
  required int type,
  required int origin,
  required int bounce,
  Value<String?> title,
  required String searchTitle,
  Value<String?> body,
  Value<String?> url,
  required String flair,
  required int sizeInBytes,
  Value<String?> ogImageUrl,
  Value<String?> ogTitle,
  Value<String?> ogDescription,
  required double broadcastScore,
  required double survivalScore,
  required double displayScore,
  required List<int> tagValues,
  required List<String> mediaUrls,
  required List<int> mediaKinds,
  Value<Uint8List?> drawingData,
  Value<int> rowid,
});
typedef $ContentsUpdateCompanionBuilder = ContentsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime> storedAt,
  Value<String> signatureId,
  Value<int> type,
  Value<int> origin,
  Value<int> bounce,
  Value<String?> title,
  Value<String> searchTitle,
  Value<String?> body,
  Value<String?> url,
  Value<String> flair,
  Value<int> sizeInBytes,
  Value<String?> ogImageUrl,
  Value<String?> ogTitle,
  Value<String?> ogDescription,
  Value<double> broadcastScore,
  Value<double> survivalScore,
  Value<double> displayScore,
  Value<List<int>> tagValues,
  Value<List<String>> mediaUrls,
  Value<List<int>> mediaKinds,
  Value<Uint8List?> drawingData,
  Value<int> rowid,
});

final class $ContentsReferences extends BaseReferences<_$AppDatabase, Contents, ContentRow> {
  $ContentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<ViewedContents, List<ViewedContentRow>> _viewedContentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.viewedContents, aliasName: 'contents__id__viewed_contents__id');

  $ViewedContentsProcessedTableManager get viewedContentsRefs {
    final manager = $ViewedContentsTableManager(
      $_db,
      $_db.viewedContents,
    ).filter((f) => f.id.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_viewedContentsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<Reactions, List<ReactionRow>> _reactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.reactions, aliasName: 'contents__id__reactions__content_id');

  $ReactionsProcessedTableManager get reactionsRefs {
    final manager = $ReactionsTableManager(
      $_db,
      $_db.reactions,
    ).filter((f) => f.contentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<Comments, List<CommentRow>> _commentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.comments, aliasName: 'contents__id__comments__content_id');

  $CommentsProcessedTableManager get commentsRefs {
    final manager = $CommentsTableManager(
      $_db,
      $_db.comments,
    ).filter((f) => f.contentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_commentsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $ContentsFilterComposer extends Composer<_$AppDatabase, Contents> {
  $ContentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get storedAt =>
      $composableBuilder(column: $table.storedAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get signatureId =>
      $composableBuilder(column: $table.signatureId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bounce =>
      $composableBuilder(column: $table.bounce, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get searchTitle =>
      $composableBuilder(column: $table.searchTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get flair =>
      $composableBuilder(column: $table.flair, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeInBytes =>
      $composableBuilder(column: $table.sizeInBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogImageUrl =>
      $composableBuilder(column: $table.ogImageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogTitle =>
      $composableBuilder(column: $table.ogTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogDescription =>
      $composableBuilder(column: $table.ogDescription, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get broadcastScore =>
      $composableBuilder(column: $table.broadcastScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get survivalScore =>
      $composableBuilder(column: $table.survivalScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get displayScore =>
      $composableBuilder(column: $table.displayScore, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<int>, List<int>, String> get tagValues =>
      $composableBuilder(column: $table.tagValues, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get mediaUrls =>
      $composableBuilder(column: $table.mediaUrls, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<int>, List<int>, String> get mediaKinds =>
      $composableBuilder(column: $table.mediaKinds, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<Uint8List> get drawingData =>
      $composableBuilder(column: $table.drawingData, builder: (column) => ColumnFilters(column));

  Expression<bool> viewedContentsRefs(Expression<bool> Function($ViewedContentsFilterComposer f) f) {
    final $ViewedContentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.viewedContents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ViewedContentsFilterComposer(
            $db: $db,
            $table: $db.viewedContents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reactionsRefs(Expression<bool> Function($ReactionsFilterComposer f) f) {
    final $ReactionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reactions,
      getReferencedColumn: (t) => t.contentId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ReactionsFilterComposer(
            $db: $db,
            $table: $db.reactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> commentsRefs(Expression<bool> Function($CommentsFilterComposer f) f) {
    final $CommentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comments,
      getReferencedColumn: (t) => t.contentId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $CommentsFilterComposer(
            $db: $db,
            $table: $db.comments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ContentsOrderingComposer extends Composer<_$AppDatabase, Contents> {
  $ContentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get storedAt =>
      $composableBuilder(column: $table.storedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signatureId =>
      $composableBuilder(column: $table.signatureId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bounce =>
      $composableBuilder(column: $table.bounce, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get searchTitle =>
      $composableBuilder(column: $table.searchTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get flair =>
      $composableBuilder(column: $table.flair, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeInBytes =>
      $composableBuilder(column: $table.sizeInBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogImageUrl =>
      $composableBuilder(column: $table.ogImageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogTitle =>
      $composableBuilder(column: $table.ogTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogDescription =>
      $composableBuilder(column: $table.ogDescription, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get broadcastScore =>
      $composableBuilder(column: $table.broadcastScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get survivalScore =>
      $composableBuilder(column: $table.survivalScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get displayScore =>
      $composableBuilder(column: $table.displayScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagValues =>
      $composableBuilder(column: $table.tagValues, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaUrls =>
      $composableBuilder(column: $table.mediaUrls, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaKinds =>
      $composableBuilder(column: $table.mediaKinds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get drawingData =>
      $composableBuilder(column: $table.drawingData, builder: (column) => ColumnOrderings(column));
}

class $ContentsAnnotationComposer extends Composer<_$AppDatabase, Contents> {
  $ContentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get storedAt =>
      $composableBuilder(column: $table.storedAt, builder: (column) => column);

  GeneratedColumn<String> get signatureId =>
      $composableBuilder(column: $table.signatureId, builder: (column) => column);

  GeneratedColumn<int> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get origin => $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get bounce => $composableBuilder(column: $table.bounce, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get searchTitle =>
      $composableBuilder(column: $table.searchTitle, builder: (column) => column);

  GeneratedColumn<String> get body => $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get url => $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get flair => $composableBuilder(column: $table.flair, builder: (column) => column);

  GeneratedColumn<int> get sizeInBytes => $composableBuilder(column: $table.sizeInBytes, builder: (column) => column);

  GeneratedColumn<String> get ogImageUrl => $composableBuilder(column: $table.ogImageUrl, builder: (column) => column);

  GeneratedColumn<String> get ogTitle => $composableBuilder(column: $table.ogTitle, builder: (column) => column);

  GeneratedColumn<String> get ogDescription =>
      $composableBuilder(column: $table.ogDescription, builder: (column) => column);

  GeneratedColumn<double> get broadcastScore =>
      $composableBuilder(column: $table.broadcastScore, builder: (column) => column);

  GeneratedColumn<double> get survivalScore =>
      $composableBuilder(column: $table.survivalScore, builder: (column) => column);

  GeneratedColumn<double> get displayScore =>
      $composableBuilder(column: $table.displayScore, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<int>, String> get tagValues =>
      $composableBuilder(column: $table.tagValues, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get mediaUrls =>
      $composableBuilder(column: $table.mediaUrls, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<int>, String> get mediaKinds =>
      $composableBuilder(column: $table.mediaKinds, builder: (column) => column);

  GeneratedColumn<Uint8List> get drawingData =>
      $composableBuilder(column: $table.drawingData, builder: (column) => column);

  Expression<T> viewedContentsRefs<T extends Object>(Expression<T> Function($ViewedContentsAnnotationComposer a) f) {
    final $ViewedContentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.viewedContents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ViewedContentsAnnotationComposer(
            $db: $db,
            $table: $db.viewedContents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reactionsRefs<T extends Object>(Expression<T> Function($ReactionsAnnotationComposer a) f) {
    final $ReactionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reactions,
      getReferencedColumn: (t) => t.contentId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ReactionsAnnotationComposer(
            $db: $db,
            $table: $db.reactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> commentsRefs<T extends Object>(Expression<T> Function($CommentsAnnotationComposer a) f) {
    final $CommentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comments,
      getReferencedColumn: (t) => t.contentId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $CommentsAnnotationComposer(
            $db: $db,
            $table: $db.comments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ContentsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Contents,
          ContentRow,
          $ContentsFilterComposer,
          $ContentsOrderingComposer,
          $ContentsAnnotationComposer,
          $ContentsCreateCompanionBuilder,
          $ContentsUpdateCompanionBuilder,
          (ContentRow, $ContentsReferences),
          ContentRow,
          PrefetchHooks Function({bool viewedContentsRefs, bool reactionsRefs, bool commentsRefs})
        > {
  $ContentsTableManager(_$AppDatabase db, Contents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $ContentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $ContentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $ContentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> storedAt = const Value.absent(),
                Value<String> signatureId = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> origin = const Value.absent(),
                Value<int> bounce = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> searchTitle = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String> flair = const Value.absent(),
                Value<int> sizeInBytes = const Value.absent(),
                Value<String?> ogImageUrl = const Value.absent(),
                Value<String?> ogTitle = const Value.absent(),
                Value<String?> ogDescription = const Value.absent(),
                Value<double> broadcastScore = const Value.absent(),
                Value<double> survivalScore = const Value.absent(),
                Value<double> displayScore = const Value.absent(),
                Value<List<int>> tagValues = const Value.absent(),
                Value<List<String>> mediaUrls = const Value.absent(),
                Value<List<int>> mediaKinds = const Value.absent(),
                Value<Uint8List?> drawingData = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                storedAt: storedAt,
                signatureId: signatureId,
                type: type,
                origin: origin,
                bounce: bounce,
                title: title,
                searchTitle: searchTitle,
                body: body,
                url: url,
                flair: flair,
                sizeInBytes: sizeInBytes,
                ogImageUrl: ogImageUrl,
                ogTitle: ogTitle,
                ogDescription: ogDescription,
                broadcastScore: broadcastScore,
                survivalScore: survivalScore,
                displayScore: displayScore,
                tagValues: tagValues,
                mediaUrls: mediaUrls,
                mediaKinds: mediaKinds,
                drawingData: drawingData,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime storedAt,
                required String signatureId,
                required int type,
                required int origin,
                required int bounce,
                Value<String?> title = const Value.absent(),
                required String searchTitle,
                Value<String?> body = const Value.absent(),
                Value<String?> url = const Value.absent(),
                required String flair,
                required int sizeInBytes,
                Value<String?> ogImageUrl = const Value.absent(),
                Value<String?> ogTitle = const Value.absent(),
                Value<String?> ogDescription = const Value.absent(),
                required double broadcastScore,
                required double survivalScore,
                required double displayScore,
                required List<int> tagValues,
                required List<String> mediaUrls,
                required List<int> mediaKinds,
                Value<Uint8List?> drawingData = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                storedAt: storedAt,
                signatureId: signatureId,
                type: type,
                origin: origin,
                bounce: bounce,
                title: title,
                searchTitle: searchTitle,
                body: body,
                url: url,
                flair: flair,
                sizeInBytes: sizeInBytes,
                ogImageUrl: ogImageUrl,
                ogTitle: ogTitle,
                ogDescription: ogDescription,
                broadcastScore: broadcastScore,
                survivalScore: survivalScore,
                displayScore: displayScore,
                tagValues: tagValues,
                mediaUrls: mediaUrls,
                mediaKinds: mediaKinds,
                drawingData: drawingData,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<Contents, ContentRow>(table), $ContentsReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({viewedContentsRefs = false, reactionsRefs = false, commentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (viewedContentsRefs) db.viewedContents,
                if (reactionsRefs) db.reactions,
                if (commentsRefs) db.comments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (viewedContentsRefs)
                    await $_getPrefetchedDataByColumns<ContentRow, Contents, ViewedContentRow, ViewedContents>(
                      currentTable: table,
                      referencedTable: $ContentsReferences._viewedContentsRefsTable(db),
                      managerFromTypedResult: (p0) => $ContentsReferences(db, table, p0).viewedContentsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'id',
                      typedResults: items,
                    ),
                  if (reactionsRefs)
                    await $_getPrefetchedDataByColumns<ContentRow, Contents, ReactionRow, Reactions>(
                      currentTable: table,
                      referencedTable: $ContentsReferences._reactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $ContentsReferences(db, table, p0).reactionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'content_id',
                      typedResults: items,
                    ),
                  if (commentsRefs)
                    await $_getPrefetchedDataByColumns<ContentRow, Contents, CommentRow, Comments>(
                      currentTable: table,
                      referencedTable: $ContentsReferences._commentsRefsTable(db),
                      managerFromTypedResult: (p0) => $ContentsReferences(db, table, p0).commentsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'content_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $ContentsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Contents,
      ContentRow,
      $ContentsFilterComposer,
      $ContentsOrderingComposer,
      $ContentsAnnotationComposer,
      $ContentsCreateCompanionBuilder,
      $ContentsUpdateCompanionBuilder,
      (ContentRow, $ContentsReferences),
      ContentRow,
      PrefetchHooks Function({bool viewedContentsRefs, bool reactionsRefs, bool commentsRefs})
    >;
typedef $ViewedContentsCreateCompanionBuilder = ViewedContentsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $ViewedContentsUpdateCompanionBuilder = ViewedContentsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $ViewedContentsReferences extends BaseReferences<_$AppDatabase, ViewedContents, ViewedContentRow> {
  $ViewedContentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Contents _idTable(_$AppDatabase db) => db.contents.createAlias('viewed_contents__id__contents__id');

  $ContentsProcessedTableManager get id {
    final $_column = $_itemColumn<String>('id')!;

    final manager = $ContentsTableManager($_db, $_db.contents).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_idTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $ViewedContentsFilterComposer extends Composer<_$AppDatabase, ViewedContents> {
  $ViewedContentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  $ContentsFilterComposer get id {
    final $ContentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ContentsFilterComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ViewedContentsOrderingComposer extends Composer<_$AppDatabase, ViewedContents> {
  $ViewedContentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $ContentsOrderingComposer get id {
    final $ContentsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ContentsOrderingComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ViewedContentsAnnotationComposer extends Composer<_$AppDatabase, ViewedContents> {
  $ViewedContentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $ContentsAnnotationComposer get id {
    final $ContentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ContentsAnnotationComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ViewedContentsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ViewedContents,
          ViewedContentRow,
          $ViewedContentsFilterComposer,
          $ViewedContentsOrderingComposer,
          $ViewedContentsAnnotationComposer,
          $ViewedContentsCreateCompanionBuilder,
          $ViewedContentsUpdateCompanionBuilder,
          (ViewedContentRow, $ViewedContentsReferences),
          ViewedContentRow,
          PrefetchHooks Function({bool id})
        > {
  $ViewedContentsTableManager(_$AppDatabase db, ViewedContents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $ViewedContentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $ViewedContentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $ViewedContentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ViewedContentsCompanion(id: id, createdAt: createdAt, updatedAt: updatedAt, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) => ViewedContentsCompanion.insert(id: id, createdAt: createdAt, updatedAt: updatedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<ViewedContents, ViewedContentRow>(table), $ViewedContentsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({id = false}) {
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
                    if (id) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.id,
                        referencedTable: $ViewedContentsReferences._idTable(db),
                        referencedColumn: $ViewedContentsReferences._idTable(db).id,
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

typedef $ViewedContentsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ViewedContents,
      ViewedContentRow,
      $ViewedContentsFilterComposer,
      $ViewedContentsOrderingComposer,
      $ViewedContentsAnnotationComposer,
      $ViewedContentsCreateCompanionBuilder,
      $ViewedContentsUpdateCompanionBuilder,
      (ViewedContentRow, $ViewedContentsReferences),
      ViewedContentRow,
      PrefetchHooks Function({bool id})
    >;
typedef $TrustSettingsStoreCreateCompanionBuilder = TrustSettingsStoreCompanion Function({
  Value<int> id,
  required List<String> mediaTrustedPatterns,
  required List<String> mediaGreyPatterns,
  required List<String> linkTrustedPatterns,
  required List<String> linkGreyPatterns,
});
typedef $TrustSettingsStoreUpdateCompanionBuilder = TrustSettingsStoreCompanion Function({
  Value<int> id,
  Value<List<String>> mediaTrustedPatterns,
  Value<List<String>> mediaGreyPatterns,
  Value<List<String>> linkTrustedPatterns,
  Value<List<String>> linkGreyPatterns,
});

class $TrustSettingsStoreFilterComposer extends Composer<_$AppDatabase, TrustSettingsStore> {
  $TrustSettingsStoreFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get mediaTrustedPatterns => $composableBuilder(
    column: $table.mediaTrustedPatterns,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get mediaGreyPatterns =>
      $composableBuilder(column: $table.mediaGreyPatterns, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get linkTrustedPatterns => $composableBuilder(
    column: $table.linkTrustedPatterns,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get linkGreyPatterns =>
      $composableBuilder(column: $table.linkGreyPatterns, builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $TrustSettingsStoreOrderingComposer extends Composer<_$AppDatabase, TrustSettingsStore> {
  $TrustSettingsStoreOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaTrustedPatterns =>
      $composableBuilder(column: $table.mediaTrustedPatterns, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaGreyPatterns =>
      $composableBuilder(column: $table.mediaGreyPatterns, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkTrustedPatterns =>
      $composableBuilder(column: $table.linkTrustedPatterns, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkGreyPatterns =>
      $composableBuilder(column: $table.linkGreyPatterns, builder: (column) => ColumnOrderings(column));
}

class $TrustSettingsStoreAnnotationComposer extends Composer<_$AppDatabase, TrustSettingsStore> {
  $TrustSettingsStoreAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get mediaTrustedPatterns =>
      $composableBuilder(column: $table.mediaTrustedPatterns, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get mediaGreyPatterns =>
      $composableBuilder(column: $table.mediaGreyPatterns, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get linkTrustedPatterns =>
      $composableBuilder(column: $table.linkTrustedPatterns, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get linkGreyPatterns =>
      $composableBuilder(column: $table.linkGreyPatterns, builder: (column) => column);
}

class $TrustSettingsStoreTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          TrustSettingsStore,
          TrustSettingsRow,
          $TrustSettingsStoreFilterComposer,
          $TrustSettingsStoreOrderingComposer,
          $TrustSettingsStoreAnnotationComposer,
          $TrustSettingsStoreCreateCompanionBuilder,
          $TrustSettingsStoreUpdateCompanionBuilder,
          (TrustSettingsRow, BaseReferences<_$AppDatabase, TrustSettingsStore, TrustSettingsRow>),
          TrustSettingsRow,
          PrefetchHooks Function()
        > {
  $TrustSettingsStoreTableManager(_$AppDatabase db, TrustSettingsStore table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $TrustSettingsStoreFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $TrustSettingsStoreOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $TrustSettingsStoreAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<List<String>> mediaTrustedPatterns = const Value.absent(),
                Value<List<String>> mediaGreyPatterns = const Value.absent(),
                Value<List<String>> linkTrustedPatterns = const Value.absent(),
                Value<List<String>> linkGreyPatterns = const Value.absent(),
              }) => TrustSettingsStoreCompanion(
                id: id,
                mediaTrustedPatterns: mediaTrustedPatterns,
                mediaGreyPatterns: mediaGreyPatterns,
                linkTrustedPatterns: linkTrustedPatterns,
                linkGreyPatterns: linkGreyPatterns,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required List<String> mediaTrustedPatterns,
                required List<String> mediaGreyPatterns,
                required List<String> linkTrustedPatterns,
                required List<String> linkGreyPatterns,
              }) => TrustSettingsStoreCompanion.insert(
                id: id,
                mediaTrustedPatterns: mediaTrustedPatterns,
                mediaGreyPatterns: mediaGreyPatterns,
                linkTrustedPatterns: linkTrustedPatterns,
                linkGreyPatterns: linkGreyPatterns,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TrustSettingsStore, TrustSettingsRow>(table),
                  BaseReferences<_$AppDatabase, TrustSettingsStore, TrustSettingsRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TrustSettingsStoreProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      TrustSettingsStore,
      TrustSettingsRow,
      $TrustSettingsStoreFilterComposer,
      $TrustSettingsStoreOrderingComposer,
      $TrustSettingsStoreAnnotationComposer,
      $TrustSettingsStoreCreateCompanionBuilder,
      $TrustSettingsStoreUpdateCompanionBuilder,
      (TrustSettingsRow, BaseReferences<_$AppDatabase, TrustSettingsStore, TrustSettingsRow>),
      TrustSettingsRow,
      PrefetchHooks Function()
    >;
typedef $StorageSettingsCreateCompanionBuilder = StorageSettingsCompanion Function({
  Value<int> id,
  required int maxSizeInBytes,
  required int strategy,
});
typedef $StorageSettingsUpdateCompanionBuilder = StorageSettingsCompanion Function({
  Value<int> id,
  Value<int> maxSizeInBytes,
  Value<int> strategy,
});

class $StorageSettingsFilterComposer extends Composer<_$AppDatabase, StorageSettings> {
  $StorageSettingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxSizeInBytes =>
      $composableBuilder(column: $table.maxSizeInBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get strategy =>
      $composableBuilder(column: $table.strategy, builder: (column) => ColumnFilters(column));
}

class $StorageSettingsOrderingComposer extends Composer<_$AppDatabase, StorageSettings> {
  $StorageSettingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxSizeInBytes =>
      $composableBuilder(column: $table.maxSizeInBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get strategy =>
      $composableBuilder(column: $table.strategy, builder: (column) => ColumnOrderings(column));
}

class $StorageSettingsAnnotationComposer extends Composer<_$AppDatabase, StorageSettings> {
  $StorageSettingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get maxSizeInBytes =>
      $composableBuilder(column: $table.maxSizeInBytes, builder: (column) => column);

  GeneratedColumn<int> get strategy => $composableBuilder(column: $table.strategy, builder: (column) => column);
}

class $StorageSettingsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          StorageSettings,
          StorageRow,
          $StorageSettingsFilterComposer,
          $StorageSettingsOrderingComposer,
          $StorageSettingsAnnotationComposer,
          $StorageSettingsCreateCompanionBuilder,
          $StorageSettingsUpdateCompanionBuilder,
          (StorageRow, BaseReferences<_$AppDatabase, StorageSettings, StorageRow>),
          StorageRow,
          PrefetchHooks Function()
        > {
  $StorageSettingsTableManager(_$AppDatabase db, StorageSettings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $StorageSettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $StorageSettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $StorageSettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> maxSizeInBytes = const Value.absent(),
            Value<int> strategy = const Value.absent(),
          }) => StorageSettingsCompanion(id: id, maxSizeInBytes: maxSizeInBytes, strategy: strategy),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int maxSizeInBytes,
            required int strategy,
          }) => StorageSettingsCompanion.insert(id: id, maxSizeInBytes: maxSizeInBytes, strategy: strategy),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<StorageSettings, StorageRow>(table),
                  BaseReferences<_$AppDatabase, StorageSettings, StorageRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $StorageSettingsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      StorageSettings,
      StorageRow,
      $StorageSettingsFilterComposer,
      $StorageSettingsOrderingComposer,
      $StorageSettingsAnnotationComposer,
      $StorageSettingsCreateCompanionBuilder,
      $StorageSettingsUpdateCompanionBuilder,
      (StorageRow, BaseReferences<_$AppDatabase, StorageSettings, StorageRow>),
      StorageRow,
      PrefetchHooks Function()
    >;
typedef $SeenContentsCreateCompanionBuilder = SeenContentsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $SeenContentsUpdateCompanionBuilder = SeenContentsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $SeenContentsFilterComposer extends Composer<_$AppDatabase, SeenContents> {
  $SeenContentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $SeenContentsOrderingComposer extends Composer<_$AppDatabase, SeenContents> {
  $SeenContentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $SeenContentsAnnotationComposer extends Composer<_$AppDatabase, SeenContents> {
  $SeenContentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $SeenContentsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SeenContents,
          SeenContentRow,
          $SeenContentsFilterComposer,
          $SeenContentsOrderingComposer,
          $SeenContentsAnnotationComposer,
          $SeenContentsCreateCompanionBuilder,
          $SeenContentsUpdateCompanionBuilder,
          (SeenContentRow, BaseReferences<_$AppDatabase, SeenContents, SeenContentRow>),
          SeenContentRow,
          PrefetchHooks Function()
        > {
  $SeenContentsTableManager(_$AppDatabase db, SeenContents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $SeenContentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $SeenContentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $SeenContentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SeenContentsCompanion(id: id, createdAt: createdAt, updatedAt: updatedAt, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) => SeenContentsCompanion.insert(id: id, createdAt: createdAt, updatedAt: updatedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SeenContents, SeenContentRow>(table),
                  BaseReferences<_$AppDatabase, SeenContents, SeenContentRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SeenContentsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SeenContents,
      SeenContentRow,
      $SeenContentsFilterComposer,
      $SeenContentsOrderingComposer,
      $SeenContentsAnnotationComposer,
      $SeenContentsCreateCompanionBuilder,
      $SeenContentsUpdateCompanionBuilder,
      (SeenContentRow, BaseReferences<_$AppDatabase, SeenContents, SeenContentRow>),
      SeenContentRow,
      PrefetchHooks Function()
    >;
typedef $ReactionsCreateCompanionBuilder = ReactionsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String contentId,
  required String authorId,
  required List<String> avatarFrames,
  Value<String?> bubbleText,
  Value<int?> colorArgb,
  required double ghostSpeed,
  required double avatarFrameSpeed,
  required int bubbleFont,
  Value<int> rowid,
});
typedef $ReactionsUpdateCompanionBuilder = ReactionsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> contentId,
  Value<String> authorId,
  Value<List<String>> avatarFrames,
  Value<String?> bubbleText,
  Value<int?> colorArgb,
  Value<double> ghostSpeed,
  Value<double> avatarFrameSpeed,
  Value<int> bubbleFont,
  Value<int> rowid,
});

final class $ReactionsReferences extends BaseReferences<_$AppDatabase, Reactions, ReactionRow> {
  $ReactionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Contents _contentIdTable(_$AppDatabase db) => db.contents.createAlias('reactions__content_id__contents__id');

  $ContentsProcessedTableManager get contentId {
    final $_column = $_itemColumn<String>('content_id')!;

    final manager = $ContentsTableManager($_db, $_db.contents).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $ReactionsFilterComposer extends Composer<_$AppDatabase, Reactions> {
  $ReactionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get avatarFrames =>
      $composableBuilder(column: $table.avatarFrames, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get bubbleText =>
      $composableBuilder(column: $table.bubbleText, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ghostSpeed =>
      $composableBuilder(column: $table.ghostSpeed, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avatarFrameSpeed =>
      $composableBuilder(column: $table.avatarFrameSpeed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bubbleFont =>
      $composableBuilder(column: $table.bubbleFont, builder: (column) => ColumnFilters(column));

  $ContentsFilterComposer get contentId {
    final $ContentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentId,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ContentsFilterComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ReactionsOrderingComposer extends Composer<_$AppDatabase, Reactions> {
  $ReactionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarFrames =>
      $composableBuilder(column: $table.avatarFrames, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bubbleText =>
      $composableBuilder(column: $table.bubbleText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ghostSpeed =>
      $composableBuilder(column: $table.ghostSpeed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avatarFrameSpeed =>
      $composableBuilder(column: $table.avatarFrameSpeed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bubbleFont =>
      $composableBuilder(column: $table.bubbleFont, builder: (column) => ColumnOrderings(column));

  $ContentsOrderingComposer get contentId {
    final $ContentsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentId,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ContentsOrderingComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ReactionsAnnotationComposer extends Composer<_$AppDatabase, Reactions> {
  $ReactionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get authorId => $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get avatarFrames =>
      $composableBuilder(column: $table.avatarFrames, builder: (column) => column);

  GeneratedColumn<String> get bubbleText => $composableBuilder(column: $table.bubbleText, builder: (column) => column);

  GeneratedColumn<int> get colorArgb => $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  GeneratedColumn<double> get ghostSpeed => $composableBuilder(column: $table.ghostSpeed, builder: (column) => column);

  GeneratedColumn<double> get avatarFrameSpeed =>
      $composableBuilder(column: $table.avatarFrameSpeed, builder: (column) => column);

  GeneratedColumn<int> get bubbleFont => $composableBuilder(column: $table.bubbleFont, builder: (column) => column);

  $ContentsAnnotationComposer get contentId {
    final $ContentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentId,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ContentsAnnotationComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ReactionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Reactions,
          ReactionRow,
          $ReactionsFilterComposer,
          $ReactionsOrderingComposer,
          $ReactionsAnnotationComposer,
          $ReactionsCreateCompanionBuilder,
          $ReactionsUpdateCompanionBuilder,
          (ReactionRow, $ReactionsReferences),
          ReactionRow,
          PrefetchHooks Function({bool contentId})
        > {
  $ReactionsTableManager(_$AppDatabase db, Reactions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $ReactionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $ReactionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $ReactionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> contentId = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<List<String>> avatarFrames = const Value.absent(),
                Value<String?> bubbleText = const Value.absent(),
                Value<int?> colorArgb = const Value.absent(),
                Value<double> ghostSpeed = const Value.absent(),
                Value<double> avatarFrameSpeed = const Value.absent(),
                Value<int> bubbleFont = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReactionsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                contentId: contentId,
                authorId: authorId,
                avatarFrames: avatarFrames,
                bubbleText: bubbleText,
                colorArgb: colorArgb,
                ghostSpeed: ghostSpeed,
                avatarFrameSpeed: avatarFrameSpeed,
                bubbleFont: bubbleFont,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String contentId,
                required String authorId,
                required List<String> avatarFrames,
                Value<String?> bubbleText = const Value.absent(),
                Value<int?> colorArgb = const Value.absent(),
                required double ghostSpeed,
                required double avatarFrameSpeed,
                required int bubbleFont,
                Value<int> rowid = const Value.absent(),
              }) => ReactionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                contentId: contentId,
                authorId: authorId,
                avatarFrames: avatarFrames,
                bubbleText: bubbleText,
                colorArgb: colorArgb,
                ghostSpeed: ghostSpeed,
                avatarFrameSpeed: avatarFrameSpeed,
                bubbleFont: bubbleFont,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<Reactions, ReactionRow>(table), $ReactionsReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({contentId = false}) {
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
                    if (contentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.contentId,
                        referencedTable: $ReactionsReferences._contentIdTable(db),
                        referencedColumn: $ReactionsReferences._contentIdTable(db).id,
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

typedef $ReactionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Reactions,
      ReactionRow,
      $ReactionsFilterComposer,
      $ReactionsOrderingComposer,
      $ReactionsAnnotationComposer,
      $ReactionsCreateCompanionBuilder,
      $ReactionsUpdateCompanionBuilder,
      (ReactionRow, $ReactionsReferences),
      ReactionRow,
      PrefetchHooks Function({bool contentId})
    >;
typedef $DrawingDraftsCreateCompanionBuilder = DrawingDraftsCompanion Function({
  Value<int> id,
  required Uint8List data,
});
typedef $DrawingDraftsUpdateCompanionBuilder = DrawingDraftsCompanion Function({Value<int> id, Value<Uint8List> data});

class $DrawingDraftsFilterComposer extends Composer<_$AppDatabase, DrawingDrafts> {
  $DrawingDraftsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => ColumnFilters(column));
}

class $DrawingDraftsOrderingComposer extends Composer<_$AppDatabase, DrawingDrafts> {
  $DrawingDraftsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => ColumnOrderings(column));
}

class $DrawingDraftsAnnotationComposer extends Composer<_$AppDatabase, DrawingDrafts> {
  $DrawingDraftsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get data => $composableBuilder(column: $table.data, builder: (column) => column);
}

class $DrawingDraftsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          DrawingDrafts,
          DrawingDraftRow,
          $DrawingDraftsFilterComposer,
          $DrawingDraftsOrderingComposer,
          $DrawingDraftsAnnotationComposer,
          $DrawingDraftsCreateCompanionBuilder,
          $DrawingDraftsUpdateCompanionBuilder,
          (DrawingDraftRow, BaseReferences<_$AppDatabase, DrawingDrafts, DrawingDraftRow>),
          DrawingDraftRow,
          PrefetchHooks Function()
        > {
  $DrawingDraftsTableManager(_$AppDatabase db, DrawingDrafts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $DrawingDraftsFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $DrawingDraftsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $DrawingDraftsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<Uint8List> data = const Value.absent(),
          }) => DrawingDraftsCompanion(id: id, data: data),
          createCompanionCallback: ({Value<int> id = const Value.absent(), required Uint8List data}) =>
              DrawingDraftsCompanion.insert(id: id, data: data),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DrawingDrafts, DrawingDraftRow>(table),
                  BaseReferences<_$AppDatabase, DrawingDrafts, DrawingDraftRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DrawingDraftsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      DrawingDrafts,
      DrawingDraftRow,
      $DrawingDraftsFilterComposer,
      $DrawingDraftsOrderingComposer,
      $DrawingDraftsAnnotationComposer,
      $DrawingDraftsCreateCompanionBuilder,
      $DrawingDraftsUpdateCompanionBuilder,
      (DrawingDraftRow, BaseReferences<_$AppDatabase, DrawingDrafts, DrawingDraftRow>),
      DrawingDraftRow,
      PrefetchHooks Function()
    >;
typedef $CommentsCreateCompanionBuilder = CommentsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String contentId,
  required String signatureId,
  required String body,
  Value<int> rowid,
});
typedef $CommentsUpdateCompanionBuilder = CommentsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> contentId,
  Value<String> signatureId,
  Value<String> body,
  Value<int> rowid,
});

final class $CommentsReferences extends BaseReferences<_$AppDatabase, Comments, CommentRow> {
  $CommentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Contents _contentIdTable(_$AppDatabase db) => db.contents.createAlias('comments__content_id__contents__id');

  $ContentsProcessedTableManager get contentId {
    final $_column = $_itemColumn<String>('content_id')!;

    final manager = $ContentsTableManager($_db, $_db.contents).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $CommentsFilterComposer extends Composer<_$AppDatabase, Comments> {
  $CommentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get signatureId =>
      $composableBuilder(column: $table.signatureId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnFilters(column));

  $ContentsFilterComposer get contentId {
    final $ContentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentId,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ContentsFilterComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CommentsOrderingComposer extends Composer<_$AppDatabase, Comments> {
  $CommentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signatureId =>
      $composableBuilder(column: $table.signatureId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => ColumnOrderings(column));

  $ContentsOrderingComposer get contentId {
    final $ContentsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentId,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ContentsOrderingComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CommentsAnnotationComposer extends Composer<_$AppDatabase, Comments> {
  $CommentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get signatureId =>
      $composableBuilder(column: $table.signatureId, builder: (column) => column);

  GeneratedColumn<String> get body => $composableBuilder(column: $table.body, builder: (column) => column);

  $ContentsAnnotationComposer get contentId {
    final $ContentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentId,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $ContentsAnnotationComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CommentsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Comments,
          CommentRow,
          $CommentsFilterComposer,
          $CommentsOrderingComposer,
          $CommentsAnnotationComposer,
          $CommentsCreateCompanionBuilder,
          $CommentsUpdateCompanionBuilder,
          (CommentRow, $CommentsReferences),
          CommentRow,
          PrefetchHooks Function({bool contentId})
        > {
  $CommentsTableManager(_$AppDatabase db, Comments table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $CommentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $CommentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $CommentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> contentId = const Value.absent(),
                Value<String> signatureId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommentsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                contentId: contentId,
                signatureId: signatureId,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String contentId,
                required String signatureId,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => CommentsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                contentId: contentId,
                signatureId: signatureId,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<Comments, CommentRow>(table), $CommentsReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({contentId = false}) {
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
                    if (contentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.contentId,
                        referencedTable: $CommentsReferences._contentIdTable(db),
                        referencedColumn: $CommentsReferences._contentIdTable(db).id,
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

typedef $CommentsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Comments,
      CommentRow,
      $CommentsFilterComposer,
      $CommentsOrderingComposer,
      $CommentsAnnotationComposer,
      $CommentsCreateCompanionBuilder,
      $CommentsUpdateCompanionBuilder,
      (CommentRow, $CommentsReferences),
      CommentRow,
      PrefetchHooks Function({bool contentId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $SignaturesTableManager get signatures => $SignaturesTableManager(_db, _db.signatures);
  $UserSettingsStoreTableManager get userSettingsStore => $UserSettingsStoreTableManager(_db, _db.userSettingsStore);
  $ExchangeLogsTableManager get exchangeLogs => $ExchangeLogsTableManager(_db, _db.exchangeLogs);
  $ErrorLogsTableManager get errorLogs => $ErrorLogsTableManager(_db, _db.errorLogs);
  $ContentsTableManager get contents => $ContentsTableManager(_db, _db.contents);
  $ViewedContentsTableManager get viewedContents => $ViewedContentsTableManager(_db, _db.viewedContents);
  $TrustSettingsStoreTableManager get trustSettingsStore =>
      $TrustSettingsStoreTableManager(_db, _db.trustSettingsStore);
  $StorageSettingsTableManager get storageSettings => $StorageSettingsTableManager(_db, _db.storageSettings);
  $SeenContentsTableManager get seenContents => $SeenContentsTableManager(_db, _db.seenContents);
  $ReactionsTableManager get reactions => $ReactionsTableManager(_db, _db.reactions);
  $DrawingDraftsTableManager get drawingDrafts => $DrawingDraftsTableManager(_db, _db.drawingDrafts);
  $CommentsTableManager get comments => $CommentsTableManager(_db, _db.comments);
}
