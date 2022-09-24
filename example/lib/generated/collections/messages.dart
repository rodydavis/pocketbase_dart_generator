import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

import 'base.dart';

part 'messages.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class Messages extends CollectionBase {
  const Messages({
    required this.id,
    required this.message,
    required this.author,
    required this.created,
    required this.updated,
  });

  @HiveField(0)
  @JsonKey(name: 'id', fromJson: getStringValue)
  @override
  final String id;

  @HiveField(1)
  @JsonKey(name: 'message', fromJson: getStringValue)
  final String message;

  @HiveField(2)
  @JsonKey(name: 'author', fromJson: getStringValue)
  final String author;

  @HiveField(3)
  @JsonKey(name: 'created')
  @override
  final DateTime created;

  @HiveField(4)
  @JsonKey(name: 'updated')
  @override
  final DateTime updated;

  Map<String, dynamic> toJson() => _$MessagesToJson(this);

  factory Messages.fromJson(Map<String, dynamic> json) => _$MessagesFromJson(json);
}

