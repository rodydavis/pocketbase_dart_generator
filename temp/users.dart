import 'package:json_annotation/json_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:sqlite3/common.dart';

part 'users.g.dart';

/// users
@JsonSerializable()
class Users {
  Users({
    required this.id,
    this.$name,
    this.$avatar,
    this.$website,
    this.collectionId = 'POWMOh0W6IoLUAI',
    this.collectionName = 'users',
    required this.created,
    required this.updated,
  });

  final String id;

  final String collectionId;

  final String collectionName;

  final DateTime created;

  final DateTime updated;

  @JsonKey(name: 'name')
  final String? $name;

  @JsonKey(name: 'avatar')
  final String? $avatar;

  @JsonKey(name: 'website')
  final Uri? $website;

  Map<String, dynamic> toJson() => _$UsersToJson(this);

  factory Users.fromJson(Map<String, dynamic> json) => _$UsersFromJson(json);
}


class UsersRepository {
  final PocketBase client;
  final CommonDatabase database;
  final String Function() idGenerator;

  UsersRepository({
    required this.client,
    required this.database,
    required this.idGenerator,
  });

  void init() {
    database.execute(r"""
    BEGIN;
    CREATE TABLE `users` (
      `id` TEXT NOT NULL,
      `name` TEXT,
      `avatar` TEXT,
      `website` TEXT,
      `collectionId` TEXT NOT NULL,
      `collectionName` TEXT NOT NULL,
      `created` TEXT NOT NULL,
      `updated` TEXT NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`collectionId`) REFERENCES `_collections` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) WITHOUT ROWID;
    CREATE INDEX `_POWMOh0W6IoLUAI_created_idx` ON `users` (`created`);
    COMMIT;
    """);
  }

  Users itemFromJson(Map<String, dynamic> json) {
    return Users.fromJson(json);
  }

  List<Users> localList() {
    final rows = database.select(r"""
    SELECT * FROM `users`
    """);
    return rows.map((e) => itemFromJson(e)).toList();
  }

  int localCount() {
    final rows = database.select(r"""
    SELECT COUNT(*) FROM `users`
    """);
    return rows.first['COUNT(*)'] as int;
  }

  Future<List<Users>> remoteList() async {
    final records = await client.collection('POWMOh0W6IoLUAI').getFullList();
    return records.map((e) => itemFromJson(e.toJson())).toList();
  }

  Future<Users?> remoteGet(String id) async {
    final result = await client.collection('POWMOh0W6IoLUAI').getList(
      filter: "id = '$id'",
    );
    if (result.items.isEmpty) return null;
    return itemFromJson(result.items.first.toJson());
  }

  Users? localGet(String id) {
    final rows = database.select(r"""
    SELECT * FROM `users`
    WHERE `id` = ?
    """, [id]);
    if (rows.isEmpty) return null;
    return itemFromJson(rows.first);
  }

  int localAdd({
    String? id,
    String? $name,
    String? $avatar,
    Uri? $website,
  }) {
    final $id = id ?? idGenerator();
    final now = DateTime.now().toUtc();
    database.execute(r"""
    INSERT INTO `users` (
      `id`,
      `name`,
      `avatar`,
      `website`,
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
      ?
    )
    """, [
      $id,
      $name,
      $avatar,
      $website,
      'POWMOh0W6IoLUAI',
      'users',
      now.toIso8601String(),
      now.toIso8601String(),
    ]);
    return database.lastInsertRowId;
  }

  int localUpdate({
    required String id,
    String? $name,
    String? $avatar,
    Uri? $website,
  }) {
    final now = DateTime.now().toUtc();
    database.execute(r"""
    UPDATE `users`
    SET
      `name` = ?,
      `avatar` = ?,
      `website` = ?,
      `updated` = ?
    WHERE `id` = ?
    """, [
      $name,
      $avatar,
      $website,
      now.toIso8601String(),
      id,
    ]);
    return database.lastInsertRowId;
  }

  void localDelete(String id) {
    database.execute(r"""
    DELETE FROM `users`
    WHERE `id` = ?
    """, [id]);
  }

  Future<Users?> remoteAdd({
    String? id,
    String? $name,
    String? $avatar,
    Uri? $website,
    List<http.MultipartFile> files = const [],
  }) async {
    final $id = id ?? idGenerator();
    final result = await client.collection('POWMOh0W6IoLUAI').create(
      body: {
        'id': $id,
        'name': $name,
        'avatar': $avatar,
        'website': $website,
      }, 
      files: files
    );
    return itemFromJson(result.toJson());
  }

  Future<Users?> remoteUpdate({
    required String id,
    String? $name,
    String? $avatar,
    Uri? $website,
    List<http.MultipartFile> files = const [],
  }) async {
    final result = await client.collection('POWMOh0W6IoLUAI').update(
      id,
      body: {
        'name': $name,
        'avatar': $avatar,
        'website': $website,
      },
      files: files,
    );
    return itemFromJson(result.toJson());
  }

  Future<void> remoteDelete(String id) async {
    await client.collection('POWMOh0W6IoLUAI').delete(id);
  }
}
