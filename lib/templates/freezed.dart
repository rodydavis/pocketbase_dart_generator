import 'package:mustache_template/mustache.dart';

const freezedTemplate = r'''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

import 'base.dart';

part '{{file}}.freezed.dart';
part '{{file}}.g.dart';

@freezed
class {{className}} extends CollectionBase with _${{className}} {
  {{#typeId}}
  @HiveType(typeId: {{.}})
  {{/typeId}}
  const factory {{className}}({
    {{#fields}}
    {{#jsonOverride}}
     @JsonKey({{jsonOverride}})
    {{/jsonOverride}}
    {{#hiveField}}
     @HiveField({{.}})
    {{/hiveField}}
    {{#required}}required {{/required}}{{type}} {{name}},
    {{/fields}}
  }) = _{{className}};

  factory {{className}}.fromJson(Map<String, Object?> json)
      => _${{className}}FromJson(json);
}
''';

class FreezedField {
  final String name;
  final String type;
  final String? jsonOverride;
  final bool required;
  final int? hiveField;

  FreezedField({
    required this.name,
    required this.type,
    required this.jsonOverride,
    required this.required,
    required this.hiveField,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'jsonOverride': jsonOverride,
      'required': required,
      'hiveField': hiveField,
    };
  }
}

class FreezedTemplate {
  final String file;
  final String className;
  final List<FreezedField> fields;
  final int? typeId;

  FreezedTemplate({
    required this.file,
    required this.className,
    required this.fields,
    required this.typeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'file': file,
      'className': className,
      'typeId': typeId,
      'fields': fields.map((e) => e.toMap()).toList(),
    };
  }

  String render() {
    final template = Template(
      freezedTemplate,
      name: 'freezed',
      htmlEscapeValues: false,
    );
    return template.renderString(toMap());
  }
}
