import 'field.dart';

class $Class {
  final int? hiveTypeAdapter;
  final String name;
  final String description;
  final String collectionId;
  final String collectionName;
  final List<$Field> fields;
  final List<String> indexes;
  final String? query;
  final String type;

  String? get hiveType => hiveTypeAdapter?.toString();
  bool get hasQuery => query != null && query!.isNotEmpty;

  $Class({
    required this.hiveTypeAdapter,
    required this.name,
    required this.type,
    required this.description,
    required this.collectionId,
    required this.collectionName,
    required this.fields,
    required this.indexes,
    required this.query,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'hiveType': hiveType,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'indexes': indexes,
      'query': query,
      'hasQuery': hasQuery,
      'fields': [
        for (var i = 0; i < fields.length; i++)
          fields[i].toJson(hiveType != null ? i : null),
      ],
    };
  }
}
