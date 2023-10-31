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
    required this.authenticate,
    this.verbose = false,
  });

  late final PocketBase client = PocketBase(url, lang: lang);
  late final Directory collectionsDir =
      Directory('${outputDir.path}/collections');

  final String lang;
  final Future<AdminAuth> Function(PocketBase client) authenticate;
  final String output;
  late final Directory outputDir = Directory(output);
  final String url;
  final bool verbose;

  /// Generates PocketBase Dart SDK files.
  Future<void> generate(StorageType storage) async {
    await authenticate(client);
    outputDir.check();
    final collections = await client.collections.getFullList();
    collectionsDir.check();
    await _createBase();
    final hive = storage == StorageType.hive;
    final adapters = await _getHiveInfo(
      hive,
      File('${outputDir.path}/adapters.json'),
      collections.map((e) => e.name.pascalCase).toList(),
    );
    final futures = <Future>[];
    for (final collection in collections) {
      final idx = adapters[collection.name.pascalCase] ?? -1;
      futures.add(_createCollection(hive, collection, idx));
    }
    await Future.wait(futures);
    await _createCollectionIndex(hive, collections);
    await _createClient(hive, collections);
  }

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
        if (verbose) print('Unknown type: ${field.type} for ${field.name}');
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
    if (verbose) print('Generating ${collection.name}...');
    final file = File('${collectionsDir.path}/${collection.name}.dart');
    await file.create(recursive: true);
    final sb = StringBuffer();
    void $([String val = '']) => sb.writeln(val);

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
    $('import \'package:json_annotation/json_annotation.dart\';');
    if (hive) {
      $('import \'package:hive/hive.dart\';');
    }
    $();
    $('import \'base.dart\';');
    $();
    $('part \'${collection.name}.g.dart\';');
    $();
    if (hive) {
      $('@HiveType(typeId: $index)');
    }
    $('@JsonSerializable()');
    $('class $dartClassName extends CollectionBase {');

    // Generate constructor
    $('  const $dartClassName({');
    for (final field in schema) {
      $('    required this.${field.name.camelCase},');
    }
    $('  });');
    $();

    // Generate fields
    for (final field in schema) {
      if (hive) {
        final idx = adapters[field.name.camelCase];
        $('  @HiveField($idx)');
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
      $(')');
      if (['id', 'created', 'updated'].contains(field.name)) {
        $('  @override');
      }
      $('  final $dartType ${field.name.camelCase};');
      $();
    }

    // Generate toJson
    $('  Map<String, dynamic> toJson() => _\$${dartClassName}ToJson(this);');
    $();

    // Generate fromJson
    $('  factory $dartClassName.fromJson(Map<String, dynamic> json) => _\$${dartClassName}FromJson(json);');

    // Close class
    $('}');
    $();

    // Write file
    await file.writeAsString(sb.toString());
  }

  Future<void> _createBase() async {
    if (verbose) print('Generating base...');
    final file = File('${collectionsDir.path}/base.dart');
    await file.create(recursive: true);
    final sb = StringBuffer();
    void $([String val = '']) => sb.writeln(val);

    // Generate Base class
    $('abstract class CollectionBase {');
    $('  const CollectionBase();');
    $('  String get id;');
    $('  DateTime get created;');
    $('  DateTime get updated;');

    // Close class
    $('}');
    $();
    $(converters);
    $();

    // Write file
    await file.writeAsString(sb.toString());
  }

  Future<void> _createCollectionIndex(
    bool hive,
    List<CollectionModel> collections,
  ) async {
    final file = File('${collectionsDir.path}/index.dart');
    final sb = StringBuffer();
    void $([String val = '']) => sb.writeln(val);
    for (final collection in collections) {
      $('export \'${collection.name}.dart\';');
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
    void $([String val = '']) => sb.writeln(val);
    $('import \'package:pocketbase/pocketbase.dart\';');
    if (hive) {
      $('import \'package:hive/hive.dart\';');
    }
    $();
    $('import \'collections/index.dart\' as col;');
    $('import \'collections/base.dart\';');
    $();
    if (hive) {
      $('class DbClient {');
      $('  DbClient(this.client);');
      $('  final PocketBase client;');
      $();
      for (final collection in collections) {
        final dartClassName = collection.name.pascalCase;
        $('  late final Box<col.$dartClassName> ${collection.name.camelCase}Box;');
      }
      $();
      $('  Future<void> init() async {');
      $('    registerAdapters();');
      $('    await openBoxes();');
      $('  }');
      $();

      // Open boxes
      $('  Future<void> openBoxes() async {');
      for (final collection in collections) {
        final dartClassName = collection.name.pascalCase;
        $('    ${collection.name.camelCase}Box = await Hive.openBox<col.$dartClassName>(\'${collection.name}\');');
      }
      $('  }');
      $();

      // // Register Hive adapters
      $('  void registerAdapters() {');
      for (final collection in collections) {
        final dartClassName = collection.name.pascalCase;
        $('    Hive.registerAdapter(col.${dartClassName}Adapter());');
      }
      $('  }');
      $();

      // Get collections
      for (final collection in collections) {
        final dartClassName = collection.name.pascalCase;
        $("  Future<List<col.$dartClassName>> get$dartClassName() =>");
        $("     getItems<col.$dartClassName>('${collection.name}', ${collection.name.camelCase}Box, col.$dartClassName.fromJson,);");
        $();
      }

      // Write helper
      $([
        '  Future<List<T>> getItems<T extends CollectionBase>(',
        '    String name,',
        '    Box<T> box,',
        '    T Function(Map<String, dynamic>) fromJson,',
        '  ) async {',
        '    String? filter;',
        if (hive) ...[
          '    final latest = box.isEmpty',
          '        ? null',
          '        : box.values.reduce((a, b) => a.updated.isAfter(b.updated) ? a : b);',
          '    if (latest != null) {',
          '      final d = latest.updated;',
          "      filter = \"updated > '\${d.year}-\${d.month.toString().padLeft(2, '0')}-\${d.day.toString().padLeft(2, '0')} \${d.hour.toString().padLeft(2, '0')}:\${d.minute.toString().padLeft(2, '0')}:\${d.second.toString().padLeft(2, '0')} UTC'\";",
          '    }',
          '    final records = await client.records.getFullList(',
          '      name,',
          '      filter: filter,',
          '    );',
        ] else ...[
          '    final records = await client.records.getFullList(',
          '      name,',
          '    );',
        ],
        '    for (final record in records) {',
        '      final item = fromJson(record.toJson());',
        '      await box.put(item.id, item);',
        '    }',
        '    return box.values.toList();',
        '  }',
      ].join('\n'));

      $('}');
    }
    $();
    // $('extension RecordModelUtils on RecordModel {');
    // for (final collection in collections) {
    //   final dartClassName = collection.name.pascalCase;
    //   sb.write('  col.$dartClassName as$dartClassName() => ');
    //   $(' col.$dartClassName.fromJson(toJson());');
    // }
    // $('}');

    $();
    await file.create(recursive: true);
    file.writeAsString(sb.toString());
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

enum StorageType {
  memory,
  sqlite,
  sqflite,
  hive,
}
