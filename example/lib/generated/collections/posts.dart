import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

import 'base.dart';

part 'posts.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class Posts extends CollectionBase {
  const Posts({
    required this.id,
    required this.title,
    required this.description,
    required this.active,
    required this.options,
    required this.featuredImages,
    required this.created,
    required this.updated,
  });

  @HiveField(0)
  @JsonKey(name: 'id', fromJson: getStringValue)
  @override
  final String id;

  @HiveField(1)
  @JsonKey(name: 'title', fromJson: getStringValue)
  final String title;

  @HiveField(2)
  @JsonKey(name: 'description', fromJson: getStringValue)
  final String? description;

  @HiveField(3)
  @JsonKey(name: 'active', fromJson: getBoolValue)
  final bool? active;

  @HiveField(4)
  @JsonKey(name: 'options')
  final List<String>? options;

  @HiveField(5)
  @JsonKey(name: 'featuredImages')
  final List<String>? featuredImages;

  @HiveField(6)
  @JsonKey(name: 'created')
  @override
  final DateTime created;

  @HiveField(7)
  @JsonKey(name: 'updated')
  @override
  final DateTime updated;

  Map<String, dynamic> toJson() => _$PostsToJson(this);

  factory Posts.fromJson(Map<String, dynamic> json) => _$PostsFromJson(json);
}

