import 'package:args/args.dart';
import 'package:pocketbase_dart_generator/pocketbase_dart_generator.dart';

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
      abbr: 'l',
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
        'hive',
        'sqlite',
        'sqflite',
        'memory',
      ],
      valueHelp: 'sqlite',
      defaultsTo: 'memory',
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

  // Create client
  final client = PocketBaseGenerator(
    url,
    authenticate: (client) => client.admins.authViaEmail(username, password),
    verbose: verbose,
    output: output,
  );

  // Generate files
  await client.generate(storageType);

  if (verbose) print('Done');
}
