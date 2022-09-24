import 'package:pocketbase/pocketbase.dart';
import 'package:hive/hive.dart';

import 'collections/index.dart' as col;
import 'collections/base.dart';

class HiveClient {
  HiveClient(this.client);
  final PocketBase client;

  late final Box<col.Profiles> profilesBox;
  late final Box<col.Posts> postsBox;
  late final Box<col.Messages> messagesBox;

  Future<void> init() async {
    registerAdapters();
    await openBoxes();
  }

  Future<void> openBoxes() async {
    profilesBox = await Hive.openBox<col.Profiles>('profiles');
    postsBox = await Hive.openBox<col.Posts>('posts');
    messagesBox = await Hive.openBox<col.Messages>('messages');
  }

  void registerAdapters() {
    Hive.registerAdapter(col.ProfilesAdapter());
    Hive.registerAdapter(col.PostsAdapter());
    Hive.registerAdapter(col.MessagesAdapter());
  }

  Future<List<col.Profiles>> getProfiles() =>
     getItems<col.Profiles>('profiles', profilesBox, col.Profiles.fromJson);

  Future<List<col.Posts>> getPosts() =>
     getItems<col.Posts>('posts', postsBox, col.Posts.fromJson);

  Future<List<col.Messages>> getMessages() =>
     getItems<col.Messages>('messages', messagesBox, col.Messages.fromJson);

  Future<List<T>> getItems<T extends CollectionBase>(
    String name,
    Box<T> box,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    String? filter;
    final latest = box.isEmpty
        ? null
        : box.values.reduce((a, b) => a.updated.isAfter(b.updated) ? a : b);
    if (latest != null) {
      final d = latest.updated;
      filter = "updated > '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')} UTC'";
    }
    final records = await client.records.getFullList(
      name,
      filter: filter,
    );
    for (final record in records) {
      final item = fromJson(record.toJson());
      await box.put(item.id, item);
    }
    return box.values.toList();
  }
}

extension RecordModelUtils on RecordModel {
  col.Profiles asProfiles() =>  col.Profiles.fromJson(toJson());
  col.Posts asPosts() =>  col.Posts.fromJson(toJson());
  col.Messages asMessages() =>  col.Messages.fromJson(toJson());
}

