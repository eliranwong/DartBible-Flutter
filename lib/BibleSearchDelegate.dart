import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'BibleParser.dart';
import 'Bibles.dart';
import 'config.dart';
import 'Helpers.dart';

class BibleSearchDelegate extends SearchDelegate<List> {
  final _bible;
  final _interfaceDialog;
  final _pageSize = 20;
  List _bcvList;
  String abbreviations;
  Map interfaceBibleSearch = {
    "ENG": [
      "is not properly formatted for search. Please correct and try again.",
      "Clear",
      "More ...",
      "Search",
      "Open '",
      "' Here",
    ],
    "TC": [
      "組成的格式不正確，請更正然後再嘗試",
      "清空",
      "更多 …",
      "搜索",
      "在這裡打開【",
      "】",
    ],
    "SC": [
      "组成的格式不正确，请更正然后再尝试",
      "清空",
      "更多 …",
      "搜索",
      "在这里打开【",
      "】",
    ],
  };

  var _verseNoFont, _verseFont, _verseFontHebrew, _verseFontGreek;
  var _activeVerseFont, _activeVerseFontHebrew, _activeVerseFontGreek;
  var hebrewBibles, greekBibles, interlinearBibles;
  var verseTextStyle;
  List _data = [];
  List _rawData;
  int _backgroundColor;
  Map<String, String> _bookCollection;

  @override
  String get searchFieldLabel => interfaceBibleSearch[this.abbreviations][3];

  BibleSearchDelegate(BuildContext context, this._bible, this._interfaceDialog,
      Config config, this._data, [this._rawData]) {
    _verseNoFont = config.verseTextStyle["verseNoFont"];
    _verseFont = config.verseTextStyle["verseFont"];
    _verseFontHebrew = config.verseTextStyle["verseFontHebrew"];
    _verseFontGreek = config.verseTextStyle["verseFontGreek"];
    _activeVerseFont = config.verseTextStyle["activeVerseFont"];
    _activeVerseFontHebrew = config.verseTextStyle["activeVerseFontHebrew"];
    _activeVerseFontGreek = config.verseTextStyle["activeVerseFontGreek"];

    this._bcvList = config.historyActiveVerse.first;
    this.abbreviations = config.abbreviations;
    this.hebrewBibles = config.hebrewBibles;
    this.greekBibles = config.greekBibles;
    this.interlinearBibles = config.interlinearBibles;
    this.verseTextStyle = config.verseTextStyle;

    this._backgroundColor = config.backgroundColor;

    this._bookCollection = config.bookCollection;
    (_rawData == null) ? _rawData = [] : _loadData();
  }

  Future _openHere(List bcvList, String module) async {
    if (module == _bible.module) {
      _data = _bible.openSingleChapter(bcvList, true);
    } else {
      Bible bible = Bible(module, this.abbreviations);
      await bible.loadData();
      _data = bible.openSingleChapter(bcvList, true);
    }
    _rawData = [];
    // workaround for visual update:
    String tempString = query;
    query = "...";
    query = tempString;
  }

  // The option of lazy loading is achieved with "_loadData" & "_loadMoreData"
  Future _loadData() async {
    _data = (_rawData.length <= _pageSize)
        ? _bible.openMultipleVerses(_rawData)
        : _bible.openMultipleVerses(_rawData.sublist(0, _pageSize));
  }

  Future _loadMoreData(BuildContext context, int i) async {
    int start = i;
    int end = i + _pageSize;
    List newBcvList = (end > _rawData.length)
        ? _rawData.sublist(start)
        : _rawData.sublist(start, end);
    _data = [..._data, ..._bible.openMultipleVerses(newBcvList)];
    // visual update; SearchDelegate doesn't have method setState; the following 3 lines is a workaround for visual update.
    String tempString = query;
    query = "...";
    query = tempString;
  }

  // This is the function which does the search.
  List _fetch(BuildContext context, String query) {
    List<dynamic> fetchResults = [];

    if (query.contains("：：：")) query = query.replaceAll("：：：", ":::");
    try {
      // search the whole bible, e.g. God.*?love
      // search in a book, e.g. John:::Jesus Christ
      // search in multiple books, e.g. Matthew, John:::Jesus Christ
      // search in a book collection, e.g. Torah:::God.*?love
      // search in multiple book collections, e.g. Moses, Gospels:::God.*?love
      // search with combination of book collections and individual books, e.g. Torah, Major Prophets, Gospels, Hebrews:::God.*?love
      if (query.contains(":::")) {
        List queryList = query.split(":::");
        if (queryList.length >= 2) {
          List bookReferenceList;
          if (queryList[0].isNotEmpty) {
            String bookString = "";
            var bookList = queryList[0].split(",");
            for (var book in bookList) {
              String bookTrim = book.trim();
              bookString += this._bookCollection[bookTrim] ?? "$bookTrim 0; ";
            }
            bookReferenceList = BibleParser(this.abbreviations)
                .extractAllReferences(bookString);
          } else {
            bookReferenceList = [_bcvList];
          }
          if (bookReferenceList.isNotEmpty) {
            String queryText = queryList.sublist(1).join(":::");
            if (queryText.isNotEmpty) {
              return _bible.searchBooks(queryText, bookReferenceList);
            }
          }
        }
      }

      // check if the query contains verse references or not.
      String possibleReference = (query.contains("：")) ? query.replaceAll("：", ":") : query;
      RegExp irregularHyphen = new RegExp(r"[－─]");
      if (irregularHyphen.hasMatch(possibleReference)) possibleReference = possibleReference.replaceAll(irregularHyphen, "-");
      var verseReferenceList =
          BibleParser(this.abbreviations).extractAllReferences(possibleReference);
      (verseReferenceList.isEmpty)
          ? fetchResults = _bible.search(query)
          : fetchResults = _bible.openMultipleVerses(verseReferenceList);
    } catch (e) {
      fetchResults = [
        [[], "['$query' ${interfaceBibleSearch[this.abbreviations][0]}", ""]
      ];
    }

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
        tooltip: this.interfaceBibleSearch[this.abbreviations][1],
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

  // Function triggered when "ENTER" is pressed.
  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) _data = _fetch(context, query);
    return _buildVerses(context);
  }

  // Results are displayed if _data is not empty.
  // Display of results changes as users type something in the search field.
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildVerses(context);
  }

  Widget _buildVerses(BuildContext context) {
    int count = ((_rawData.isNotEmpty) && (_rawData.length > _data.length))
        ? (_data.length + 1)
        : _data.length;
    return Container(
      color: Colors.blueGrey[_backgroundColor],
      child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: count,
          itemBuilder: (context, i) {
            return (i == _data.length)
                ? _buildMoreRow(context, i)
                : _buildVerseRow(context, i);
          }),
    );
  }

  Widget _buildMoreRow(BuildContext context, int i) {
    return ListTile(
      title: Text(
        "[${interfaceBibleSearch[this.abbreviations][2]}]",
        style: _activeVerseFont,
      ),
      onTap: () {
        _loadMoreData(context, i);
      },
    );
  }

  Widget _buildVerseRow(BuildContext context, int i) {
    var verseData = _data[i];

    return ListTile(
      title: _buildVerseText(context, verseData),
      onTap: () {
        close(context, [_data, i]);
      },
      onLongPress: () {
        _longPressedVerse(context, _data[i]);
      },
    );
  }

  // This function gives RichText widget with search items highlighted.
  Widget _buildVerseText(BuildContext context, List verseData) {
    var verseDirection = TextDirection.ltr;
    var verseFont = _verseFont;
    var activeVerseFont = _activeVerseFont;
    var versePrefix = "";
    var verseContent = "";
    var verseModule = verseData[2];

    if ((hebrewBibles.contains(verseModule)) && (verseData[0][0] < 40)) {
      verseFont = _verseFontHebrew;
      activeVerseFont = _activeVerseFontHebrew;
      verseDirection = TextDirection.rtl;
    } else if (greekBibles.contains(verseModule)) {
      verseFont = _verseFontGreek;
      activeVerseFont = _activeVerseFontGreek;
    }
    var verseText = verseData[1];
    var tempList = verseText.split("]");

    if (tempList.isNotEmpty) versePrefix = "${tempList[0]}]";
    if (tempList.length > 1) verseContent = tempList.sublist(1).join("]");

    List<TextSpan> textContent = [
      TextSpan(text: versePrefix, style: _verseNoFont)
    ];
    try {
      String searchEntry = query;
      if (query.contains(":::")) {
        searchEntry = query.split(":::").sublist(1).join(":::");
      } else if (query.contains("：：：")) {
        searchEntry = query.split("：：：").sublist(1).join("：：：");
      }
      if (this.interlinearBibles.contains(verseModule)) {
        List<TextSpan> interlinearSpan = InterlinearHelper(this.verseTextStyle)
            .getInterlinearSpan(verseModule, verseContent, verseData[0][0]);
        textContent = interlinearSpan
          ..insert(0, TextSpan(text: versePrefix, style: _verseNoFont));
      } else if (searchEntry.isEmpty) {
        textContent.add(TextSpan(text: verseContent, style: verseFont));
      } else {
        var regex = RegexHelper();
        regex.searchReplace = [
          ["($searchEntry)", r'％\1％'],
        ];
        verseContent = regex.doSearchReplace(verseContent);
        List<String> textList = verseContent.split("％");
        for (var text in textList) {
          if (RegExp(searchEntry).hasMatch(text)) {
            textContent.add(TextSpan(text: text, style: activeVerseFont));
          } else {
            textContent.add(TextSpan(text: text, style: verseFont));
          }
        }
      }
    } catch (e) {
      textContent.add(TextSpan(text: verseContent, style: verseFont));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: textContent,
      ),
      textDirection: verseDirection,
    );
  }

  Future<void> _longPressedVerse(BuildContext context, List verseData) async {
    if (verseData.first.isNotEmpty) {
      List bcvList = verseData.first;
      String ref = BibleParser(this.abbreviations).bcvToVerseReference(bcvList);
      String refCh = BibleParser(this.abbreviations).bcvToChapterReference(bcvList);
      var copiedText = await Clipboard.getData('text/plain');
      switch (await showDialog<DialogAction>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text(ref),
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.open_in_browser),
                  title:
                  Text("${interfaceBibleSearch[this.abbreviations][4]}$refCh${interfaceBibleSearch[this.abbreviations][5]}"),
                  onTap: () =>
                      Navigator.pop(context, DialogAction.openHere),
                ),
                ListTile(
                  leading: Icon(Icons.share),
                  title: Text(_interfaceDialog[this.abbreviations][1]),
                  onTap: () => Navigator.pop(context, DialogAction.share),
                ),
                ListTile(
                  leading: Icon(Icons.content_copy),
                  title: Text(_interfaceDialog[this.abbreviations][2]),
                  onTap: () => Navigator.pop(context, DialogAction.copy),
                ),
                ListTile(
                  leading: Icon(Icons.playlist_add),
                  title: Text(_interfaceDialog[this.abbreviations][3]),
                  onTap: () => Navigator.pop(context, DialogAction.addCopy),
                ),
                /*SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, DialogAction.share);
                },
                child: Text(_interfaceDialog[this.abbreviations][1]),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, DialogAction.copy);
                },
                child: Text(_interfaceDialog[this.abbreviations][2]),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, DialogAction.addCopy);
                },
                child: Text(_interfaceDialog[this.abbreviations][3]),
              ),*/
              ],
            );
          })) {
        case DialogAction.share:
          Share.share("${verseData[1]} ($ref, ${verseData.last})");
          break;
        case DialogAction.copy:
          Clipboard.setData(ClipboardData(text: "${verseData[1]} ($ref, ${verseData.last})"));
          break;
        case DialogAction.addCopy:
          var combinedText = copiedText.text;
          combinedText += "\n${verseData[1]} ($ref, ${verseData.last})";
          Clipboard.setData(ClipboardData(text: combinedText));
          break;
        case DialogAction.openHere:
          _openHere(bcvList, verseData.last);
          break;
        default:
      }
    }
  }
}
