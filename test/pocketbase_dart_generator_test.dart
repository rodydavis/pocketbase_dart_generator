import 'dart:io';

import 'package:pocketbase_dart_generator/pocketbase_dart_generator.dart';
import 'package:test/test.dart';

void main() {
  final outDir = Directory('test/generated');
  late PocketBaseGenerator client;

  setUp(() async {
    client = PocketBaseGenerator(
      'https://pocketbase.io',
      authenticate: (client) => client.admins.authViaEmail(
        'test@example.com',
        '123456',
      ),
      output: outDir.path,
    );
  });

  test('hive generate test', () async {
    await client.generate(hive: true);

    final collectionsDir = Directory('${outDir.path}/collections');

    // Run process: dart run build_runner build
    await Process.run('dart', ['run', 'build_runner', 'build']);

    final collections = await client.client.collections.getFullList();

    // Check collections
    for (final collection in collections) {
      final file = File('${collectionsDir.path}/${collection.name}.dart');
      expect(file.existsSync(), true);
    }

    expect(outDir.existsSync(), true);
  });

  tearDown(() async {
    await outDir.delete(recursive: true);
  });
}
