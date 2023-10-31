import 'package:recase/recase.dart';

class $Field {
  final String name;
  final String description;
  final bool isRequired;
  final bool isFinal;
  final String type;
  final List<String>? options;

  bool get isEnum => options != null && options!.isNotEmpty;

  $Field({
    required this.name,
    required this.description,
    required this.isRequired,
    required this.isFinal,
    required this.type,
    required this.options,
  });

  String get typeName {
    if (type == 'url') return 'Uri';
    if (type == 'select') return name.pascalCase;
    const stringTypes = ['text', 'file', 'relation', 'editor', 'email'];
    if (stringTypes.contains(type)) return 'String';
    if (type == 'bool') return 'bool';
    if (type == 'number') return 'num';
    if (type == 'date') return 'DateTime';
    return 'dynamic';
  }

  String get sql {
    const stringTypes = [
      'text',
      'file',
      'relation',
      'editor',
      'email',
      'url',
      'select',
      'date',
    ];
    if (stringTypes.contains(type)) return 'TEXT';
    if (type == 'bool') return 'INTEGER';
    if (type == 'number') return 'REAL';
    return '';
  }

  Map<String, dynamic> toJson(int? hiveType) {
    return {
      'name': name,
      if (hiveType != null) 'hiveType': hiveType,
      'description': description,
      'required': isRequired,
      'final': isFinal,
      'enum': isEnum,
      'options': options,
      'defaultValue': null,
      'type': typeName,
      'sql': sql,
    };
  }
}
