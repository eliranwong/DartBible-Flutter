import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:unique_bible_app/Helpers.dart';
import 'package:unique_bible_app/BibleParser.dart';

// This wrapper deals with simple html elements only.
class HtmlWrapper {

  final double _fontSize;
  final String _abbreviations;
  BibleParser _parser;
  RegexHelper _regex;
  TextStyle _defaultStyle, _bcvStyle, _hStyle, _iStyle, _uStyle, _bStyle;

  HtmlWrapper(this._abbreviations, this._fontSize) {
    _parser = BibleParser(this._abbreviations);
    _regex = RegexHelper();
    _defaultStyle = TextStyle(fontSize: this._fontSize);
    _bcvStyle = TextStyle(fontSize: (this._fontSize - 2), color: Colors.indigo, decoration: TextDecoration.underline);
    _hStyle = TextStyle(fontSize: (this._fontSize + 4), fontWeight: FontWeight.bold);
    _iStyle = TextStyle(fontSize: this._fontSize, fontStyle: FontStyle.italic);
    _uStyle = TextStyle(fontSize: this._fontSize, decoration: TextDecoration.underline);
    _bStyle = TextStyle(fontSize: this._fontSize, fontWeight: FontWeight.bold);
  }

  convertHtmlText(String htmlText) {
    _regex.searchReplace = [
      ['\n|<p>', ''],
      [r'<h([0-9]*?)>(.*?)</h\1>', r'％＄\2％</p>'],
      ['<br>|<br/>|<br />', '\n'],
      ['</p>', '\n\n'],
      ['<i>(.*?)</i>', r'％｛\1％'],
      ['<b>(.*?)</b>', r'％＊\1％'],
      ['<u>(.*?)</u>', r'％｝\1％'],
      [r'<ref onclick="bcv\(([0-9,]+?)\)">.*?</ref>', r'％＠\1％'],
    ];
    return _regex.doSearchReplace(htmlText);
  }

  Widget buildRichText(BuildContext context, String plainText) {

    List<TextSpan> textSpans = [];
    List<String> textList = plainText.split("％");
    for (var text in textList) {
      if (text.startsWith("＠")) {
        List<dynamic> bcvList = text.substring(1).split(",");
        bcvList = bcvList.map((i) => int.parse(i)).toList();
        String bcvReference = _parser.bcvToVerseReference(bcvList);
        textSpans.add(TextSpan(text: bcvReference, style: _bcvStyle, recognizer: TapGestureRecognizer()..onTap = () => popUpVerse(context, bcvList)));
      } else if (text.startsWith("＄")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _hStyle));
      } else if (text.startsWith("｛")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _iStyle));
      } else if (text.startsWith("＊")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _bStyle));
      } else if (text.startsWith("｝")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _uStyle));
      } else {
        textSpans.add(TextSpan(text: text, style: _defaultStyle));
      }
    }
    return RichText(
      text: TextSpan(
        //style: DefaultTextStyle.of(context).style,
        children: textSpans,
      ),
    );
  }

  Future popUpVerse(BuildContext context, List bcvList) async {
    var text = bcvList.join(",");
    final selected = await showModalBottomSheet(context: context, builder: (BuildContext context) {
      return Container(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListTile(
            title: Text(text),
            subtitle: Text("Subtitle"),
            onTap: () {
              print("tile tapped");
              Navigator.pop(context, bcvList);
            },
          ),
        ),
      );
    });
    if (selected != null) Navigator.pop(context, selected);
  }

}