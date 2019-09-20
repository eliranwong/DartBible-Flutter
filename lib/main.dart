// Copyright 2019 Eliran Wong. All rights reserved.

//import 'dart:as
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:indexed_list_view/indexed_list_view.dart';
import 'package:swipedetector/swipedetector.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'config.dart';
import 'Bibles.dart';
import 'BibleSearchDelegate.dart';
import 'TopicSearchDelegate.dart';
import 'PeopleSearchDelegate.dart';
import 'LocationSearchDelegate.dart';
import 'BibleSettings.dart';
import 'BibleParser.dart';
import 'DialogAction.dart';
import 'Morphology.dart';
import 'Helpers.dart';
import 'Tools.dart';
import 'MyDrawer.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //theme: ThemeData(brightness: Brightness.dark,),
      title: 'Unique Bible App',
      home: UniqueBible(),
    );
  }
}

class UniqueBible extends StatefulWidget {
  @override
  UniqueBibleState createState() => UniqueBibleState();
}

class UniqueBibleState extends State<UniqueBible> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _startup = false;
  bool _parallelBibles = false;
  List<dynamic> _data = [
    [
      [0, 0, 0],
      "... loading ...",
      ""
    ]
  ];
  List<int> _currentActiveVerse = [0, 0, 0];

  Bibles bibles;
  var scrollController;
  var _scrollIndex = 0;
  var config;
  var _verseNoFont, _verseFont, _verseFontHebrew, _verseFontGreek;
  var _activeVerseNoFont, _activeVerseFont, _activeVerseFontHebrew, _activeVerseFontGreek;
  var _interlinearStyle, _interlinearStyleDim;
  Color _appBarColor, _bottomAppBarColor, _backgroundColor;
  final _highlightStyle = TextStyle(
      fontWeight: FontWeight.bold,
      //fontStyle: FontStyle.italic,
      decoration: TextDecoration.underline,
      color: Colors.blue,
  );

  List searchData = [];

  String abbreviations = "ENG";
  Map interfaceApp = {
    "ENG": ["Unique Bible App", "Navigation menu", "Search", "Quick swap", "Settings", "Parallel mode", "Favourites", "History", "Books", "Chapters", "Timelines"],
    "TC": ["跨平台聖經工具", "菜單", "搜索", "快速轉換", "設定", "平衡模式", "收藏", "歷史", "書卷", "章", "時序圖"],
    "SC": ["跨平台圣经工具", "菜单", "搜索", "快速转换", "设定", "平衡模式", "收藏", "历史", "书卷", "章", "时序图"],
  };

  Map interfaceBottom = {
    "ENG": ["Popover Interlinear", "Bible Topics", "Bible Promises", "Parallel Passages", "Bible People", "Bible Locations"],
    "TC": ["原文逐字翻譯", "聖經主題", "聖經應許", "對觀經文", "聖經人物", "聖經地點"],
    "SC": ["原文逐字翻译", "圣经主题", "圣经应许", "对观经文", "圣经人物", "圣经地点"],
  };

  Map interfaceMessage = {
    "ENG": ["is selected.\n'Tap' it again to open your 'Favourite Action'.\nOr 'press' & 'hold' it for more actions.", "Loading cross-references ...", "Loading bibles for comparison ...", "Added to Favourites!"],
    "TC": ["被點選。\n再'按'此節可啟動'設定'中的'常用功能'。\n或'長按'可選擇更多功能。", "啟動相關經文 ...", "啟動版本比較 ...", "已收藏"],
    "SC": ["被点选。\n再'按'此节可启动'设定'中的'常用功能'。\n或'长按'可选择更多功能。", "启动相关经文 ...", "啟動版本比较 ...", "已收藏"],
  };

  Map interfaceDialog = {
    "ENG": ["Select an action:", "Share", "Copy", "Add to Copied Text", "Add to Favourites", "Cross-references", "Version Comparison", "Interlinear", "Morphology"],
    "TC": ["功能選項：", "分享", "複製", "增補複製內容", "收藏", "相關經文", "比較版本", "原文逐字翻譯", "原文形態學"],
    "SC": ["功能选项：", "分享", "拷贝", "增补拷贝内容", "收藏", "相关经文", "比较版本", "原文逐字翻译", "原文形态学"],
  };

  UniqueBibleState() {
    this.config = Config();
  }

  bool isAllBiblesReady() {
    return ((this.bibles?.bible1?.data != null) && (this.bibles?.bible2?.data != null) && (this.bibles?.iBible?.data != null));
  }

  Future _setup() async {
    if (!_startup) {
      await this.config.setDefault();

      this.abbreviations = this.config.abbreviations;
      this.bibles = Bibles(this.abbreviations);

      // pre-load bible1 data
      this.bibles.bible1 = Bible(this.config.bible1, this.abbreviations);
      await this.bibles.bible1.loadData();

      // pre-load bible2 data
      this.bibles.bible2 = Bible(this.config.bible2, this.abbreviations);
      this.bibles.bible2.loadData();

      this.bibles.iBible = Bible("OHGBi", this.abbreviations);
      this.bibles.iBible.loadData();

      // make sure these function runs on startup only
      _startup = true;

      setState(() {
        _currentActiveVerse = List<int>.from(this.config.historyActiveVerse.first);
        _data = this.bibles.bible1.openSingleChapter(_currentActiveVerse);
        _scrollIndex = getScrollIndex();
      });
    }
  }

  int getScrollIndex() {
    for (var i = 0; i < _data.length; i++) {
      if (_data[i].first[2] == _currentActiveVerse[2]) {
        return i;
      }
    }
    return 0;
  }

  void _scrollToCurrentActiveVerse() {
    this.scrollController.jumpToIndex(_scrollIndex);
  }

  void setActiveVerse(BuildContext context, List bcvList) {
    List newBcvList = List<int>.from(bcvList);
    if ((bcvList.isNotEmpty) && (newBcvList.join(".") != _currentActiveVerse.join("."))) {
      setState(() {
        _currentActiveVerse = newBcvList;
        updateHistoryActiveVerse();
      });
      if (this.config.instantAction != -1) {
        List instantActions = [showTip, showInterlinear];
        instantActions[this.config.instantAction](context, bcvList);
      }
    }
  }

  showTip(BuildContext context, List bcvList) {
    String verseReference = BibleParser(this.abbreviations).bcvToVerseReference(bcvList);
    String message = "'$verseReference' ${this.interfaceMessage[this.abbreviations].first}";
    _scaffoldKey.currentState.removeCurrentSnackBar();
    final snackBar = SnackBar(content: Text(message));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future showInterlinear(BuildContext context, List bcvList) async {
    if (this.bibles?.iBible?.data != null) {
      String verseReference = BibleParser(this.abbreviations).bcvToVerseReference(bcvList);

      var verseDirection = TextDirection.ltr;
      if (bcvList.first < 40) verseDirection = TextDirection.rtl;

      String verseText = this.bibles.iBible.openSingleVerse(bcvList);
      List<TextSpan> textContent = InterlinearHelper(this.config.verseTextStyle).getInterlinearSpan(verseText, bcvList.first)
        ..insert(0, TextSpan(text: " "))
        ..insert(0, TextSpan(text: "$verseReference", style: _highlightStyle))
        ..insert(0, TextSpan(text: " "))
      ;

      final selected = await showModalBottomSheet(context: context, builder: (BuildContext context) {
        return Container(
          color: config.myColors["background"],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: ListTile(
              title: RichText(
                text: TextSpan(
                  //style: DefaultTextStyle.of(context).style,
                  children: textContent,
                ),
                textDirection: verseDirection,
              ),
              //subtitle: Text(verseReference, style: _highlightStyle),
              onTap: () {
                Navigator.pop(context, bcvList);
                // note: do not use the following line to load interlinearView directly, which cause instability.
                // _loadInterlinearView(context, bcvList);
              },
            ),
          ),
        );
      });
      if (selected != null) _loadInterlinearView(context, selected);
    }
  }

  Future _newVerseSelected(List selected) async {
    _scrollToCurrentActiveVerse();

    List selectedBcvList = List<int>.from(selected.first);
    String selectedBible = selected.last;
    if (selectedBible.isEmpty) selectedBible = this.bibles.bible1.module;

    if ((selectedBible != this.bibles.bible1.module) && (selectedBible == this.bibles.bible2.module)) _swapBibles();

    if (selectedBcvList != null && selectedBcvList.isNotEmpty) {
      bool sameVerse = (selectedBcvList.join(".") == _currentActiveVerse.join("."));
      if ((!sameVerse) || ((sameVerse) && (selectedBible != this.bibles.bible1.module))) {
        if (selectedBible != this.bibles.bible1.module) {
          this.bibles.bible1 = Bible(selectedBible, this.abbreviations);
          await this.bibles.bible1.loadData();
          this.config.bible1 = selectedBible;
          this.config.save("bible1", selectedBible);
        }
        setState(() {
          _currentActiveVerse = selectedBcvList;
          updateHistoryActiveVerse();
          (_parallelBibles) ? _parallelBibles = false : _parallelBibles = true;
          _parallelBibles = _toggleParallelBibles();
          _scrollIndex = getScrollIndex();
        });
      }
    }
  }

  void updateHistoryActiveVerse() {
    List bcvList = List<int>.from(_currentActiveVerse);
    if (this.config.historyActiveVerse.first.join(".") != bcvList.join(".")) {
      this.config.historyActiveVerse.insert(0, bcvList);
      this.config.add("historyActiveVerse", (bcvList));
    }
  }

  goPreviousChapter() {
    int currentBook = _currentActiveVerse.first;
    int previousChapter = _currentActiveVerse[1] - 1;
    List chapterList = this.bibles.bible1.getChapterList(currentBook);

    if (chapterList.contains(previousChapter)) {
      List verseList = this.bibles.bible1.getVerseList(currentBook, previousChapter);
      if (verseList.isNotEmpty) _newVerseSelected([[currentBook, previousChapter, verseList.first], "", this.bibles.bible1.module]);
    } else {
      List bookList = this.bibles.bible1.bookList;
      int previousBook = currentBook - 1;
      if (bookList.contains(previousBook)) {
        chapterList = this.bibles.bible1.getChapterList(previousBook);
        if (chapterList.isNotEmpty) {
          previousChapter = chapterList[chapterList.length - 1];
          List verseList = this.bibles.bible1.getVerseList(previousBook, previousChapter);
          if (verseList.isNotEmpty) _newVerseSelected([[previousBook, previousChapter, verseList.first], "", this.bibles.bible1.module]);
        }
      }
    }
  }

  goNextChapter() {
    int currentBook = _currentActiveVerse.first;
    int nextChapter = _currentActiveVerse[1] + 1;
    List chapterList = this.bibles.bible1.getChapterList(currentBook);

    if (chapterList.contains(nextChapter)) {
      List verseList = this.bibles.bible1.getVerseList(currentBook, nextChapter);
      if (verseList.isNotEmpty) _newVerseSelected([[currentBook, nextChapter, verseList.first], "", this.bibles.bible1.module]);
    } else {
      List bookList = this.bibles.bible1.bookList;
      int nextBook = currentBook + 1;
      if (bookList.contains(nextBook)) {
        chapterList = this.bibles.bible1.getChapterList(nextBook);
        if (chapterList.isNotEmpty) {
          nextChapter = chapterList.first;
          List verseList = this.bibles.bible1.getVerseList(nextBook, nextChapter);
          if (verseList.isNotEmpty) _newVerseSelected([[nextBook, nextChapter, verseList.first], "", this.bibles.bible1.module]);
        }
      }
    }
  }

  void addToFavourite(List inBcvList) {
    setState(() {
      // ensure runtimeType is List<int>
      List bcvList = List<int>.from(inBcvList);

      var check = this.config.favouriteVerse.indexOf(bcvList);
      if (check != -1) this.config.favouriteVerse.removeAt(check);
      this.config.favouriteVerse.insert(0, bcvList);
      this.config.add("favouriteVerse", bcvList);
    });
  }

  void removeFromFavourite(List bcvList) {
    setState(() {
      var check = this.config.favouriteVerse.indexOf(bcvList);
      if (check != -1) this.config.favouriteVerse.removeAt(check);
      this.config.remove("favouriteVerse", bcvList);
    });
  }

  Future _openBibleSettings(BuildContext context) async {
    final BibleSettingsParser newBibleSettings = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BibleSettings(
            this.bibles.bible1,
            _currentActiveVerse,
            this.interfaceDialog,
            this.config,
          )),
    );
    if (newBibleSettings != null) {
      // Font size
      this.config.fontSize = newBibleSettings.fontSize;
      this.config.save("fontSize", newBibleSettings.fontSize);
      // Abbreviations
      this.abbreviations = newBibleSettings.abbreviations;
      this.config.abbreviations = newBibleSettings.abbreviations;
      updateBibleAbbreviations(newBibleSettings.abbreviations);
      this.config.save("abbreviations", newBibleSettings.abbreviations);
      // Bible comparison list
      this.config.compareBibleList = newBibleSettings.compareBibleList;
      this.config.save("compareBibleList", newBibleSettings.compareBibleList);
      // Instant action
      this.config.instantAction = newBibleSettings.instantAction;
      this.config.save("instantAction", newBibleSettings.instantAction);
      // Quick action
      this.config.favouriteAction = newBibleSettings.favouriteAction;
      this.config.save("favouriteAction", newBibleSettings.favouriteAction);
      // Background color
      this.config.backgroundColor = newBibleSettings.backgroundColor;
      this.config.save("backgroundColor", newBibleSettings.backgroundColor);
      // Newly selected verse
      var newVerse = [[newBibleSettings.book, newBibleSettings.chapter, newBibleSettings.verse,], "", newBibleSettings.module];
      _newVerseSelected(newVerse);
    }
  }

  void updateBibleAbbreviations(String abbreviations) {
    this.bibles.abbreviations = abbreviations;
    this.bibles.bible1.abbreviations = abbreviations;
    this.bibles.bible2.abbreviations = abbreviations;
  }

  Future _loadXRef(BuildContext context, List bcvList) async {
    _scaffoldKey.currentState.removeCurrentSnackBar();
    final snackBar = SnackBar(content: Text(this.interfaceMessage[this.abbreviations][1]));
    _scaffoldKey.currentState.showSnackBar(snackBar);
    
    var xRefData = await this.bibles.crossReference(bcvList);
    _scaffoldKey.currentState.removeCurrentSnackBar();

    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, xRefData, _currentActiveVerse));
    if (selected != null) {
      this.searchData = selected.first;
      _newVerseSelected(this.searchData[selected.last]);
    }
  }

  Future _loadCompare(BuildContext context, List bcvList) async {
    _scaffoldKey.currentState.removeCurrentSnackBar();
    final snackBar = SnackBar(content: Text(this.interfaceMessage[this.abbreviations][2]));
    _scaffoldKey.currentState.showSnackBar(snackBar);

    var compareData = await this.bibles.compareBibles(this.config.compareBibleList, bcvList);
    _scaffoldKey.currentState.removeCurrentSnackBar();

    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, compareData, _currentActiveVerse));
    if (selected != null) {
      this.searchData = selected.first;
      _newVerseSelected(this.searchData[selected.last]);
    }
  }

  Future _loadInterlinearView(BuildContext context, List bcvList, [String module]) async {
    if (isAllBiblesReady()) {
      String table = module ?? "OHGB";
      final List<Map> morphology = await SqliteHelper(this.config).getMorphology(bcvList, table);
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => InterlinearView(morphology, true, table, this.config, this.bibles)),
      );
      if (selected != null) _newVerseSelected(selected);
    }
  }

  Future _loadMorphologyView(BuildContext context, List bcvList, [String module]) async {
    if (isAllBiblesReady()) {
      String table = module ?? "OHGB";
      final List<Map> morphology = await SqliteHelper(this.config).getMorphology(bcvList, table);
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MorphologyView(morphology, true, table, this.config, this.bibles)),
      );
      if (selected != null) _newVerseSelected(selected);
    }
  }

  Future _loadTools(BuildContext context, Map title, String table, List menu, Icon icon) async {
    if (this.bibles?.bible1?.data != null) {
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ToolMenu(title, table, menu, this.config, this.bibles.bible1, icon, this.interfaceDialog, _currentActiveVerse)),
      );
      if (selected != null) {
        this.searchData = selected.first;
        _newVerseSelected(this.searchData[selected.last]);
      }
    }
  }

  Future _loadLocation(BuildContext context, List bcvList, [String module]) async {
    if (this.bibles?.bible1?.data != null) {
      String table = module ?? "EXLBL";
      final List<Map> tools = await SqliteHelper(this.config).getTools(bcvList, table);
      final List selected = await showSearch(
        context: context,
        delegate: LocationSearchDelegate(context, tools, this.config),
      );
      if ((selected != null) && (selected.isNotEmpty)) {
        _loadLocationVerses(context, selected.first);
      }
    }
  }

  Future _loadLocationVerses(BuildContext context, String locationID) async {
    final Database db = await SqliteHelper(this.config).initToolsDb();
    var statement = "SELECT Book, Chapter, Verse FROM EXLBL WHERE LocationID = ? ORDER BY Number";
    List<Map> tools = await db.rawQuery(statement, [locationID]);
    db.close();
    List<List> bcvLists = tools.map((i) => [i["Book"], i["Chapter"], i["Verse"]]).toList();
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, [], _currentActiveVerse, bcvLists));
    if (selected != null) {
      this.searchData = selected.first;
      _newVerseSelected(this.searchData[selected.last]);
    }
  }

  Future _loadPeople(BuildContext context, List bcvList, [String module]) async {
    if (this.bibles?.bible1?.data != null) {
      String table = module ?? "PEOPLE";
      final List<Map> tools = await SqliteHelper(this.config).getTools(bcvList, table);
      final List selected = await showSearch(
        context: context,
        delegate: PeopleSearchDelegate(context, tools, this.config),
      );
      if ((selected != null) && (selected.isNotEmpty)) {
        if (selected.first == 1) {
          _loadPeopleVerses(context, selected[1]);
        } else if (selected.first == 0) {
          _loadRelationship(context, selected[1], selected[2]);
        }
      }
    }
  }

  Future _loadPeopleVerses(BuildContext context, int personID) async {
    final Database db = await SqliteHelper(this.config).initToolsDb();
    var statement = "SELECT Book, Chapter, Verse FROM PEOPLE WHERE PersonID = ?";
    List<Map> tools = await db.rawQuery(statement, [personID]);
    db.close();
    List<List> bcvLists = tools.map((i) => [i["Book"], i["Chapter"], i["Verse"]]).toList();
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, [], _currentActiveVerse, bcvLists));
    if (selected != null) {
      this.searchData = selected.first;
      _newVerseSelected(this.searchData[selected.last]);
    }
  }

  Future _loadRelationship(BuildContext context, int personID, String name) async {
    final Database db = await SqliteHelper(this.config).initToolsDb();
    var statement = "SELECT PersonID, Name, Sex, Relationship FROM PEOPLERELATIONSHIP WHERE RelatedPersonID = ? AND Relationship != '[Reference]' ORDER BY RelationshipOrder";
    List<Map> tools = await db.rawQuery(statement, [personID]);
    db.close();
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Relationship(name, tools, this.config, this.bibles.bible1, this.interfaceDialog, _currentActiveVerse)),
    );
    if (selected != null) {
      this.searchData = selected.first;
      _newVerseSelected(this.searchData[selected.last]);
    }
  }

  Future _loadTopics(BuildContext context, List bcvList, [String module]) async {
    if (this.bibles?.bible1?.data != null) {
      String table = module ?? "EXLBT";
      final List<Map> tools = await SqliteHelper(this.config).getTopics(bcvList, table);
      final List selected = await showSearch(
        context: context,
        delegate: TopicSearchDelegate(context, tools, this.config),
      );
      if ((selected != null) && (selected.isNotEmpty)) {
        String entry = selected.first;
        (selected[1] == "open") ? _loadTopicView(context, entry) : _loadTopicVerses(context, entry);
      }
    }
  }

  Future _loadTopicView(BuildContext context, String entry) async {
    List topic = await SqliteHelper(this.config).getTopic(entry);
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TopicView(this.config, topic, this.bibles)),
    );
    if (selected != null) _newVerseSelected(selected);
  }

  Future _loadTopicVerses(BuildContext context, String entry) async {
    final Database db = await SqliteHelper(this.config).initToolsDb();
    var statement = "SELECT Book, Chapter, Verse, toVerse FROM EXLBT WHERE Entry = ?";
    List<Map> tools = await db.rawQuery(statement, [entry]);
    db.close();
    List<String> bcvStrings = tools.map((i) {
      if (i["Verse"] == i["toVerse"]) {
        return "${i["Book"]}.${i["Chapter"]}.${i["Verse"]}";
      } else {
        return "${i["Book"]}.${i["Chapter"]}.${i["Verse"]}.${i["Chapter"]}.${i["toVerse"]}";
      }
    }).toSet().toList();
    List<List> bcvLists = bcvStrings.map((i) => i.split(".").map((i) => int.parse(i)).toList()).toList();
    final List selected = await showSearch(
        context: context,
        //delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, verseData, _currentActiveVerse));
        delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, [], _currentActiveVerse, bcvLists));
    if (selected != null) {
      this.searchData = selected.first;
      _newVerseSelected(this.searchData[selected.last]);
    }
  }

  bool _toggleParallelBibles() {
    if ((_parallelBibles) && (this.bibles?.bible1?.data != null)) {
      _data = this.bibles.bible1.openSingleChapter(_currentActiveVerse);
      return false;
    } else if ((!_parallelBibles) &&
        (this.bibles?.bible1?.data != null) &&
        (this.bibles?.bible2?.data != null)) {
      _data = this.bibles.parallelBibles(_currentActiveVerse);
      return true;
    }
    return _parallelBibles;
  }

  void _swapBibles() {
    this.bibles.bible3 = this.bibles.bible1;
    this.bibles.bible1 = this.bibles.bible2;
    this.bibles.bible2 = this.bibles.bible3;
    this.bibles.bible3 = Bible("KJV", this.abbreviations);
    this.config.bible1 = this.bibles.bible1.module;
    this.config.bible2 = this.bibles.bible2.module;
    this.config.save("bible1", this.bibles.bible1.module);
    this.config.save("bible2", this.bibles.bible2.module);
    _reLoadBibles();
  }

  void _reLoadBibles() {
    (_parallelBibles)
        ? _data = this.bibles.parallelBibles(_currentActiveVerse)
        : _data = this.bibles.bible1.openSingleChapter(_currentActiveVerse);
  }

  void _updateTextStyle() {
    // adjustment with changes of brightness
    _backgroundColor = Colors.blueGrey[config.backgroundColor];
    Color blueAccent, indigo, black, blue, deepOrange, grey;
    if (this.config.backgroundColor >= 500) {
      blueAccent = Colors.blueAccent[100];
      indigo = Colors.indigo[200];
      black = Colors.grey[300];
      blue = Colors.blue[300];
      deepOrange = Colors.deepOrange[300];
      grey = Colors.grey[400];
      _appBarColor = Colors.blueGrey[this.config.backgroundColor - 200];
      _bottomAppBarColor = Colors.grey[500];
    } else {
      blueAccent = Colors.blueAccent[700];
      indigo = Colors.indigo[800];
      black = Colors.black;
      blue = Colors.blue[700];
      deepOrange = Colors.deepOrange[700];
      grey = Colors.grey[700];
      //_appBarColor = Theme.of(context).appBarTheme.color;
      _appBarColor = Colors.blue[600];
      _bottomAppBarColor = Colors.grey[config.backgroundColor + 100];
    }

    // define a set of colors
    this.config.myColors = {
      "blueAccent": blueAccent,
      "indigo": indigo,
      "black": black,
      "blue": blue,
      "deepOrange": deepOrange,
      "grey": grey,
      "appBarColor": _appBarColor,
      "bottomAppBarColor": _bottomAppBarColor,
      "background": _backgroundColor,
    };

    // update various font text style here
    _verseNoFont = TextStyle(fontSize: (this.config.fontSize - 3), color: blueAccent);
    _verseFont = TextStyle(fontSize: this.config.fontSize, color: black);
    _verseFontHebrew = TextStyle(fontFamily: "Ezra SIL", fontSize: (this.config.fontSize + 4), color: black);
    _verseFontGreek = TextStyle(fontSize: (this.config.fontSize + 2), color: black);
    _activeVerseNoFont = TextStyle(fontSize: (this.config.fontSize - 3), color: blue, fontWeight: FontWeight.bold);
    _activeVerseFont = TextStyle(fontSize: this.config.fontSize, color: indigo);
    _activeVerseFontHebrew = TextStyle(fontFamily: "Ezra SIL", fontSize: (this.config.fontSize + 4), color: indigo);
    _activeVerseFontGreek = TextStyle(fontSize: (this.config.fontSize + 2), color: indigo);
    _interlinearStyle = TextStyle(fontSize: (this.config.fontSize - 3), color: deepOrange);
    _interlinearStyleDim = TextStyle(fontSize: (this.config.fontSize - 3), color: grey, fontStyle: FontStyle.italic);

    // set the same font settings, which is passed to search delegate
    this.config.verseTextStyle = {
      "HebrewFont": TextStyle(fontFamily: "Ezra SIL"),
      "verseNoFont": _verseNoFont,
      "verseFont": _verseFont,
      "verseFontHebrew": _verseFontHebrew,
      "verseFontGreek": _verseFontGreek,
      "activeVerseNoFont": _activeVerseNoFont,
      "activeVerseFont": _activeVerseFont,
      "activeVerseFontHebrew": _activeVerseFontHebrew,
      "activeVerseFontGreek": _activeVerseFontGreek,
      "interlinearStyle": _interlinearStyle,
      "interlinearStyleDim": _interlinearStyleDim,
    };

    config.updateThemeData();
  }

  void _updateAppBarTitle() {
    // update App bar title
    if (this.bibles?.bible1?.bookList != null) {
      if (_parallelBibles) {
        this.interfaceApp[this.abbreviations].first = BibleParser(this.abbreviations).bcvToChapterReference(_currentActiveVerse);
      } else {
        this.interfaceApp[this.abbreviations].first = "${BibleParser(this.abbreviations).bcvToChapterReference(_currentActiveVerse)} [${this.bibles.bible1.module}]";
      }
    }
  }

  Widget _buildDrawer() {
    if (this.bibles?.bible1?.data == null) {
      return Drawer(
          child: Text("... loading ..."),
      );
    }
    return MyDrawer(this.config, this.bibles.bible1, _currentActiveVerse, (List data) {
      Map actions = {
        "open": _newVerseSelected,
        "addFavourite": addToFavourite,
        "removeFavourite": removeFromFavourite,
      };
      actions[data.first](data.last);
    });
  }

  @override
  build(BuildContext context) {

    _setup();
    _updateTextStyle();
    _updateAppBarTitle();

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      //drawer: MyDrawer(this.config, this.bibles.bible1, _currentActiveVerse),
      /*
      // trigger actions when drawer is opened or closed:
      // find a fix of drawerCallback at:
      // https://juejin.im/post/5be5356bf265da61602c6f68
      drawer: DrawerController(
        child: _buildDrawer(),
        alignment: DrawerAlignment.start,
        drawerCallback: (isOpen) {
          if (!isOpen) {
            setState(() {
              _selectedBook = _currentActiveVerse.first;
              _displayAllBooks = false;
            });
          }
        },
      ),
      */
      appBar: _buildAppBar(),
      body: Container(
        color: _backgroundColor,
        child: SwipeDetector(
          child: _buildVerses(context),
          onSwipeLeft: () {
            goNextChapter();
          },
          onSwipeRight: () {
            goPreviousChapter();
          },
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _appBarColor,
        onPressed: () {
          setState(() {
            _parallelBibles = _toggleParallelBibles();
            _scrollIndex = getScrollIndex();
          });
        },
        tooltip: this.interfaceApp[this.abbreviations][5],
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar() {
    //original color: Theme.of(context).appBarTheme.color
    return AppBar(
      backgroundColor: _appBarColor,
      title: Text(this.interfaceApp[this.abbreviations].first),
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            //tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            tooltip: this.interfaceApp[this.abbreviations][1],
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState.openDrawer();
            },
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          tooltip: this.interfaceApp[this.abbreviations][2],
          icon: const Icon(Icons.search),
          onPressed: () async {
            final List selected = await showSearch(
              context: context,
              delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, this.searchData, _currentActiveVerse),
            );
            if (selected != null) {
              this.searchData = selected.first;
              _newVerseSelected(this.searchData[selected.last]);
            }
          },
        ),
        IconButton(
          tooltip: this.interfaceApp[this.abbreviations][3],
          icon: const Icon(Icons.swap_calls),
          onPressed: () {
            setState(() {
              _swapBibles();
            });
          },
        ),
        IconButton(
          tooltip: this.interfaceApp[this.abbreviations][4],
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _openBibleSettings(context);
          },
        ),
      ],
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      // Container placed here is necessary for controlling the height of the ListView.
      child: Container(
        padding: EdgeInsets.only(right: 84.0),
        height: 48,
        color: _bottomAppBarColor,
        child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              IconButton(
                tooltip: this.interfaceBottom[this.abbreviations].first,
                icon: const Icon(Icons.layers),
                onPressed: () {
                  showInterlinear(context, _currentActiveVerse);
                },
              ),
              IconButton(
                tooltip: this.interfaceBottom[this.abbreviations][1],
                icon: const Icon(Icons.title),
                onPressed: () {
                  _loadTopics(context, _currentActiveVerse);
                },
              ),
              IconButton(
                tooltip: this.interfaceBottom[this.abbreviations][4],
                icon: const Icon(Icons.people),
                onPressed: () {
                  _loadPeople(context, _currentActiveVerse);
                },
              ),
              IconButton(
                tooltip: this.interfaceBottom[this.abbreviations][5],
                icon: const Icon(Icons.pin_drop),
                onPressed: () {
                  _loadLocation(context, _currentActiveVerse);
                },
              ),
              IconButton(
                tooltip: this.interfaceBottom[this.abbreviations][2],
                icon: const Icon(Icons.games),
                onPressed: () {
                  Map title = {
                    "ENG": this.interfaceBottom["ENG"][2],
                    "TC": this.interfaceBottom["TC"][2],
                    "SC": this.interfaceBottom["SC"][2],
                  };
                  List menu = [
                    "Precious Bible Promises I",
                    "Precious Bible Promises II",
                    "Precious Bible Promises III",
                    "Precious Bible Promises IV",
                    "Take Words with You",
                    "Index",
                    "When you ...",
                    "當你 ……",
                    "当你 ……",
                  ];
                  _loadTools(context, title, "PROMISES", menu, Icon(Icons.games, color: this.config.myColors["black"],));
                },
              ),
              IconButton(
                tooltip: this.interfaceBottom[this.abbreviations][3],
                icon: const Icon(Icons.compare),
                onPressed: () {
                  Map title = {
                    "ENG": this.interfaceBottom["ENG"][3],
                    "TC": this.interfaceBottom["TC"][3],
                    "SC": this.interfaceBottom["SC"][3],
                  };
                  List menu = [
                    "History of Israel I",
                    "History of Israel II",
                    "Gospels I",
                    "Gospels II",
                    "摩西五經",
                    "撒母耳記，列王紀，歷代志",
                    "詩篇",
                    "福音書（可，太，路〔順序〕，約） x 54",
                    "福音書（可，太，路〔不順序〕） x 14",
                    "福音書（可，太） x 11",
                    "福音書（可，太，約） x 4",
                    "福音書（可，路） x 7",
                    "福音書（太，路） x 32",
                    "福音書（可〔獨家記載〕） x 5",
                    "福音書（太〔獨家記載〕） x 30",
                    "福音書（路〔獨家記載〕） x 39",
                    "福音書（約〔獨家記載〕） x 61",
                  ];
                  _loadTools(context, title, "PARALLEL", menu, Icon(Icons.compare, color: this.config.myColors["black"],));
                },
              ),
              IconButton(
                tooltip: this.interfaceBottom[this.abbreviations][3],
                icon: const Icon(Icons.share),
                onPressed: () {
                  String chapterReference = BibleParser(this.abbreviations).bcvToChapterReference(_data.first.first);
                  String verses = _data.map((i) => "${i.first.last.toString()} ${i[1]}").toList().join("\n");
                  Share.share("$chapterReference\n$verses");
                },
              ),
              /*IconButton(
                tooltip: this.interfaceBottom[this.abbreviations][3],
                icon: const Icon(Icons.speaker_phone),
                onPressed: () {
                  String chapterReference = BibleParser(this.abbreviations).bcvToChapterReference(_data.first.first);
                  String verses = _data.map((i) => i[1]).toList().join("\n");
                  _speak("$chapterReference\n$verses");
                },
              ),*/
            ]
        ),
      ),
    );
  }

  Future _speak(message) async {
    FlutterTts flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    var result = await flutterTts.speak(message);
    //if (result == 1) setState(() => ttsState = TtsState.playing);
  }

  Widget _buildVerses(BuildContext context) {
    if (_currentActiveVerse == null) {
      this.scrollController = IndexedScrollController();
    } else {
      this.scrollController = IndexedScrollController(
        initialIndex: _scrollIndex,
        initialScrollOffset: 0.0,
      );
    }
    return IndexedListView.builder(
        padding: EdgeInsets.zero,
        controller: this.scrollController,
        // workaround of finite list with IndexedListView:
        // do not use itemCount in this case
        // build empty rows with embedded actions
        // itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildVerseRow(context, i);
        },
        emptyItemBuilder: (context, i) {
          return _buildEmptyVerseRow(i);
        });
  }

  Widget _buildVerseRow(BuildContext context, int i) {
    var verseDirection = TextDirection.ltr;
    var verseFont = _verseFont;
    var verseActiveFont = _activeVerseFont;
    var verseNo;
    var verseContent;
    if ((i >= 0) && (i < _data.length)) {
      // assign text style here
      List verseData = _data[i];
      List bcvList = verseData.first;
      int book = bcvList.first;
      String module = verseData.last;

      if ((this.config.hebrewBibles.contains(module)) && (book < 40)) {
        verseFont = _verseFontHebrew;
        verseActiveFont = _activeVerseFontHebrew;
        verseDirection = TextDirection.rtl;
      } else if (this.config.greekBibles.contains(module)) {
        verseFont = _verseFontGreek;
        verseActiveFont = _activeVerseFontGreek;
      }
      (_parallelBibles) ? verseNo = "[${bcvList[2]}] [$module] " : verseNo = "[${bcvList[2]}] ";

      verseContent = verseData[1];
      List<TextSpan> wordSpans;

      // check if it is an active verse or not
      if (bcvList[2] == _currentActiveVerse[2]) {
        if (this.config.interlinearBibles.contains(module)) {
          List<TextSpan> interlinearSpans = InterlinearHelper(this.config.verseTextStyle).getInterlinearSpan(verseContent, book, true);
          wordSpans = <TextSpan>[TextSpan(text: verseNo, style: _activeVerseNoFont), ...interlinearSpans];
        } else {
          wordSpans = <TextSpan>[TextSpan(text: verseNo, style: _activeVerseNoFont), TextSpan(text: verseContent, style: verseActiveFont)];
        }
        return ListTile(
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: wordSpans,
            ),
            textDirection: verseDirection,
          ),
          //subtitle: Text(interlinear),
          onTap: () {
            _tapActiveVerse(context, _data[i].first);
          },
          onLongPress: () {
            _longPressedActiveVerse(context, _data[i]);
          },
        );
      } else {
        if (this.config.interlinearBibles.contains(module)) {
          List<TextSpan> interlinearSpans = InterlinearHelper(this.config.verseTextStyle).getInterlinearSpan(verseContent, book);
          wordSpans = <TextSpan>[TextSpan(text: verseNo, style: _verseNoFont), ...interlinearSpans];
        } else {
          wordSpans = <TextSpan>[TextSpan(text: verseNo, style: _verseNoFont), TextSpan(text: verseContent, style: verseFont)];
        }
        return ListTile(
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: wordSpans,
            ),
            textDirection: verseDirection,
          ),
          onTap: () {
            (module == this.bibles.bible1.module) ? _scrollIndex = i : _scrollIndex = (i - 1);
            setActiveVerse(context, _data[i].first);
          },
          onLongPress: () {
            _longPressedVerse(context, _data[i]);
          },
        );
      }
    }
    return null;
  }

  Widget _buildEmptyVerseRow(int i) {
    return ListTile(
      title: Text(
        "",
        style: _verseFont,
      ),
      onTap: () {
        if (i < 0) {
          this.scrollController.jumpToIndex(0);
        } else if (i > _data.length) {
          this.scrollController.jumpToIndex(_data.length - 1);
        }
      },
    );
  }

  void _tapActiveVerse(context, bcvList) {
    if (this.config.favouriteAction != -1) {
      List favouriteActions = [addToFavourite, _loadXRef, _loadCompare, _loadInterlinearView, _loadMorphologyView];
      favouriteActions[this.config.favouriteAction](context, bcvList);
    }
  }

  // reference: https://api.flutter.dev/flutter/material/SimpleDialog-class.html
  Future<void> _longPressedVerse(BuildContext context, List verseData) async {
    var copiedText = await Clipboard.getData('text/plain');
    switch (await showDialog<DialogAction>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(this.interfaceDialog[this.abbreviations].first),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.share); },
                child: Text(this.interfaceDialog[this.abbreviations][1]),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.copy); },
                child: Text(this.interfaceDialog[this.abbreviations][2]),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.addCopy); },
                child: Text(this.interfaceDialog[this.abbreviations][3]),
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

  Future<void> _longPressedActiveVerse(BuildContext context, List verseData) async {
    var copiedText = await Clipboard.getData('text/plain');
    List<Widget> dialogOptions = [
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, DialogAction.share); },
            child: Text(this.interfaceDialog[this.abbreviations][1]),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, DialogAction.copy); },
            child: Text(this.interfaceDialog[this.abbreviations][2]),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, DialogAction.addCopy); },
            child: Text(this.interfaceDialog[this.abbreviations][3]),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, DialogAction.addFavourite); },
            child: Text(this.interfaceDialog[this.abbreviations][4]),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, DialogAction.crossReference); },
            child: Text(this.interfaceDialog[this.abbreviations][5]),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, DialogAction.compareAll); },
            child: Text(this.interfaceDialog[this.abbreviations][6]),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, DialogAction.interlinearOHGB); },
            child: Text("OHGB ${this.interfaceDialog[this.abbreviations][7]}"),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, DialogAction.morphologyOHGB); },
            child: Text("OHGB ${this.interfaceDialog[this.abbreviations][8]}"),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, DialogAction.interlinearABP); },
            child: Text("ABP ${this.interfaceDialog[this.abbreviations][7]}"),
          ),
        ];
    int bookNo = verseData.first.first;
    if ((bookNo < 40) || (bookNo > 66)) {
      List<Widget> lxxDialogOptions = [
        SimpleDialogOption(
          onPressed: () { Navigator.pop(context, DialogAction.interlinearLXX1); },
          child: Text("LXX1 ${this.interfaceDialog[this.abbreviations][7]}"),
        ),
        SimpleDialogOption(
          onPressed: () { Navigator.pop(context, DialogAction.morphologyLXX1); },
          child: Text("LXX1 ${this.interfaceDialog[this.abbreviations][8]}"),
        ),
        SimpleDialogOption(
          onPressed: () { Navigator.pop(context, DialogAction.interlinearLXX2); },
          child: Text("LXX2 ${this.interfaceDialog[this.abbreviations][7]}"),
        ),
        SimpleDialogOption(
          onPressed: () { Navigator.pop(context, DialogAction.morphologyLXX2); },
          child: Text("LXX2 ${this.interfaceDialog[this.abbreviations][8]}"),
        ),
      ];
      dialogOptions = [...dialogOptions, ...lxxDialogOptions];
    }
    switch (await showDialog<DialogAction>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(this.interfaceDialog[this.abbreviations].first),
            children: dialogOptions,
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
      case DialogAction.addFavourite:
        addToFavourite(verseData.first);
        break;
      case DialogAction.crossReference:
        _loadXRef(context, verseData.first);
        break;
      case DialogAction.compareAll:
        _loadCompare(context, verseData.first);
        break;
      case DialogAction.interlinearOHGB:
        _loadInterlinearView(context, verseData.first, "OHGB");
        break;
      case DialogAction.morphologyOHGB:
        _loadMorphologyView(context, verseData.first, "OHGB");
        break;
      case DialogAction.interlinearLXX1:
        _loadInterlinearView(context, verseData.first, "LXX1");
        break;
      case DialogAction.morphologyLXX1:
        _loadMorphologyView(context, verseData.first, "LXX1");
        break;
      case DialogAction.interlinearLXX2:
        _loadInterlinearView(context, verseData.first, "LXX2");
        break;
      case DialogAction.morphologyLXX2:
        _loadMorphologyView(context, verseData.first, "LXX2");
        break;
      case DialogAction.interlinearABP:
        _loadInterlinearView(context, verseData.first, "ABP");
        break;
      default:
    }
  }

}
