import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'BibleParser.dart';
import 'DialogAction.dart';
import 'config.dart';

class BibleSearchDelegate extends SearchDelegate<List> {

  final _bible;
  final _interfaceDialog;
  String abbreviations;

  var _verseNoFont, _verseFont, _verseFontHebrew, _verseFontGreek;
  var hebrewBibles, greekBibles;
  List _data = [];

  BibleSearchDelegate(BuildContext context, this._bible, this._interfaceDialog, Config config, this._data) {
    _verseNoFont = config.verseTextStyle["verseNoFont"];
    _verseFont = config.verseTextStyle["verseFont"];
    _verseFontHebrew = config.verseTextStyle["verseFontHebrew"];
    _verseFontGreek = config.verseTextStyle["verseFontGreek"];

    this.abbreviations = config.abbreviations;
    this.hebrewBibles = config.hebrewBibles;
    this.greekBibles = config.greekBibles;
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
    var verseDirection = TextDirection.ltr;
    var verseFont = _verseFont;
    var verseNo;
    var verseContent;
    var verseData = _data[i];
    if ((hebrewBibles.contains(verseData[2])) && (verseData[0][0] < 40)) {
      verseFont = _verseFontHebrew;
      verseDirection = TextDirection.rtl;
    } else if (greekBibles.contains(verseData[2])) {
      verseFont = _verseFontGreek;
    }
    //verseNo = "[${verseData[0][2]}] ";
    //verseContent = verseData[1];

    return ListTile(
      title: Text(
        verseData[1],
        style: _verseNoFont,
      ),

      onTap: () {
        close(context, [_data, i]);
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
            title: Text(_interfaceDialog[this.abbreviations][0]),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.share); },
                child: Text(_interfaceDialog[this.abbreviations][1]),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.copy); },
                child: Text(_interfaceDialog[this.abbreviations][2]),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.addCopy); },
                child: Text(_interfaceDialog[this.abbreviations][3]),
              ),
            ],
          );
        }
    )) {
      case DialogAction.share:
        Share.share(verseData[1]);
        break;
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
