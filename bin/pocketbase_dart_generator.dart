import 'dart:io';

import 'package:args/args.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pocketbase_dart_generator/src/data/source/templates/collection.dart';
import 'package:pocketbase_dart_generator/src/domain/usecase/convert_collections_to_files.dart';
import 'package:pocketbase_dart_generator/src/domain/usecase/render_file_template.dart';
import 'package:pocketbase_dart_generator/src/generator.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'username',
      abbr: 'u',
      help: 'Admin Username',
      valueHelp: 'username',
      mandatory: true,
    )
    ..addOption(
      'password',
      abbr: 'p',
      help: 'Admin Password',
      valueHelp: 'password',
      mandatory: true,
    )
    ..addOption(
      'url',
      help: 'Url',
      valueHelp: 'url',
      mandatory: true,
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output',
      valueHelp: 'output',
      defaultsTo: 'lib/generated',
    )
    ..addOption(
      'storage',
      abbr: 's',
      help: 'Storage Type',
      allowed: [
        'sqlite',
        'sqflite',
      ],
      valueHelp: 'sqlite',
      defaultsTo: 'sqlite',
    )
    ..addFlag(
      'hive',
      help: 'Hive types',
      defaultsTo: false,
    )
    ..addFlag(
      'verbose',
      help: 'Verbose output',
      defaultsTo: false,
    );

  // CLI Args
  final args = parser.parse(arguments);
  final url = args['url'] as String;
  final username = args['username'] as String;
  final password = args['password'] as String;
  final verbose = args['verbose'] as bool;
  final hive = args['hive'] as bool;
  final output = args['output'] as String;
  final storage = args['storage'] as String;
  final storageType = StorageType.values.firstWhere((e) => e.name == storage);

  if (verbose) {
    print('Generating PocketBase Dart classes for $url');
  }

  if (url.isEmpty || username.isEmpty || password.isEmpty) {
    if (verbose) print('Missing arguments');
    return;
  }

  final dir = Directory(output);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
  }
  final pb = PocketBase(url);
  await pb.admins.authWithPassword(username, password);
  final collections = await pb.collections.getFullList();
  final files = ConvertCollectionsToFiles().execute(
    collections,
    storageType,
    hive,
  );
  for (final value in files) {
    final str = RenderFileTemplate(COLLECTION_TEMPLATE).execute(value);
    final file = File('${dir.path}/${value.filename}.dart');
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(str);
  }

  if (verbose) print('Done');
}
