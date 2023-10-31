import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sqlite3/common.dart';

part 'books.g.dart';

/// Books
@JsonSerializable()
class Books {
  Books({
    required this.id,
    this.$title,
    this.$author,
    this.$date,
    this.$content,
    this.collectionId = 'e45os9y41gf8w5t',
    this.collectionName = 'Books',
    required this.created,
    required this.updated,
  });

  final String id;

  final String collectionId;

  final String collectionName;

  final DateTime created;

  final DateTime updated;

  @JsonKey(name: 'title')
  final String? $title;

  @JsonKey(name: 'author')
  final String? $author;

  @JsonKey(name: 'date')
  final DateTime? $date;

  @JsonKey(name: 'content')
  final String? $content;

  Map<String, dynamic> toJson() => _$BooksToJson(this);

  factory Books.fromJson(Map<String, dynamic> json) => _$BooksFromJson(json);
}


class BooksRepository {
  final PocketBase client;
  final CommonDatabase database;
  final String Function() idGenerator;

  BooksRepository({
    required this.client,
    required this.database,
    required this.idGenerator,
  });

  void init() {
    database.execute(r"""
    BEGIN;
    CREATE TABLE `Books` (
      `id` TEXT NOT NULL,
      `$title` TEXT ,
      `$author` TEXT ,
      `$date` TEXT ,
      `$content` TEXT ,
      `collectionId` TEXT NOT NULL,
      `collectionName` TEXT NOT NULL,
      `created` TEXT NOT NULL,
      `updated` TEXT NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`collectionId`) REFERENCES `collections` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) WITHOUT ROWID;
    COMMIT;
    """);
  }

  Books itemFromJson(Map<String, dynamic> json) {
    return Books.fromJson(json);
  }

  List<Books> localList() {
    final rows = database.select(r"""
    SELECT * FROM `Books`
    """);
    return rows.map((e) => itemFromJson(e)).toList();
  }

  int localCount() {
    final rows = database.select(r"""
    SELECT COUNT(*) FROM `Books`
    """);
    return rows.first['COUNT(*)'] as int;
  }

  Future<List<Books>> remoteList() async {
    final records = await client.collection('e45os9y41gf8w5t').getFullList();
    return records.map((e) => itemFromJson(e.toJson())).toList();
  }

  Future<Books?> remoteGet(String id) async {
    final result = await client.collection('e45os9y41gf8w5t').getList(
      filter: "id = '$id'",
    );
    if (result.items.isEmpty) return null;
    return itemFromJson(result.items.first.toJson());
  }

  Books? localGet(String id) {
    final rows = database.select(r"""
    SELECT * FROM `Books`
    WHERE `id` = ?
    """, [id]);
    if (rows.isEmpty) return null;
    return itemFromJson(rows.first);
  }

  int localAdd({
    String? id,
    String? $title,
    String? $author,
    DateTime? $date,
    String? $content,
  }) {
    final $id = id ?? idGenerator();
    final now = DateTime.now().toUtc();
    database.execute(r"""
    INSERT INTO `Books` (
      `id`,
      `$title`,
      `$author`,
      `$date`,
      `$content`,
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
      ?,
      ?,
      ?
    )
    """, [
      $id,
      $title,
      $author,
      $date,
      $content,
      'e45os9y41gf8w5t',
      'Books',
      now.toIso8601String(),
      now.toIso8601String(),
    ]);
    return database.lastInsertRowId;
  }

  int localUpdate({
    required String id,
    String? $title,
    String? $author,
    DateTime? $date,
    String? $content,
  }) {
    final now = DateTime.now().toUtc();
    database.execute(r"""
    UPDATE `Books`
    SET
      `$title` = ?,
      `$author` = ?,
      `$date` = ?,
      `$content` = ?,
      `updated` = ?
    WHERE `id` = ?
    """, [
      $title,
      $author,
      $date,
      $content,
      now.toIso8601String(),
      id,
    ]);
    return database.lastInsertRowId;
  }

  void localDelete(String id) {
    database.execute(r"""
    DELETE FROM `Books`
    WHERE `id` = ?
    """, [id]);
  }

  Future<Books?> remoteAdd({
    String? id,
    String? $title,
    String? $author,
    DateTime? $date,
    String? $content,
  }) async {
    final $id = id ?? idGenerator();
    final result = await client.collection('e45os9y41gf8w5t').create(body: {
      'id': $id,
      'title': $title,
      'author': $author,
      'date': $date,
      'content': $content,
    });
    return itemFromJson(result.toJson());
  }

  Future<Books?> remoteUpdate({
    required String id,
    String? $title,
    String? $author,
    DateTime? $date,
    String? $content,
  }) async {
    final result = await client.collection('e45os9y41gf8w5t').update(
      id,
      body: {
        'title': $title,
        'author': $author,
        'date': $date,
        'content': $content,
      },
    );
    return itemFromJson(result.toJson());
  }

  Future<void> remoteDelete(String id) async {
    await client.collection('e45os9y41gf8w5t').delete(id);
  }
}
