import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sqlite3/common.dart';

part 'messages.g.dart';

/// messages
@JsonSerializable()
class Messages {
  Messages({
    required this.id,
    required this.$message,
    required this.$author,
    this.collectionId = 'XTpascjA7jyzB88',
    this.collectionName = 'messages',
    required this.created,
    required this.updated,
  });

  final String id;

  final String collectionId;

  final String collectionName;

  final DateTime created;

  final DateTime updated;

  @JsonKey(name: 'message')
  final String $message;

  @JsonKey(name: 'author')
  final String $author;

  Map<String, dynamic> toJson() => _$MessagesToJson(this);

  factory Messages.fromJson(Map<String, dynamic> json) => _$MessagesFromJson(json);
}


class MessagesRepository {
  final PocketBase client;
  final CommonDatabase database;
  final String Function() idGenerator;

  MessagesRepository({
    required this.client,
    required this.database,
    required this.idGenerator,
  });

  void init() {
    database.execute(r"""
    BEGIN;
    CREATE TABLE `messages` (
      `id` TEXT NOT NULL,
      `$message` TEXT NOT NULL,
      `$author` TEXT NOT NULL,
      `collectionId` TEXT NOT NULL,
      `collectionName` TEXT NOT NULL,
      `created` TEXT NOT NULL,
      `updated` TEXT NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`collectionId`) REFERENCES `collections` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) WITHOUT ROWID;
    CREATE INDEX `messages_created_idx` ON `messages` (`created`);
    COMMIT;
    """);
  }

  Messages itemFromJson(Map<String, dynamic> json) {
    return Messages.fromJson(json);
  }

  List<Messages> localList() {
    final rows = database.select(r"""
    SELECT * FROM `messages`
    """);
    return rows.map((e) => itemFromJson(e)).toList();
  }

  int localCount() {
    final rows = database.select(r"""
    SELECT COUNT(*) FROM `messages`
    """);
    return rows.first['COUNT(*)'] as int;
  }

  Future<List<Messages>> remoteList() async {
    final records = await client.collection('XTpascjA7jyzB88').getFullList();
    return records.map((e) => itemFromJson(e.toJson())).toList();
  }

  Future<Messages?> remoteGet(String id) async {
    final result = await client.collection('XTpascjA7jyzB88').getList(
      filter: "id = '$id'",
    );
    if (result.items.isEmpty) return null;
    return itemFromJson(result.items.first.toJson());
  }

  Messages? localGet(String id) {
    final rows = database.select(r"""
    SELECT * FROM `messages`
    WHERE `id` = ?
    """, [id]);
    if (rows.isEmpty) return null;
    return itemFromJson(rows.first);
  }

  int localAdd({
    String? id,
    required String $message,
    required String $author,
  }) {
    final $id = id ?? idGenerator();
    final now = DateTime.now().toUtc();
    database.execute(r"""
    INSERT INTO `messages` (
      `id`,
      `$message`,
      `$author`,
      `collectionId`,
      `collectionName`,
      `created`,
      `updated`
    ) VALUES (
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?
    )
    """, [
      $id,
      $message,
      $author,
      'XTpascjA7jyzB88',
      'messages',
      now.toIso8601String(),
      now.toIso8601String(),
    ]);
    return database.lastInsertRowId;
  }

  int localUpdate({
    required String id,
    required String $message,
    required String $author,
  }) {
    final now = DateTime.now().toUtc();
    database.execute(r"""
    UPDATE `messages`
    SET
      `$message` = ?,
      `$author` = ?,
      `updated` = ?
    WHERE `id` = ?
    """, [
      $message,
      $author,
      now.toIso8601String(),
      id,
    ]);
    return database.lastInsertRowId;
  }

  void localDelete(String id) {
    database.execute(r"""
    DELETE FROM `messages`
    WHERE `id` = ?
    """, [id]);
  }

  Future<Messages?> remoteAdd({
    String? id,
    required String $message,
    required String $author,
  }) async {
    final $id = id ?? idGenerator();
    final result = await client.collection('XTpascjA7jyzB88').create(body: {
      'id': $id,
      'message': $message,
      'author': $author,
    });
    return itemFromJson(result.toJson());
  }

  Future<Messages?> remoteUpdate({
    required String id,
    required String $message,
    required String $author,
  }) async {
    final result = await client.collection('XTpascjA7jyzB88').update(
      id,
      body: {
        'message': $message,
        'author': $author,
      },
    );
    return itemFromJson(result.toJson());
  }

  Future<void> remoteDelete(String id) async {
    await client.collection('XTpascjA7jyzB88').delete(id);
  }
}
