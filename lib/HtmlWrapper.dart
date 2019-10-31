import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'Helpers.dart';
import 'BibleParser.dart';
import 'config.dart';
import 'Bibles.dart';

// This wrapper deals with simple html elements only.
class HtmlWrapper {
  final Bibles _bibles;
  final Config _config;
  int currentBible = 1;
  String _abbreviations;
  BibleParser _parser;
  RegexHelper _regex;
  TextStyle _defaultStyle,
      _bcvStyle,
      _hStyle,
      _iStyle,
      _uStyle,
      _bStyle,
      _hebStyle,
      _grkStyle;

  HtmlWrapper(this._bibles, this._config) {
    this._abbreviations = _config.abbreviations;
    _parser = BibleParser(this._abbreviations);
    _regex = RegexHelper();
    setHtmlTextStyle();
  }

  setHtmlTextStyle() {
    _defaultStyle = _config.verseTextStyle["verseFont"];
    _bcvStyle = TextStyle(
        fontSize: (_config.fontSize - 2),
        color: _config.myColors["blue"],
        decoration: TextDecoration.underline);
    _hStyle = TextStyle(
        fontSize: (_config.fontSize + 4),
        color: _config.myColors["black"],
        fontWeight: FontWeight.bold);
    _iStyle = TextStyle(
        fontSize: _config.fontSize,
        color: _config.myColors["black"],
        fontStyle: FontStyle.italic);
    _uStyle = TextStyle(
        fontSize: _config.fontSize,
        color: _config.myColors["black"],
        decoration: TextDecoration.underline);
    _bStyle = TextStyle(
        fontSize: _config.fontSize,
        color: _config.myColors["black"],
        fontWeight: FontWeight.bold);
    _hebStyle = _config.verseTextStyle["verseFontHebrew"];
    _grkStyle = _config.verseTextStyle["verseFontGreek"];
  }

  convertHtmlText(String htmlText, [bool tagBcv = true]) {
    String text = (tagBcv) ? _parser.parseText(htmlText) : htmlText;

    _regex.searchReplace = [
      //['\n|<p>|<author>|</author>|<date>|</date>|<re>|</re>|<note>|</note>|<Lat>|</Lat>|<foreign.*?>|</foreign>|<corr>|</corr>', ''],
      ['\n|<ind>|</ind>|<font.*?>|</font>|<div.*?>', ''],
      [r'<h([0-9]*?)>(.*?)</h\1>', r'％＄\2％</p>'],
      ['<br>|<br/>|<br />|</ul>|</li>', '\n'],
      ['<p>|</p>|</div>|<ul>', '\n\n'],
      ['<li>', '* '],
      ['<i>(.*?)</i>', r'％｛\1％'],
      ['<b>(.*?)</b>', r'％＊\1％'],
      ['<u>(.*?)</u>', r'％｝\1％'],
      ['<heb>(.*?)</heb>', r'％＆\1％'],
      ['<grk>(.*?)</grk>', r'％＃\1％'],
      [r'<ref onclick="bcv\(([0-9,]+?)\)">.*?</ref>', r'％＠\1％'],
      ['&gt;', '>'],
      ['&lt;', '<'],
      [' [ ]+?([^ ])', ' \\1'],
      ['\n\n[\n]+?([^\n])', '\n\n\\1'],
    ];
    return _regex.doSearchReplace(text);
  }

  Widget buildRichText(BuildContext context, String htmlText) {
    String plainText = this.convertHtmlText(htmlText);

    List<TextSpan> textSpans = [];
    List<String> textList = plainText.split("％");
    for (var text in textList) {
      if (text.startsWith("＠")) {
        List<dynamic> bcvList = text.substring(1).split(",");
        bcvList = bcvList.map((i) => int.parse(i)).toList();
        String bcvReference = _parser.bcvToVerseReference(bcvList);
        textSpans.add(
            TextSpan(
                text: bcvReference,
                style: _bcvStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => popUpVerse(context, bcvList)
            )
        );
      } else if (text.startsWith("＄")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _hStyle));
      } else if (text.startsWith("｛")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _iStyle));
      } else if (text.startsWith("＊")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _bStyle));
      } else if (text.startsWith("｝")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _uStyle));
      } else if (text.startsWith("＆")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _hebStyle));
      } else if (text.startsWith("＃")) {
        textSpans.add(TextSpan(text: text.substring(1), style: _grkStyle));
      } else {
        textSpans.add(TextSpan(text: text, style: _defaultStyle));
      }
    }
    return RichText(
      text: TextSpan(
        children: textSpans,
      ),
    );
  }

  Future popUpVerse(BuildContext context, List bcvList) async {
    String reference = _parser.bcvToVerseReference(bcvList);
    Widget verseText;
    String module;
    switch (currentBible) {
      case 1:
        verseText = buildVerseRichText(_bibles.bible1, bcvList);
        module = _bibles.bible1.module;
        break;
      case 2:
        verseText = buildVerseRichText(_bibles.bible2, bcvList);
        module = _bibles.bible2.module;
        break;
      case 3:
        verseText = buildVerseRichText(_bibles.iBible, bcvList);
        module = _bibles.iBible.module;
        break;
      default:
    }
    final selected = await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            color: _config.myColors["background"],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: ListTile(
                title: verseText,
                subtitle: Text(
                  "[$reference, $module]",
                  style: TextStyle(color: _config.myColors["blue"]),
                ),
                onTap: () {
                  Navigator.pop(context, [bcvList, "", module]);
                },
                trailing: IconButton(
                  //tooltip: "",
                  icon: Icon(
                    Icons.swap_vert,
                    color: _config.myColors["black"],
                  ),
                  onPressed: () {
                    Navigator.pop(context, [bcvList, "", currentBible]);
                  },
                ),
              ),
            ),
          );
        });
    if (selected != null) {
      if (selected[2] is int) {
        currentBible = (currentBible < 3) ? currentBible + 1 : 1;
        popUpVerse(context, bcvList);
      } else {
        Navigator.pop(context, selected);
      }
    }
  }

  // This function gives RichText widget of a verse.
  Widget buildVerseRichText(Bible bible, List bcvList) {
    String module = bible.module;
    int book = bcvList[0];
    String text = (bcvList.length > 3)
        ? bible.openSingleVerseRange(bcvList)
        : bible.openSingleVerse(bcvList);

    bool isHebrewBible =
        ((_config.hebrewBibles.contains(module)) && (book < 40));
    TextDirection verseDirection =
        (isHebrewBible) ? TextDirection.rtl : TextDirection.ltr;
    TextStyle verseFont;
    if (isHebrewBible) {
      verseFont = _config.verseTextStyle["verseFontHebrew"];
    } else if (_config.greekBibles.contains(module)) {
      verseFont = _config.verseTextStyle["verseFontGreek"];
    } else {
      verseFont = _config.verseTextStyle["verseFont"];
    }

    List<TextSpan> wordSpans = (_config.interlinearBibles.contains(module))
        ? InterlinearHelper(_config.verseTextStyle)
            .getInterlinearSpan(module, text, book)
        : <TextSpan>[TextSpan(text: text, style: verseFont)];
    return RichText(
      text: TextSpan(
        //style: DefaultTextStyle.of(context).style,
        children: wordSpans,
      ),
      textDirection: verseDirection,
    );
  }
}
