import 'dart:io';

import 'package:pocketbase/pocketbase.dart';
import 'package:recase/recase.dart';

class PocketBaseGenerator {
  PocketBaseGenerator(
    this.url, {
    this.lang = "en-US",
    this.output = 'lib/generated',
    required this.login,
    bool generateHive = true,
    bool generateDrift = false,
  }) : _hive = generateHive;

  final String url;
  final String lang;
  final String output;
  final bool _hive;

  final Future<AdminAuth> Function(PocketBase client) login;

  late final Directory outputDir = Directory(output);
  late final Directory collectionsDir =
      Directory('${outputDir.path}/collections');
  late final PocketBase client = PocketBase(url, lang: lang);

  String _getDartType(SchemaField field) {
    String type = 'dynamic';
    switch (field.type) {
      case 'text':
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
      case 'file':
      default:
        print('Unknown type: ${field.type} for ${field.name}');
    }
    if (!field.required) {
      // Make optional for null safety
      type = '$type?';
    }
    return type;
  }

  Future<void> _createCollection(CollectionModel collection, int index) async {
    print('Generating ${collection.name}...');
    final file = File('${collectionsDir.path}/${collection.name}.dart');
    await file.create(recursive: true);
    final sb = StringBuffer();

    // Generate JSON and Hive
    final dartClassName = collection.name.pascalCase;
    final schema = collection.schema
      ..insert(0,
          SchemaField(name: 'id', type: 'text', required: true, unique: true))
      ..add(SchemaField(name: 'created', type: 'date', required: true))
      ..add(SchemaField(name: 'updated', type: 'date', required: true));
    // Generate Class
    sb.writeln('import \'package:json_annotation/json_annotation.dart\';');
    if (_hive) {
      sb.writeln('import \'package:hive/hive.dart\';');
    }
    sb.writeln();
    sb.writeln('import \'base.dart\';');
    sb.writeln();
    sb.writeln('part \'${collection.name}.g.dart\';');
    sb.writeln();
    if (_hive) {
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
    var idx = 0;
    for (final field in schema) {
      if (_hive) {
        sb.writeln('  @HiveField($idx)');
      }
      sb.writeln('  @JsonKey(name: \'${field.name}\')');
      if (['id', 'created', 'updated'].contains(field.name)) {
        sb.writeln('  @override');
      }
      sb.writeln('  final ${_getDartType(field)} ${field.name.camelCase};');
      sb.writeln();
      idx++;
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

    // Write file
    await file.writeAsString(sb.toString());
  }

  Future<void> _createCollectionIndex(List<CollectionModel> collections) async {
    final file = File('${collectionsDir.path}/index.dart');
    final sb = StringBuffer();
    for (final collection in collections) {
      sb.writeln('export \'${collection.name}.dart\';');
    }
    await file.create(recursive: true);
    await file.writeAsString(sb.toString());
  }

  Future<void> _createClient(List<CollectionModel> collections) async {
    final file = File('${outputDir.path}/client.dart');
    final sb = StringBuffer();
    sb.writeln('import \'package:pocketbase/pocketbase.dart\';');
    sb.writeln();
    sb.writeln('import \'collections/index.dart\' as col;');
    sb.writeln();
    sb.writeln('extension RecordModelUtils on RecordModel {');
    for (final collection in collections) {
      final dartClassName = collection.name.pascalCase;
      sb.writeln(
          '  col.$dartClassName get as$dartClassName => col.$dartClassName.fromJson(toJson());');
    }
    sb.writeln('}');

    sb.writeln();
    await file.create(recursive: true);
    file.writeAsString(sb.toString());
  }

  Future<void> generate() async {
    await login(client);
    outputDir.check();
    final collections = await client.collections.getFullList();
    collectionsDir.check();
    await _createBase();
    final futures = <Future>[];
    var idx = 0;
    for (final collection in collections) {
      futures.add(_createCollection(collection, idx));
      idx++;
    }
    await Future.wait(futures);
    await _createCollectionIndex(collections);
    await _createClient(collections);
  }
}

extension on Directory {
  void check() {
    if (!existsSync()) {
      createSync(recursive: true);
    }
  }
}
