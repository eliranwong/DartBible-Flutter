import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'BibleParser.dart';
import 'DialogAction.dart';

class BibleSearchDelegate extends SearchDelegate<List> {

  final _bible;
  String abbreviations;
  Map interfaceDialog = {
    "ENG": ["Select an action:", "Copy", "Add to Copied Text"],
    "TC": ["功能選項：", "複製", "加到已被複製的內容後面"],
    "SC": ["功能选项：", "拷贝", "加到已被拷贝的内容后面"],
  };

  var _bibleFont;
  List<dynamic> _data = [];

  BibleSearchDelegate(BuildContext context, this._bible, double fontSize, abbreviations, [List startupData]) {
    this._bibleFont = TextStyle(fontSize: fontSize);
    this.abbreviations = abbreviations;
    if (startupData != null) {
      _data = startupData; // startup data to be displayed via suggestions
    }
  }

  List _fetch(query) {
    List<dynamic> fetchResults =[];
    var verseReferenceList = BibleParser(this.abbreviations).extractAllReferences(query);
    (verseReferenceList.isEmpty) ? fetchResults = _bible.search(query) : fetchResults = _bible.openMultipleVerses(verseReferenceList);
    return fetchResults;
  }
/*
  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme;
  }
*/
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) _data = _fetch(query);
    return _buildVerses(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildVerses(context);
  }

  Widget _buildVerses(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildVerseRow(i, context);
        });
  }

  Widget _buildVerseRow(int i, BuildContext context) {
    return ListTile(
      title: Text(
        _data[i][1],
        style: _bibleFont,
      ),

      onTap: () {
        close(context, _data[i]);
      },

      onLongPress: () {
        _longPressedVerse(context, _data[i]);
      },

    );
  }

  Future<void> _longPressedVerse(BuildContext context, List verseData) async {
    var copiedText = await Clipboard.getData('text/plain');
    switch (await showDialog<DialogAction>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(interfaceDialog[this.abbreviations][0]),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.copy); },
                child: Text(interfaceDialog[this.abbreviations][1]),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.addCopy); },
                child: Text(interfaceDialog[this.abbreviations][2]),
              ),
            ],
          );
        }
    )) {
      case DialogAction.copy:
        Clipboard.setData(ClipboardData(text: verseData[1]));
        break;
      case DialogAction.addCopy:
        var combinedText = copiedText.text;
        combinedText += "\n${verseData[1]}";
        Clipboard.setData(ClipboardData(text: combinedText));
        break;
      default:
    }
  }

}
