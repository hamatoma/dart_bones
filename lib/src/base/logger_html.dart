import 'dart:convert' as convert;

import 'memory_logger.dart';

class HtmlLogger extends MemoryLogger {
  HtmlLogger(String filename, [int logLevel = 1]) : super(logLevel);

  String asDiv() {
    var buffer = StringBuffer();
    if (messages.isNotEmpty) {
      buffer.write('<div class="logger">');
      messages.forEach((element) {
        buffer.write(convert.htmlEscape.convert(element));
        buffer.write('<br/>');
      });
      buffer.write('</div>');
    }
    if (errors.isNotEmpty) {
      buffer.write('<div class="error">');
      errors.forEach((element) {
        buffer.write('+++ ');
        buffer.write(convert.htmlEscape.convert(element));
        buffer.write('<br/>');
      });
      buffer.write('</div>');
    }
    return buffer.toString();
  }
}
