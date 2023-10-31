import 'dart:convert';

import 'package:mustache_recase/mustache_recase.dart' as mustache_recase;
import 'package:mustache_template/mustache.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:recase/recase.dart';

final template = r'''
import 'package:json_annotation/json_annotation.dart';
{{#hasHive}}
import 'package:hive/hive.dart';
{{/hasHive}}
import 'package:pocketbase/pocketbase.dart';
import 'package:sqlite3/common.dart';

part '{{filename}}.g.dart';
{{#classes}}

/// {{description}}
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

class {{name}}Repository {
  final PocketBase client;
  final CommonDatabase database;
  final String Function() idGenerator;

  {{name}}Repository({
    required this.client,
    required this.database,
    required this.idGenerator,
  });

  void init() {
    database.execute(r"""
    BEGIN;
    CREATE TABLE `{{collectionName}}` (
      `id` TEXT NOT NULL,
      {{#fields}}
      `{{name}}` {{sql}} {{#required}}NOT NULL{{/required}},
      {{/fields}}
      `collectionId` TEXT NOT NULL,
      `collectionName` TEXT NOT NULL,
      `created` TEXT NOT NULL,
      `updated` TEXT NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`collectionId`) REFERENCES `collections` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) WITHOUT ROWID;
    {{#indexes}}
    {{.}};
    {{/indexes}}
    COMMIT;
    """);
  }

  {{name}} itemFromJson(Map<String, dynamic> json) {
    return {{name}}.fromJson(json);
  }

  List<{{name}}> localList() {
    final rows = database.select(r"""
    {{#query}}
    {{.}}
    {{/query}}
    {{^hasQuery}}
    SELECT * FROM `{{collectionName}}`
    {{/hasQuery}}
    """);
    return rows.map((e) => itemFromJson(e)).toList();
  }

  int localCount() {
    final rows = database.select(r"""
    SELECT COUNT(*) FROM `{{collectionName}}`
    """);
    return rows.first['COUNT(*)'] as int;
  }

  Future<List<{{name}}>> remoteList() async {
    final records = await client.collection('{{collectionId}}').getFullList();
    return records.map((e) => itemFromJson(e.toJson())).toList();
  }

  Future<{{name}}?> remoteGet(String id) async {
    final result = await client.collection('{{collectionId}}').getList(
      filter: "id = '$id'",
    );
    if (result.items.isEmpty) return null;
    return itemFromJson(result.items.first.toJson());
  }

  {{^hasQuery}}
  {{name}}? localGet(String id) {
    final rows = database.select(r"""
    SELECT * FROM `{{collectionName}}`
    WHERE `id` = ?
    """, [id]);
    if (rows.isEmpty) return null;
    return itemFromJson(rows.first);
  }

  int localAdd({
    String? id,
    {{#fields}}
    {{#required}}required {{/required}}{{type}}{{^required}}?{{/required}} {{name}},
    {{/fields}}
  }) {
    final $id = id ?? idGenerator();
    final now = DateTime.now().toUtc();
    database.execute(r"""
    INSERT INTO `{{collectionName}}` (
      `id`,
      {{#fields}}
      `{{name}}`,
      {{/fields}}
      `collectionId`,
      `collectionName`,
      `created`,
      `updated`
    ) VALUES (
      ?,
      {{#fields}}
      ?,
      {{/fields}}
      ?,
      ?,
      ?,
      ?
    )
    """, [
      $id,
      {{#fields}}
      {{name}},
      {{/fields}}
      '{{collectionId}}',
      '{{collectionName}}',
      now.toIso8601String(),
      now.toIso8601String(),
    ]);
    return database.lastInsertRowId;
  }

  int localUpdate({
    required String id,
    {{#fields}}
    {{#required}}required {{/required}}{{type}}{{^required}}?{{/required}} {{name}},
    {{/fields}}
  }) {
    final now = DateTime.now().toUtc();
    database.execute(r"""
    UPDATE `{{collectionName}}`
    SET
      {{#fields}}
      `{{name}}` = ?,
      {{/fields}}
      `updated` = ?
    WHERE `id` = ?
    """, [
      {{#fields}}
      {{name}},
      {{/fields}}
      now.toIso8601String(),
      id,
    ]);
    return database.lastInsertRowId;
  }

  void localDelete(String id) {
    database.execute(r"""
    DELETE FROM `{{collectionName}}`
    WHERE `id` = ?
    """, [id]);
  }

  Future<{{name}}?> remoteAdd({
    String? id,
    {{#fields}}
    {{#required}}required {{/required}}{{type}}{{^required}}?{{/required}} {{name}},
    {{/fields}}
  }) async {
    final $id = id ?? idGenerator();
    final result = await client.collection('{{collectionId}}').create(body: {
      'id': $id,
      {{#fields}}
      '{{description}}': {{name}},
      {{/fields}}
    });
    return itemFromJson(result.toJson());
  }

  Future<{{name}}?> remoteUpdate({
    required String id,
    {{#fields}}
    {{#required}}required {{/required}}{{type}}{{^required}}?{{/required}} {{name}},
    {{/fields}}
  }) async {
    final result = await client.collection('{{collectionId}}').update(
      id,
      body: {
        {{#fields}}
        '{{description}}': {{name}},
        {{/fields}}
      },
    );
    return itemFromJson(result.toJson());
  }

  Future<void> remoteDelete(String id) async {
    await client.collection('{{collectionId}}').delete(id);
  }
  {{/hasQuery}}
}
{{/classes}}
''';

class $File {
  final String filename;
  final List<$Class> classes;

  $File({
    required this.filename,
    required this.classes,
  });

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'classes': classes.map((e) => e.toJson()).toList(),
      'hasHive': classes.any((e) => e.hiveTypeAdapter != null),
    };
  }
}

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

class $Field {
  final String name;
  final String description;
  final bool isRequired;
  final bool isFinal;
  final String type;
  final List<String>? options;

  bool get isEnum => options != null && options!.isNotEmpty;

  $Field({
    required this.name,
    required this.description,
    required this.isRequired,
    required this.isFinal,
    required this.type,
    required this.options,
  });

  String get typeName {
    if (type == 'url') return 'Uri';
    if (type == 'select') return name.pascalCase;
    const stringTypes = ['text', 'file', 'relation', 'editor', 'email'];
    if (stringTypes.contains(type)) return 'String';
    if (type == 'bool') return 'bool';
    if (type == 'number') return 'num';
    if (type == 'date') return 'DateTime';
    return 'dynamic';
  }

  String get sql {
    const stringTypes = [
      'text',
      'file',
      'relation',
      'editor',
      'email',
      'url',
      'select',
      'date',
    ];
    if (stringTypes.contains(type)) return 'TEXT';
    if (type == 'bool') return 'INTEGER';
    if (type == 'number') return 'REAL';
    return '';
  }

  Map<String, dynamic> toJson(int? hiveType) {
    return {
      'name': name,
      if (hiveType != null) 'hiveType': hiveType,
      'description': description,
      'required': isRequired,
      'final': isFinal,
      'enum': isEnum,
      'options': options,
      'defaultValue': null,
      'type': typeName,
      'sql': sql,
    };
  }
}

String renderTemplate($File value) {
  final target = Template(template);
  final variables = value.toJson();
  // print(JsonEncoder.withIndent(' ').convert(variables));
  variables.addAll(mustache_recase.cases);
  final output = target.renderString(variables);
  return output;
}

List<$File> convertCollections(
  List<CollectionModel> collections,
  StorageType storage,
  bool hive,
) {
  final files = <$File>[];
  for (var i = 0; i < collections.length; i++) {
    final collection = collections[i];
    print(JsonEncoder.withIndent(' ').convert(collection));
    final file = $File(
      filename: collection.name.snakeCase,
      classes: [
        $Class(
          query: collection.options['query'] as String?,
          type: collection.type,
          description: collection.name,
          hiveTypeAdapter: hive ? i : null,
          name: collection.name.pascalCase,
          collectionId: collection.id,
          collectionName: collection.name,
          indexes: collection.indexes,
          fields: [
            for (final field in collection.schema)
              $Field(
                name: field.type == 'select'
                    ? field.name.camelCase
                    : '\$${field.name.camelCase}',
                description: field.name,
                isRequired: field.required,
                isFinal: true,
                type: field.type,
                options: field.type == 'select'
                    ? (field.options['values'] as List).cast<String>()
                    : [],
              ),
          ],
        ),
      ],
    );
    files.add(file);
  }
  return files;
}

enum StorageType {
  sqlite,
  sqflite,
}
