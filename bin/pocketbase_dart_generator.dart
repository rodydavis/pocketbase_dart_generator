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
    );

  // CLI Args
  final args = parser.parse(arguments);
  final url = args['url'] as String;
  final username = args['username'] as String;
  final password = args['password'] as String;

  print('Generating PocketBase Dart classes for $url');

  if (url.isEmpty || username.isEmpty || password.isEmpty) {
    print('Missing arguments');
    return;
  }

  // Create client
  final client = PocketBaseGenerator(
    url,
    login: (client) => client.admins.authViaEmail(username, password),
  );

  // Generate files
  await client.generate();
}
