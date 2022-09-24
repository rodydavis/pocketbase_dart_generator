import 'dart:io';

import 'package:pocketbase_dart_generator/pocketbase_dart_generator.dart';
import 'package:test/test.dart';

void main() {
  final outDir = Directory('test/generated');
  late PocketBaseGenerator client;

  setUp(() async {
    client = PocketBaseGenerator(
      'POCKETBASE_URL',
      login: (client) => client.admins.authViaEmail(
        'ADMIN_USERNAME',
        'ADMIN_PASSWORD',
      ),
      output: outDir.path,
    );
  });

  test('generate', () async {
    await client.generate();
    expect(outDir.existsSync(), true);
  });

  tearDown(() async {
    await outDir.delete(recursive: true);
  });
}
