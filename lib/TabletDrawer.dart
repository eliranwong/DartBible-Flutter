import 'package:flutter/material.dart';
import 'config.dart';
import 'Bibles.dart';
import 'BibleParser.dart';
import 'Helpers.dart';
import 'Tools.dart';

class TabletDrawer extends StatefulWidget {
  final Config config;
  final Bible bible, headings;
  final Function onTap;

  TabletDrawer(this.config, this.bible, this.headings, this.onTap);

  @override
  TabletDrawerState createState() => TabletDrawerState(this.config, this.bible,
      this.headings, this.onTap);
}

class TabletDrawerState extends State<TabletDrawer> {
  final Config config;
  final Bible bible, headings;

  Function onTap;

  String abbreviations;
  List _currentActiveVerse;
  int _selectedBook, headingBook, _selectedChapter;
  bool _displayAllBooks = false;
  bool _updateCurrentActiveVerse = true;
  TextStyle _generalTextStyle, _entryTextStyle;

  Map interfaceApp = {
    "ENG": [
      "Unique Bible App",
      "Navigation menu",
      "Search",
      "Quick swap",
      "Settings",
      "Parallel mode",
      "Favourites",
      "History",
      "Books",
      "Chapters",
      "Timelines",
      "Headings"
    ],
    "TC": [
      "跨平台聖經工具",
      "菜單",
      "搜索",
      "快速轉換",
      "設定",
      "平衡模式",
      "收藏",
      "歷史",
      "書卷",
      "章",
      "時序圖",
      "標題"
    ],
    "SC": [
      "跨平台圣经工具",
      "菜单",
      "搜索",
      "快速转换",
      "设定",
      "平衡模式",
      "收藏",
      "历史",
      "书卷",
      "章",
      "时序图",
      "标题"
    ],
  };

  Map interfaceAlert = {
    "ENG": [
      "CANCEL",
      "ADD",
      "REMOVE",
      "Add to Favourites?",
      "Remove from Favourites?"
    ],
    "TC": ["取消", "收藏", "删除", "收藏？", "删除？"],
    "SC": ["取消", "收藏", "删除", "收藏？", "删除？"],
  };

  TabletDrawerState(this.config, this.bible, this.headings, this.onTap);

  void updateInterface() {
    this.abbreviations = this.config.abbreviations;
    if (_updateCurrentActiveVerse) {
      this._currentActiveVerse = this.config.historyActiveVerse.first;
      this._selectedBook = this._currentActiveVerse.first;
      this.headingBook = _selectedBook;
      this._selectedChapter = this._currentActiveVerse[1];
    } else {
      _updateCurrentActiveVerse = !_updateCurrentActiveVerse;
    }
    _generalTextStyle = TextStyle(color: config.myColors["black"]);
    _entryTextStyle = TextStyle(color: config.myColors["blueAccent"]);
  }

  @override
  Widget build(BuildContext context) {
    updateInterface();
    return ListView(
      // Important: Remove any padding from the ListView.
      padding: EdgeInsets.zero,
      children: <Widget>[
        _buildTimelineList(context),
        _buildFavouriteList(context),
        _buildHistoryList(context),
        _buildBookList(context),
        _buildChapterList(context),
        _buildHeadingList(context),
      ],
    );
  }

  Widget _buildTimelineList(BuildContext context) {
    List timelines = [
      ["0", "2210-2090 BCE"],
      ["1", "2090-1970 BCE"],
      ["2", "1970-1850 BCE"],
      ["3", "1850-1730 BCE"],
      ["4", "1750-1630 BCE"],
      ["5", "1630-1510 BCE"],
      ["6", "1510-1390 BCE"],
      ["7", "1410-1290 BCE"],
      ["8", "1290-1170 BCE"],
      ["9", "1170-1050 BCE"],
      ["10", "1050-930 BCE"],
      ["11", "930-810 BCE"],
      ["12", "810-690 BCE"],
      ["13", "690-570 BCE"],
      ["14", "570-450 BCE"],
      ["15", "470-350 BCE"],
      ["16", "350-230 BCE"],
      ["17", "240-120 BCE"],
      ["18", "120-1 BCE"],
      ["19", "10-110 CE"],
      ["20", "Matthew"],
      ["21", "Mark"],
      ["22", "Luke"],
      ["23", "John"],
      ["24", "4 Gospels"],
    ];
    List<Widget> timelineRowList = timelines
        .map((i) => _buildTimelineRow(context, i[0], i[1], timelines))
        .toList();
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][10],
          style: _generalTextStyle),
      //initiallyExpanded: true,
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: timelineRowList,
    );
  }

  Widget _buildTimelineRow(
      BuildContext context, String file, String title, List timelines) {
    return ListTile(
      leading: Icon(
        Icons.timeline,
        color: this.config.myColors["grey"],
      ),
      title: Text(
        title,
        style: _entryTextStyle,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Timeline(file, title, timelines, config)),
        );
      },
    );
  }

  Widget _buildHeadingList(BuildContext context) {
    List<Widget> headingRowList;
    if ((_currentActiveVerse.join(".") == "0.0.0") ||
        (headings?.data == null)) {
      headingRowList = [_emptyRow(context)];
    } else {
      List headingsList =
      headings.openSingleChapter([headingBook, _selectedChapter, 0]);
      headingRowList =
          headingsList.map((i) => _buildHeadingRow(context, i)).toList();
    }
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][11],
          style: _generalTextStyle),
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      initiallyExpanded: true,
      children: headingRowList,
    );
  }

  Widget _buildHeadingRow(BuildContext context, List verseItem) {
    return ListTile(
      leading: Icon(
        Icons.outlined_flag,
        color: this.config.myColors["grey"],
      ),
      title: Text(
        verseItem[1],
        style: _entryTextStyle,
      ),
      onTap: () {
        //Navigator.pop(context);
        onTap([
          "open",
          [verseItem.first, "", bible.module]
        ]);
      },
    );
  }

  Widget _buildFavouriteList(BuildContext context) {
    List<Widget> favouriteRowList;
    if ((_currentActiveVerse.join(".") == "0.0.0") || (bible?.data == null)) {
      favouriteRowList = [_emptyRow(context)];
    } else {
      List favouriteList = this.config.favouriteVerse;
      favouriteRowList =
          favouriteList.map((i) => _buildFavouriteRow(context, i)).toList();
    }
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][6],
          style: _generalTextStyle),
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: favouriteRowList,
    );
  }

  Widget _buildFavouriteRow(BuildContext context, List hxBcvList) {
    var parser = BibleParser(this.abbreviations);
    String hxReference = parser.bcvToVerseReference(hxBcvList);
    return ListTile(
      leading: Icon(
        Icons.favorite_border,
        color: this.config.myColors["grey"],
      ),
      title: Text(
        hxReference,
        style: _entryTextStyle,
      ),
      onTap: () {
        //Navigator.pop(context);
        onTap([
          "open",
          [hxBcvList, "", bible.module]
        ]);
      },
      onLongPress: () {
        _removeFromFavouriteDialog(context, hxBcvList);
      },
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    List<Widget> historyRowList;
    if ((_currentActiveVerse.join(".") == "0.0.0") || (bible?.data == null)) {
      historyRowList = [_emptyRow(context)];
    } else {
      List historyList = this.config.historyActiveVerse;
      historyRowList =
          historyList.map((i) => _buildHistoryRow(context, i)).toList();
    }
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][7],
          style: _generalTextStyle),
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: historyRowList,
    );
  }

  Widget _buildHistoryRow(BuildContext context, List hxBcvList) {
    var parser = BibleParser(this.abbreviations);
    String hxReference = parser.bcvToVerseReference(hxBcvList);
    return ListTile(
      leading: Icon(
        Icons.history,
        color: this.config.myColors["grey"],
      ),
      title: Text(
        hxReference,
        style: _entryTextStyle,
      ),
      onTap: () {
        //Navigator.pop(context);
        onTap([
          "open",
          [hxBcvList, "", bible.module]
        ]);
      },
      onLongPress: () {
        _addToFavouriteDialog(context, hxBcvList);
      },
    );
  }

  Widget _buildBookList(BuildContext context) {
    List<Widget> bookRowList;
    if ((_currentActiveVerse.join(".") == "0.0.0") ||
        (bible?.bookList == null)) {
      bookRowList = [_emptyRow(context)];
    } else {
      bookRowList = [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Wrap(
            spacing: 3.0,
            children: _buildBookChips(),
          ),
        ),
      ];
    }
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][8],
          style: _generalTextStyle),
      initiallyExpanded: true,
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: bookRowList,
      //onExpansionChanged: ,
    );
  }

  List<Widget> _buildBookChips() {
    List bookList = bible.bookList;
    List<Widget> bookChips;
    BibleParser parser = BibleParser(this.abbreviations);
    int currentBook = _currentActiveVerse[0];
    String abb;
    if (_displayAllBooks) {
      bookChips = List<Widget>.generate(
        bookList.length,
            (int index) {
          int book = bookList[index];
          abb = parser.standardAbbreviation[book.toString()];
          return ChoiceChip(
            label: Text(abb),
            selected: (book == currentBook),
            onSelected: (bool selected) {
              setState(() {
                _updateCurrentActiveVerse = false;
                _displayAllBooks = false;
                _selectedBook = book;
                headingBook = book;
              });
            },
          );
        },
      ).toList();
    } else {
      int book = _selectedBook ?? currentBook;
      abb = parser.standardAbbreviation[book.toString()];
      bookChips = [
        ChoiceChip(
          label: Text(abb),
          selected: true,
          onSelected: (bool selected) {
            setState(() {
              _displayAllBooks = true;
            });
          },
        )
      ];
    }
    return bookChips;
  }

  Widget _buildChapterList(BuildContext context) {
    List<Widget> chapterRowList;
    if ((_currentActiveVerse.join(".") == "0.0.0") ||
        (bible?.bookList == null)) {
      chapterRowList = [_emptyRow(context)];
    } else {
      List chapterList;
      int selectedChapter, selectedBook;
      int currentBook = _currentActiveVerse[0];
      if ((_selectedBook != null) && (_selectedBook != currentBook)) {
        chapterList = bible.getChapterList(_selectedBook);
        (chapterList.isNotEmpty)
            ? selectedChapter = chapterList[0]
            : selectedChapter = 0;
        selectedBook = _selectedBook;
        _selectedBook = currentBook;
      } else {
        chapterList = bible.getChapterList(currentBook);
        selectedChapter = _currentActiveVerse[1];
        selectedBook = currentBook;
      }
      _selectedChapter = selectedChapter;
      chapterRowList = [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Wrap(
            spacing: 3.0,
            children: List<Widget>.generate(
              chapterList.length,
                  (int index) {
                int chapter = chapterList[index];
                return ChoiceChip(
                  label: Text(chapter.toString()),
                  selected: (chapter == selectedChapter),
                  onSelected: (bool selected) {
                    List verses = bible.getVerseList(selectedBook, chapter);
                    if (verses.isNotEmpty) {
                      //Navigator.pop(context);
                      _selectedBook = selectedBook;
                      _currentActiveVerse = [selectedBook, chapter, verses[0]];
                      onTap([
                        "open",
                        [
                          _currentActiveVerse,
                          "",
                          bible.module
                        ]
                      ]);
                    }
                  },
                );
              },
            ).toList(),
          ),
        ),
      ];
    }
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][9],
          style: _generalTextStyle),
      initiallyExpanded: true,
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: chapterRowList,
    );
  }

  Widget _emptyRow(BuildContext context) {
    return ListTile(
      title: Text("... loading ..."),
      /*onTap: () {
        Navigator.pop(context);
      },*/
    );
  }

  // reference: https://github.com/flutter/flutter/blob/master/examples/flutter_gallery/lib/demo/material/dialog_demo.dart
  void _addToFavouriteDialog(BuildContext context, List bcvList) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
    theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    showMyDialog<DialogAction>(
      bcvList,
      context: context,
      child: AlertDialog(
        content: Text(
          this.interfaceAlert[this.abbreviations][3],
          style: dialogTextStyle,
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(this.interfaceAlert[this.abbreviations][0]),
            onPressed: () {
              Navigator.pop(context, DialogAction.cancel);
            },
          ),
          FlatButton(
            child: Text(this.interfaceAlert[this.abbreviations][1]),
            onPressed: () {
              Navigator.pop(context, DialogAction.addFavourite);
            },
          ),
        ],
      ),
    );
  }

  void _removeFromFavouriteDialog(BuildContext context, List bcvList) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
    theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    showMyDialog<DialogAction>(
      bcvList,
      context: context,
      child: AlertDialog(
        content: Text(
          this.interfaceAlert[this.abbreviations][4],
          style: dialogTextStyle,
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(this.interfaceAlert[this.abbreviations][0]),
            onPressed: () {
              Navigator.pop(context, DialogAction.cancel);
            },
          ),
          FlatButton(
            child: Text(this.interfaceAlert[this.abbreviations][2]),
            onPressed: () {
              Navigator.pop(context, DialogAction.removeFavourite);
            },
          ),
        ],
      ),
    );
  }

  void showMyDialog<T>(List bcvList, {BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.

      if (value == DialogAction.addFavourite) {
        onTap(["addFavourite", bcvList]);
      } else if (value == DialogAction.removeFavourite) {
        onTap(["removeFavourite", bcvList]);
      }
    });
  }

}
