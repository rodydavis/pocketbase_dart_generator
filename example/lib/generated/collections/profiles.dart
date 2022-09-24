import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

import 'base.dart';

part 'profiles.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Profiles extends CollectionBase {
  const Profiles({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.website,
    required this.created,
    required this.updated,
  });

  @HiveField(0)
  @JsonKey(name: 'id', fromJson: getStringValue)
  @override
  final String id;

  @HiveField(1)
  @JsonKey(name: 'userId', fromJson: getStringValue)
  final String userId;

  @HiveField(2)
  @JsonKey(name: 'name', fromJson: getStringValue)
  final String? name;

  @HiveField(3)
  @JsonKey(name: 'avatar', fromJson: getStringValue)
  final String? avatar;

  @HiveField(4)
  @JsonKey(name: 'website', fromJson: getStringValue)
  final String? website;

  @HiveField(5)
  @JsonKey(name: 'created')
  @override
  final DateTime created;

  @HiveField(6)
  @JsonKey(name: 'updated')
  @override
  final DateTime updated;

  Map<String, dynamic> toJson() => _$ProfilesToJson(this);

  factory Profiles.fromJson(Map<String, dynamic> json) => _$ProfilesFromJson(json);
}

