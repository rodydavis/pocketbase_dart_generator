import 'package:args/args.dart';
import 'package:pocketbase_dart_generator/pocketbase_dart_generator.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'username',
      abbr: 'u',
      help: 'Username',
      valueHelp: 'username',
      mandatory: true,
    )
    ..addOption(
      'password',
      abbr: 'p',
      help: 'Password',
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
    ..addFlag(
      'hive',
      abbr: 'h',
      help: 'Hive classes',
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
  final hive = args['hive'] as bool;
  final verbose = args['verbose'] as bool;

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
  );

  // Generate files
  await client.generate(hive: hive);

  if (verbose) print('Done');
}
