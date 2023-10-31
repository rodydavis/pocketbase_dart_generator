import 'package:mustache_template/mustache.dart';
import 'package:mustache_recase/mustache_recase.dart' as mustache_recase;

import '../models/file.dart';

class RenderFileTemplate {
  final String template;

  RenderFileTemplate(this.template);

  String execute($File value) {
    final target = Template(template);
    final variables = value.toJson();
    // print(JsonEncoder.withIndent(' ').convert(variables));
    variables.addAll(mustache_recase.cases);
    final output = target.renderString(variables);
    return output;
  }
}
