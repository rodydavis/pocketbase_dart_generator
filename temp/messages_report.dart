import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sqlite3/common.dart';

part 'messages_report.g.dart';

/// messagesReport
@JsonSerializable()
class MessagesReport {
  MessagesReport({
    required this.id,
    required this.$author,
    this.$total,
    this.collectionId = '52zrtrl7k3z6sbl',
    this.collectionName = 'messagesReport',
    required this.created,
    required this.updated,
  });

  final String id;

  final String collectionId;

  final String collectionName;

  final DateTime created;

  final DateTime updated;

  @JsonKey(name: 'author')
  final String $author;

  @JsonKey(name: 'total')
  final num? $total;

  Map<String, dynamic> toJson() => _$MessagesReportToJson(this);

  factory MessagesReport.fromJson(Map<String, dynamic> json) => _$MessagesReportFromJson(json);
}


class MessagesReportRepository {
  final PocketBase client;
  final CommonDatabase database;
  final String Function() idGenerator;

  MessagesReportRepository({
    required this.client,
    required this.database,
    required this.idGenerator,
  });

  void init() {
    database.execute(r"""
    BEGIN;
    CREATE TABLE `messagesReport` (
      `id` TEXT NOT NULL,
      `$author` TEXT NOT NULL,
      `$total` REAL ,
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

  MessagesReport itemFromJson(Map<String, dynamic> json) {
    return MessagesReport.fromJson(json);
  }

  List<MessagesReport> localList() {
    final rows = database.select(r"""
    SELECT
  (ROW_NUMBER() OVER()) as id,
  messages.author,
  count(messages.id) as total
FROM messages
GROUP BY messages.author
    """);
    return rows.map((e) => itemFromJson(e)).toList();
  }

  int localCount() {
    final rows = database.select(r"""
    SELECT COUNT(*) FROM `messagesReport`
    """);
    return rows.first['COUNT(*)'] as int;
  }

  Future<List<MessagesReport>> remoteList() async {
    final records = await client.collection('52zrtrl7k3z6sbl').getFullList();
    return records.map((e) => itemFromJson(e.toJson())).toList();
  }

  Future<MessagesReport?> remoteGet(String id) async {
    final result = await client.collection('52zrtrl7k3z6sbl').getList(
      filter: "id = '$id'",
    );
    if (result.items.isEmpty) return null;
    return itemFromJson(result.items.first.toJson());
  }

}
