import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:unique_bible_app/config.dart';

class FileIOHelper {

  String getDataPath(String dataType, [String module]) {
    var config = Config();
    return "${config.assets}/$dataType/$module.json";
  }

}

class JsonHelper {

  Future getJsonObject(filePath) async {
    var jsonString = await rootBundle.loadString(filePath);
    var jsonObject = jsonDecode(jsonString);
    return jsonObject;
  }

}

class RegexHelper {

  var searchReplace;

  var searchPattern;

  var patternString;

  String Function(Match) replacement(String pattern) => (Match match) => pattern.replaceAllMapped(new RegExp(r'\\(\d+)'), (m) => match[int.parse(m[1])]);

  String replaceAllSmart(String source, Pattern pattern, String replacementPattern) => source.replaceAllMapped(pattern, replacement(replacementPattern));

  String doSearchReplace(String text, {bool multiLine = false, bool caseSensitive = true, bool unicode = false, bool dotAll = false}) {
    var replacedText = text;
    for (var i in this.searchReplace) {
      var search = i[0];
      var replace = i[1];
      replacedText = this.replaceAllSmart(replacedText, RegExp(search, multiLine: multiLine, caseSensitive: caseSensitive, unicode: unicode, dotAll: dotAll), replace);
    }
    return replacedText;
  }

}
