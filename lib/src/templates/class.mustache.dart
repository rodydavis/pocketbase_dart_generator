final classTemplate = r'''
import 'package:json_annotation/json_annotation.dart';
{{#hiveType}}
import 'package:hive/hive.dart';
{{/hiveType}}

part '{{filename}}.g.dart';

{{#hiveType}}
@HiveType(typeId: {{.}})
{{/hiveType}}
@JsonSerializable()
class {{name}} {
  {{name}}({
    required this.id,
    {{#fields}}
    {{#required}}required {{/required}}this.{{name}}{{#defaultValue}} defaultValue{{/defaultValue}},
    {{/fields}}
    this.collectionId = '{{collectionId}}',
    this.collectionName = '{{collectionName}}',
    required this.created,
    required this.updated,
  });

  final String id;
  final String collectionId;
  final String collectionName;
  final DateTime created;
  final DateTime updated;

  {{#fields}}
  {{#hiveType}}
  @HiveField({{.}})
  {{/hiveType}}
  @JsonKey(name: '{{description}}')
  {{#final}}final {{/final}}{{type}}{{^required}}?{{/required}} {{name}};
  {{/fields}}

  Map<String, dynamic> toJson() => _${{name}}ToJson(this);

  factory {{name}}.fromJson(Map<String, dynamic> json) => _${{name}}FromJson(json);
}

{{#fields}}
{{#enum}}
/// {{description}}
enum {{type}} {
  {{#options}}
  ${{.}},
  {{/options}}
}

extension {{type}}Utils on {{type}} {
  String get name {
    switch (this) {
      {{#options}}
      case {{type}}.${{.}}:
        return '{{.}}';
      {{/options}}
    }
  }
}
{{/enum}}
{{/fields}}
''';

class $Class {
  final int? hiveTypeAdapter;
  final String name;
  final String filename;
  final String collectionId;
  final String collectionName;

  String? get hiveType => hiveTypeAdapter?.toString();

  $Class({
    required this.hiveTypeAdapter,
    required this.name,
    required this.filename,
    required this.collectionId,
    required this.collectionName,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filename': filename,
      'hiveType': hiveType,
      'collectionId': collectionId,
      'collectionName': collectionName,
    };
  }
}

class $Field {
  final String name;
  final String description;
  final bool isRequired;
  final bool isFinal;
  final String type;
  final List<String>? options;

  bool get isEnum => options != null;

  $Field({
    required this.name,
    required this.description,
    required this.isRequired,
    required this.isFinal,
    required this.type,
    required this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'required': isRequired,
      'final': isFinal,
      'type': type,
      'enum': isEnum,
      'options': options,
    };
  }
}
