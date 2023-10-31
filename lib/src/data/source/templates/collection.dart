final COLLECTION_TEMPLATE = r'''
import 'package:json_annotation/json_annotation.dart';
{{#hasHive}}
import 'package:hive/hive.dart';
{{/hasHive}}
import 'package:http/http.dart' as http;
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
      `{{description}}` {{sql}}{{#required}} NOT NULL{{/required}},
      {{/fields}}
      `collectionId` TEXT NOT NULL,
      `collectionName` TEXT NOT NULL,
      `created` TEXT NOT NULL,
      `updated` TEXT NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`collectionId`) REFERENCES `_collections` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
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
      `{{description}}`,
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
      `{{description}}` = ?,
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
    List<http.MultipartFile> files = const [],
  }) async {
    final $id = id ?? idGenerator();
    final result = await client.collection('{{collectionId}}').create(
      body: {
        'id': $id,
        {{#fields}}
        '{{description}}': {{name}},
        {{/fields}}
      }, 
      files: files
    );
    return itemFromJson(result.toJson());
  }

  Future<{{name}}?> remoteUpdate({
    required String id,
    {{#fields}}
    {{#required}}required {{/required}}{{type}}{{^required}}?{{/required}} {{name}},
    {{/fields}}
    List<http.MultipartFile> files = const [],
  }) async {
    final result = await client.collection('{{collectionId}}').update(
      id,
      body: {
        {{#fields}}
        '{{description}}': {{name}},
        {{/fields}}
      },
      files: files,
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
