import 'package:json_annotation/json_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:sqlite3/common.dart';

part 'posts.g.dart';

/// posts
@JsonSerializable()
class Posts {
  Posts({
    required this.id,
    required this.$title,
    this.$description,
    this.$active,
    this.options,
    this.$featuredImages,
    this.collectionId = 'BHKW36mJl3ZPt6z',
    this.collectionName = 'posts',
    required this.created,
    required this.updated,
  });

  final String id;

  final String collectionId;

  final String collectionName;

  final DateTime created;

  final DateTime updated;

  @JsonKey(name: 'title')
  final String $title;

  @JsonKey(name: 'description')
  final String? $description;

  @JsonKey(name: 'active')
  final bool? $active;

  @JsonKey(name: 'options')
  final Options? options;

  @JsonKey(name: 'featuredImages')
  final String? $featuredImages;

  Map<String, dynamic> toJson() => _$PostsToJson(this);

  factory Posts.fromJson(Map<String, dynamic> json) => _$PostsFromJson(json);
}

/// options
enum Options {
  $optionA,
  $optionB,
  $optionC,
}

extension OptionsUtils on Options {
  String get name {
    switch (this) {
      case Options.$optionA:
        return 'optionA';
      case Options.$optionB:
        return 'optionB';
      case Options.$optionC:
        return 'optionC';
    }
  }
}

class PostsRepository {
  final PocketBase client;
  final CommonDatabase database;
  final String Function() idGenerator;

  PostsRepository({
    required this.client,
    required this.database,
    required this.idGenerator,
  });

  void init() {
    database.execute(r"""
    BEGIN;
    CREATE TABLE `posts` (
      `id` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `description` TEXT,
      `active` INTEGER,
      `options` TEXT,
      `featuredImages` TEXT,
      `collectionId` TEXT NOT NULL,
      `collectionName` TEXT NOT NULL,
      `created` TEXT NOT NULL,
      `updated` TEXT NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`collectionId`) REFERENCES `_collections` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) WITHOUT ROWID;
    CREATE INDEX `posts_created_idx` ON `posts` (`created`);
    COMMIT;
    """);
  }

  Posts itemFromJson(Map<String, dynamic> json) {
    return Posts.fromJson(json);
  }

  List<Posts> localList() {
    final rows = database.select(r"""
    SELECT * FROM `posts`
    """);
    return rows.map((e) => itemFromJson(e)).toList();
  }

  int localCount() {
    final rows = database.select(r"""
    SELECT COUNT(*) FROM `posts`
    """);
    return rows.first['COUNT(*)'] as int;
  }

  Future<List<Posts>> remoteList() async {
    final records = await client.collection('BHKW36mJl3ZPt6z').getFullList();
    return records.map((e) => itemFromJson(e.toJson())).toList();
  }

  Future<Posts?> remoteGet(String id) async {
    final result = await client.collection('BHKW36mJl3ZPt6z').getList(
      filter: "id = '$id'",
    );
    if (result.items.isEmpty) return null;
    return itemFromJson(result.items.first.toJson());
  }

  Posts? localGet(String id) {
    final rows = database.select(r"""
    SELECT * FROM `posts`
    WHERE `id` = ?
    """, [id]);
    if (rows.isEmpty) return null;
    return itemFromJson(rows.first);
  }

  int localAdd({
    String? id,
    required String $title,
    String? $description,
    bool? $active,
    Options? options,
    String? $featuredImages,
  }) {
    final $id = id ?? idGenerator();
    final now = DateTime.now().toUtc();
    database.execute(r"""
    INSERT INTO `posts` (
      `id`,
      `title`,
      `description`,
      `active`,
      `options`,
      `featuredImages`,
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
      ?,
      ?
    )
    """, [
      $id,
      $title,
      $description,
      $active,
      options,
      $featuredImages,
      'BHKW36mJl3ZPt6z',
      'posts',
      now.toIso8601String(),
      now.toIso8601String(),
    ]);
    return database.lastInsertRowId;
  }

  int localUpdate({
    required String id,
    required String $title,
    String? $description,
    bool? $active,
    Options? options,
    String? $featuredImages,
  }) {
    final now = DateTime.now().toUtc();
    database.execute(r"""
    UPDATE `posts`
    SET
      `title` = ?,
      `description` = ?,
      `active` = ?,
      `options` = ?,
      `featuredImages` = ?,
      `updated` = ?
    WHERE `id` = ?
    """, [
      $title,
      $description,
      $active,
      options,
      $featuredImages,
      now.toIso8601String(),
      id,
    ]);
    return database.lastInsertRowId;
  }

  void localDelete(String id) {
    database.execute(r"""
    DELETE FROM `posts`
    WHERE `id` = ?
    """, [id]);
  }

  Future<Posts?> remoteAdd({
    String? id,
    required String $title,
    String? $description,
    bool? $active,
    Options? options,
    String? $featuredImages,
    List<http.MultipartFile> files = const [],
  }) async {
    final $id = id ?? idGenerator();
    final result = await client.collection('BHKW36mJl3ZPt6z').create(
      body: {
        'id': $id,
        'title': $title,
        'description': $description,
        'active': $active,
        'options': options,
        'featuredImages': $featuredImages,
      }, 
      files: files
    );
    return itemFromJson(result.toJson());
  }

  Future<Posts?> remoteUpdate({
    required String id,
    required String $title,
    String? $description,
    bool? $active,
    Options? options,
    String? $featuredImages,
    List<http.MultipartFile> files = const [],
  }) async {
    final result = await client.collection('BHKW36mJl3ZPt6z').update(
      id,
      body: {
        'title': $title,
        'description': $description,
        'active': $active,
        'options': options,
        'featuredImages': $featuredImages,
      },
      files: files,
    );
    return itemFromJson(result.toJson());
  }

  Future<void> remoteDelete(String id) async {
    await client.collection('BHKW36mJl3ZPt6z').delete(id);
  }
}
