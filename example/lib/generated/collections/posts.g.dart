// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostsAdapter extends TypeAdapter<Posts> {
  @override
  final int typeId = 1;

  @override
  Posts read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Posts(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      active: fields[3] as bool?,
      options: (fields[4] as List?)?.cast<String>(),
      featuredImages: (fields[5] as List?)?.cast<String>(),
      created: fields[6] as DateTime,
      updated: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Posts obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.active)
      ..writeByte(4)
      ..write(obj.options)
      ..writeByte(5)
      ..write(obj.featuredImages)
      ..writeByte(6)
      ..write(obj.created)
      ..writeByte(7)
      ..write(obj.updated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Posts _$PostsFromJson(Map<String, dynamic> json) => Posts(
      id: getStringValue(json['id']),
      title: getStringValue(json['title']),
      description: getStringValue(json['description']),
      active: getBoolValue(json['active']),
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      featuredImages: (json['featuredImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );

Map<String, dynamic> _$PostsToJson(Posts instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'active': instance.active,
      'options': instance.options,
      'featuredImages': instance.featuredImages,
      'created': instance.created.toIso8601String(),
      'updated': instance.updated.toIso8601String(),
    };
