import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:pocketbase/pocketbase.dart';
import 'package:recase/recase.dart';

import 'converters.dart';

class PocketBaseGenerator {
  PocketBaseGenerator(
    this.url, {
    this.lang = "en-US",
    this.output = 'lib/generated',
    required this.login,
  });

  final String url;
  final String lang;
  final String output;

  final Future<AdminAuth> Function(PocketBase client) login;

  late final Directory outputDir = Directory(output);
  late final Directory collectionsDir =
      Directory('${outputDir.path}/collections');
  late final PocketBase client = PocketBase(url, lang: lang);

  String _getDartType(SchemaField field) {
    String type = 'dynamic';
    switch (field.type) {
      case 'text':
      case 'email':
      case 'url':
      case 'user':
        type = 'String';
        break;
      case 'number':
        type = 'num';
        break;
      case 'bool':
        type = 'bool';
        break;
      case 'relation':
        type = 'String';
        break;
      case 'date':
        type = 'DateTime';
        break;
      // Could be list or map
      case 'json':
        // Type not supported yet
        break;
      case 'file':
      case 'select':
        if (field.options['maxSelect'] == 1) {
          type = 'String';
        } else {
          type = 'List<String>';
        }
        break;
      default:
        print('Unknown type: ${field.type} for ${field.name}');
    }
    if (!field.required && type != 'dynamic') {
      // Make optional for null safety
      type = '$type?';
    }
    return type;
  }

  Future<void> _createCollection(
    bool hive,
    CollectionModel collection,
    int index,
  ) async {
    print('Generating ${collection.name}...');
    final file = File('${collectionsDir.path}/${collection.name}.dart');
    await file.create(recursive: true);
    final sb = StringBuffer();

    // Generate JSON and Hive
    final dartClassName = collection.name.pascalCase;
    final schema = collection.schema;
    schema.insert(
      0,
      SchemaField(name: 'id', type: 'text', required: true, unique: true),
    );
    schema.add(SchemaField(name: 'created', type: 'date', required: true));
    schema.add(SchemaField(name: 'updated', type: 'date', required: true));
    final adapters = await _getHiveInfo(
      hive,
      File('${collectionsDir.path}/${collection.name}.json'),
      schema.map((e) => e.name.camelCase).toList(),
    );

    // Generate Class
    sb.writeln('import \'package:json_annotation/json_annotation.dart\';');
    if (hive) {
      sb.writeln('import \'package:hive/hive.dart\';');
    }
    sb.writeln();
    sb.writeln('import \'base.dart\';');
    sb.writeln();
    sb.writeln('part \'${collection.name}.g.dart\';');
    sb.writeln();
    if (hive) {
      sb.writeln('@HiveType(typeId: $index)');
    }
    sb.writeln('@JsonSerializable()');
    sb.writeln('class $dartClassName extends CollectionBase {');

    // Generate constructor
    sb.writeln('  const $dartClassName({');
    for (final field in schema) {
      sb.writeln('    required this.${field.name.camelCase},');
    }
    sb.writeln('  });');
    sb.writeln();

    // Generate fields
    for (final field in schema) {
      if (hive) {
        final idx = adapters[field.name.camelCase];
        sb.writeln('  @HiveField($idx)');
      }
      final dartType = _getDartType(field);
      sb.write('  @JsonKey(name: \'${field.name}\'');
      switch (dartType) {
        case 'String':
        case 'String?':
          sb.write(', fromJson: getStringValue');
          break;
        case 'bool':
        case 'bool?':
          sb.write(', fromJson: getBoolValue');
          break;
        case 'num':
        case 'num?':
          sb.write(', fromJson: getDoubleValue');
          break;
        default:
      }
      sb.writeln(')');
      if (['id', 'created', 'updated'].contains(field.name)) {
        sb.writeln('  @override');
      }
      sb.writeln('  final $dartType ${field.name.camelCase};');
      sb.writeln();
    }

    // Generate toJson
    sb.writeln(
        '  Map<String, dynamic> toJson() => _\$${dartClassName}ToJson(this);');
    sb.writeln();

    // Generate fromJson
    sb.writeln(
        '  factory $dartClassName.fromJson(Map<String, dynamic> json) => _\$${dartClassName}FromJson(json);');

    // Close class
    sb.writeln('}');
    sb.writeln();

    // Write file
    await file.writeAsString(sb.toString());
  }

  Future<void> _createBase() async {
    print('Generating base...');
    final file = File('${collectionsDir.path}/base.dart');
    await file.create(recursive: true);
    final sb = StringBuffer();

    // Generate Base class
    sb.writeln('abstract class CollectionBase {');
    sb.writeln('  const CollectionBase();');
    sb.writeln('  String get id;');
    sb.writeln('  DateTime get created;');
    sb.writeln('  DateTime get updated;');

    // Close class
    sb.writeln('}');
    sb.writeln();
    sb.writeln(converters);
    sb.writeln();

    // Write file
    await file.writeAsString(sb.toString());
  }

  Future<void> _createCollectionIndex(
    bool hive,
    List<CollectionModel> collections,
  ) async {
    final file = File('${collectionsDir.path}/index.dart');
    final sb = StringBuffer();
    for (final collection in collections) {
      sb.writeln('export \'${collection.name}.dart\';');
    }
    await file.create(recursive: true);
    await file.writeAsString(sb.toString());
  }

  Future<void> _createClient(
    bool hive,
    List<CollectionModel> collections,
  ) async {
    final file = File('${outputDir.path}/client.dart');
    final sb = StringBuffer();
    sb.writeln('import \'package:pocketbase/pocketbase.dart\';');
    if (hive) {
      sb.writeln('import \'package:hive/hive.dart\';');
    }
    sb.writeln();
    sb.writeln('import \'collections/index.dart\' as col;');
    sb.writeln();
    if (hive) {
      // Register Hive adapters
      sb.writeln('void registerHiveAdapters() {');
      for (final collection in collections) {
        final dartClassName = collection.name.pascalCase;
        sb.writeln('  Hive.registerAdapter(col.${dartClassName}Adapter());');
      }
      sb.writeln('}');
    }
    sb.writeln();
    sb.writeln('extension RecordModelUtils on RecordModel {');
    for (final collection in collections) {
      final dartClassName = collection.name.pascalCase;
      sb.write('  col.$dartClassName as$dartClassName() => ');
      sb.writeln(' col.$dartClassName.fromJson(toJson());');
    }
    sb.writeln('}');

    sb.writeln();
    await file.create(recursive: true);
    file.writeAsString(sb.toString());
  }

  Future<void> generate({bool hive = true}) async {
    await login(client);
    outputDir.check();
    final collections = await client.collections.getFullList();
    collectionsDir.check();
    await _createBase();
    final adapters = await _getHiveInfo(
      hive,
      File('${outputDir.path}/adapters.json'),
      collections.map((e) => e.name.pascalCase).toList(),
    );
    final futures = <Future>[];
    for (final collection in collections) {
      final idx = adapters[collection.name.pascalCase]!;
      futures.add(_createCollection(hive, collection, idx));
    }
    await Future.wait(futures);
    await _createCollectionIndex(hive, collections);
    await _createClient(hive, collections);
  }
}

extension on Directory {
  void check() {
    if (!existsSync()) {
      createSync(recursive: true);
    }
  }
}

Future<Map<String, int>> _getHiveInfo(
  bool hive,
  File file,
  List<String> fields,
) async {
  final adapters = <String, int>{};
  if (!hive) return adapters;
  var idx = 0;
  if (await file.exists()) {
    final json = await file.readAsString();
    final map = jsonDecode(json) as Map<String, dynamic>;
    for (final entry in map.entries) {
      adapters[entry.key] = entry.value;
    }
    // Get highest index
    idx = adapters.values.reduce(max) + 1;
  }
  for (final entry in fields) {
    final name = entry;
    if (adapters[name] != null) {
      continue;
    }
    adapters[name] = idx;
    idx++;
  }
  await file.writeAsString(jsonEncode(adapters));
  return adapters;
}
