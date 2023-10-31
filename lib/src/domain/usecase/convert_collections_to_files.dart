import 'dart:convert';

import 'package:pocketbase/pocketbase.dart';
import 'package:recase/recase.dart';

import '../models/class.dart';
import '../models/field.dart';
import '../models/file.dart';

class ConvertCollectionsToFiles {
  List<$File> execute(
    List<CollectionModel> collections,
    StorageType storage,
    bool hive,
  ) {
    final files = <$File>[];
    for (var i = 0; i < collections.length; i++) {
      final collection = collections[i];
      print(JsonEncoder.withIndent(' ').convert(collection));
      final file = $File(
        filename: collection.name.snakeCase,
        classes: [
          $Class(
            query: collection.options['query'] as String?,
            type: collection.type,
            description: collection.name,
            hiveTypeAdapter: hive ? i : null,
            name: collection.name.pascalCase,
            collectionId: collection.id,
            collectionName: collection.name,
            indexes: collection.indexes,
            fields: [
              for (final field in collection.schema)
                $Field(
                  name: field.type == 'select'
                      ? field.name.camelCase
                      : '\$${field.name.camelCase}',
                  description: field.name,
                  isRequired: field.required,
                  isFinal: true,
                  type: field.type,
                  options: field.type == 'select'
                      ? (field.options['values'] as List).cast<String>()
                      : [],
                ),
            ],
          ),
        ],
      );
      files.add(file);
    }
    return files;
  }
}

enum StorageType {
  sqlite,
  sqflite,
}
