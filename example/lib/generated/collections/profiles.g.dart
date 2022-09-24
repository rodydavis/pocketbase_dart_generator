// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profiles.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfilesAdapter extends TypeAdapter<Profiles> {
  @override
  final int typeId = 0;

  @override
  Profiles read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Profiles(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String?,
      avatar: fields[3] as String?,
      website: fields[4] as String?,
      created: fields[5] as DateTime,
      updated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Profiles obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.avatar)
      ..writeByte(4)
      ..write(obj.website)
      ..writeByte(5)
      ..write(obj.created)
      ..writeByte(6)
      ..write(obj.updated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profiles _$ProfilesFromJson(Map<String, dynamic> json) => Profiles(
      id: getStringValue(json['id']),
      userId: getStringValue(json['userId']),
      name: getStringValue(json['name']),
      avatar: getStringValue(json['avatar']),
      website: getStringValue(json['website']),
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );

Map<String, dynamic> _$ProfilesToJson(Profiles instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'avatar': instance.avatar,
      'website': instance.website,
      'created': instance.created.toIso8601String(),
      'updated': instance.updated.toIso8601String(),
    };
