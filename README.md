# Pocketbase Dart Generator

Generate `json_serializable` and `hive_generator` classes for use with PocketBase client and app caching.

## Library Usage

Create an instance of the client:

```dart
final client = PocketBaseGenerator(
  'POCKETBASE_URL',
  login: (client) => client.admins.authViaEmail(
    'ADMIN_USERNAME',
    'ADMIN_PASSWORD',
  ),
);
```

Then call the generate function to create files at the specified output directory:

```dart
await client.generate();
```

## CLI Usage

Clone the repo locally and run the following command:

```bash
dart bin/pocketbase_dart_generator.dart -u ADMIN_USERNAME -p ADMIN_PASSWORD -l POCKETBASE_URL
```
