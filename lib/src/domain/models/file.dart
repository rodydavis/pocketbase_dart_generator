import 'class.dart';

class $File {
  final String filename;
  final List<$Class> classes;

  $File({
    required this.filename,
    required this.classes,
  });

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'classes': classes.map((e) => e.toJson()).toList(),
      'hasHive': classes.any((e) => e.hiveTypeAdapter != null),
    };
  }
}
