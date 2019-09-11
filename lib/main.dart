// Copyright 2019 Eliran Wong. All rights reserved.

//import 'dart:as
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:indexed_list_view/indexed_list_view.dart';
import 'package:swipedetector/swipedetector.dart';
import 'package:unique_bible_app/config.dart';
import 'package:unique_bible_app/Bibles.dart';
import 'package:unique_bible_app/BibleSearchDelegate.dart';
import 'package:unique_bible_app/TopicSearchDelegate.dart';
import 'package:unique_bible_app/BibleSettings.dart';
import 'package:unique_bible_app/BibleParser.dart';
import 'package:unique_bible_app/DialogAction.dart';
import 'package:unique_bible_app/Morphology.dart';
import 'package:unique_bible_app/Helpers.dart';
import 'package:sqflite/sqflite.dart';


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
  final _highlightStyle = TextStyle(
      fontWeight: FontWeight.bold,
      //fontStyle: FontStyle.italic,
      decoration: TextDecoration.underline,
      color: Colors.blue,
  );

  List searchData = [];

  String abbreviations = "ENG";
  Map interfaceApp = {
    "ENG": ["Unique Bible App", "Navigation menu", "Search", "Quick swap", "Settings", "Parallel mode", "Favourites", "History", "Books", "Chapters"],
    "TC": ["跨平台聖經工具", "菜單", "搜索", "快速轉換", "設定", "平衡模式", "收藏", "歷史", "書卷", "章"],
    "SC": ["跨平台圣经工具", "菜单", "搜索", "快速转换", "设定", "平衡模式", "收藏", "历史", "书卷", "章"],
  };

  Map interfaceBottom = {
    "ENG": ["Popover Interlinear", "Bible Topics"],
    "TC": ["原文逐字翻譯", "聖經主題"],
    "SC": ["原文逐字翻译", "圣经主题"],
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

  Map interfaceAlert = {
    "ENG": ["CANCEL", "ADD", "REMOVE", "Add to Favourites?", "Remove from Favourites?"],
    "TC": ["取消", "收藏", "删除", "收藏？", "删除？"],
    "SC": ["取消", "收藏", "删除", "收藏？", "删除？"],
  };

  UniqueBibleState() {
    this.config = Config();
  }

  bool isAllBiblesReady() {
    return ((this.bibles?.bible1?.data != null) && (this.bibles?.bible2?.data != null) && (this.bibles?.bible3?.data != null));
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
        _currentActiveVerse = List<int>.from(this.config.historyActiveVerse[0]);
        _data = this.bibles.bible1.openSingleChapter(_currentActiveVerse);
        _scrollIndex = getScrollIndex();
      });
    }
  }

  int getScrollIndex() {
    for (var i = 0; i < _data.length; i++) {
      if (_data[i][0][2] == _currentActiveVerse[2]) {
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
    String message = "'$verseReference' ${this.interfaceMessage[this.abbreviations][0]}";
    final snackBar = SnackBar(content: Text(message));
    Scaffold.of(context).showSnackBar(snackBar);
  }

  Future showInterlinear(BuildContext context, List bcvList) async {
    if (this.bibles?.iBible?.data != null) {
      String verseReference = BibleParser(this.abbreviations).bcvToVerseReference(bcvList);

      var verseDirection = TextDirection.ltr;
      if (bcvList[0] < 40) verseDirection = TextDirection.rtl;

      String verseText = this.bibles.iBible.openSingleVerse(bcvList);
      List<TextSpan> textContent = InterlinearHelper(this.config.verseTextStyle).getInterlinearSpan(verseText, bcvList[0])
        ..insert(0, TextSpan(text: " "))
        ..insert(0, TextSpan(text: "$verseReference", style: _highlightStyle))
        ..insert(0, TextSpan(text: " "))
      ;

      showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
        return Container(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
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
                _loadInterlinearView(context, bcvList);
              },
            ),
          ),
        );
      });
    }
  }

  Future _newVerseSelected(List selected) async {
    _scrollToCurrentActiveVerse();

    List selectedBcvList = List<int>.from(selected[0]);
    String selectedBible = selected[2];
    if (selectedBible.isEmpty) selectedBible = this.bibles.bible1.module;

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
    if (this.config.historyActiveVerse[0].join(".") != bcvList.join(".")) {
      this.config.historyActiveVerse.insert(0, bcvList);
      this.config.add("historyActiveVerse", (bcvList));
    }
  }

  goPreviousChapter() {
    int currentBook = _currentActiveVerse[0];
    int previousChapter = _currentActiveVerse[1] - 1;
    List chapterList = this.bibles.bible1.getChapterList(currentBook);

    if (chapterList.contains(previousChapter)) {
      List verseList = this.bibles.bible1.getVerseList(currentBook, previousChapter);
      if (verseList.isNotEmpty) _newVerseSelected([[currentBook, previousChapter, verseList[0]], "", this.bibles.bible1.module]);
    } else {
      List bookList = this.bibles.bible1.bookList;
      int previousBook = currentBook - 1;
      if (bookList.contains(previousBook)) {
        chapterList = this.bibles.bible1.getChapterList(previousBook);
        if (chapterList.isNotEmpty) {
          previousChapter = chapterList[chapterList.length - 1];
          List verseList = this.bibles.bible1.getVerseList(previousBook, previousChapter);
          if (verseList.isNotEmpty) _newVerseSelected([[previousBook, previousChapter, verseList[0]], "", this.bibles.bible1.module]);
        }
      }
    }
  }

  goNextChapter() {
    int currentBook = _currentActiveVerse[0];
    int nextChapter = _currentActiveVerse[1] + 1;
    List chapterList = this.bibles.bible1.getChapterList(currentBook);

    if (chapterList.contains(nextChapter)) {
      List verseList = this.bibles.bible1.getVerseList(currentBook, nextChapter);
      if (verseList.isNotEmpty) _newVerseSelected([[currentBook, nextChapter, verseList[0]], "", this.bibles.bible1.module]);
    } else {
      List bookList = this.bibles.bible1.bookList;
      int nextBook = currentBook + 1;
      if (bookList.contains(nextBook)) {
        chapterList = this.bibles.bible1.getChapterList(nextBook);
        if (chapterList.isNotEmpty) {
          nextChapter = chapterList[0];
          List verseList = this.bibles.bible1.getVerseList(nextBook, nextChapter);
          if (verseList.isNotEmpty) _newVerseSelected([[nextBook, nextChapter, verseList[0]], "", this.bibles.bible1.module]);
        }
      }
    }
  }

  void addToFavourite(BuildContext context, List inBcvList) {
    //final snackBar = SnackBar(content: Text(interfaceMessage[this.abbreviations][3]));
    //Scaffold.of(context).showSnackBar(snackBar);

    setState(() {
      // make sure runtimeType is List<int>
      List bcvList = List<int>.from(inBcvList);

      var check = this.config.favouriteVerse.indexOf(bcvList);
      if (check != -1) this.config.favouriteVerse.removeAt(check);
      this.config.favouriteVerse.insert(0, bcvList);
      this.config.add("favouriteVerse", bcvList);
    });
  }

  void removeFromFavourite(List bcvList) {
    var check = this.config.favouriteVerse.indexOf(bcvList);
    if (check != -1) this.config.favouriteVerse.removeAt(check);
    this.config.remove("favouriteVerse", bcvList);
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
    final snackBar = SnackBar(content: Text(this.interfaceMessage[this.abbreviations][1]));
    Scaffold.of(context).showSnackBar(snackBar);

    var xRefData = await this.bibles.crossReference(bcvList);
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, xRefData));
    if (selected != null) {
      this.searchData = selected[0];
      _newVerseSelected(this.searchData[selected[1]]);
    }
  }

  Future _loadCompare(BuildContext context, List bcvList) async {
    final snackBar = SnackBar(content: Text(this.interfaceMessage[this.abbreviations][2]));
    Scaffold.of(context).showSnackBar(snackBar);

    var compareData = await this.bibles.compareBibles(this.config.compareBibleList, bcvList);
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, compareData));
    if (selected != null) {
      this.searchData = selected[0];
      _newVerseSelected(this.searchData[selected[1]]);
    }
  }

  Future _loadInterlinearView(BuildContext context, List bcvList, [String module]) async {
    if (isAllBiblesReady()) {
      String table = module ?? "OHGB";
      final List<Map> morphology = await getMorphology(bcvList, table);
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
      final List<Map> morphology = await getMorphology(bcvList, table);
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MorphologyView(morphology, true, table, this.config, this.bibles)),
      );
      if (selected != null) _newVerseSelected(selected);
    }
  }

  Future _loadTopics(BuildContext context, List bcvList, [String module]) async {
    if (this.bibles?.bible1?.data != null) {
      String table = module ?? "EXLBT";
      final List<Map> tools = await getTools(bcvList, table);
      final List selected = await showSearch(
        context: context,
        delegate: TopicSearchDelegate(context, tools, this.config),
      );
      if ((selected != null) && (selected.isNotEmpty)) _loadTopicVerses(context, selected[0]);
    }
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
        return "${i["Book"]}.${i["Chapter"]}.${i["Verse"]}.${i["Chapter"]}.${i["toVerse"]}";;
      }
    }).toSet().toList();
    List<List> bcvLists = bcvStrings.map((i) => i.split(".").map((i) => int.parse(i)).toList()).toList();
    List verseData = this.bibles.bible1.openMultipleVerses(bcvLists);
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, verseData));
    if (selected != null) {
      this.searchData = selected[0];
      _newVerseSelected(this.searchData[selected[1]]);
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

  @override
  build(BuildContext context) {
    _setup();
    // update various font text style here
    _verseNoFont = TextStyle(fontSize: (this.config.fontSize - 3), color: Colors.blueAccent);
    _verseFont = TextStyle(fontSize: this.config.fontSize, color: Colors.black);
    _verseFontHebrew = TextStyle(fontFamily: "Ezra SIL", fontSize: (this.config.fontSize + 4), color: Colors.black);
    _verseFontGreek = TextStyle(fontSize: (this.config.fontSize + 2), color: Colors.black);
    _activeVerseNoFont = TextStyle(fontSize: (this.config.fontSize - 3), color: Colors.blue, fontWeight: FontWeight.bold);
    _activeVerseFont = TextStyle(fontSize: this.config.fontSize, color: Colors.indigo, fontWeight: FontWeight.bold);
    _activeVerseFontHebrew = TextStyle(fontFamily: "Ezra SIL", fontSize: (this.config.fontSize + 4), color: Colors.indigo, fontWeight: FontWeight.bold);
    _activeVerseFontGreek = TextStyle(fontSize: (this.config.fontSize + 2), color: Colors.indigo, fontWeight: FontWeight.bold);
    _interlinearStyle = TextStyle(fontSize: (this.config.fontSize - 3), color: Colors.deepOrange);
    _interlinearStyleDim = TextStyle(fontSize: (this.config.fontSize - 3), color: Colors.grey, fontStyle: FontStyle.italic);
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
    // update App bar title
    if (this.bibles?.bible1?.bookList != null) {
      if (_parallelBibles) {
        this.interfaceApp[this.abbreviations][0] = BibleParser(this.abbreviations).bcvToChapterReference(_currentActiveVerse);
      } else {
        this.interfaceApp[this.abbreviations][0] = "${BibleParser(this.abbreviations).bcvToChapterReference(_currentActiveVerse)} [${this.bibles.bible1.module}]";
      }
    }
    return Scaffold(
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
                //decoration: BoxDecoration(color: Colors.blue,),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: AssetImage("assets/images/account.png"),
                ),
                accountName: const Text("Eliran Wong"),
                accountEmail: const Text("support@BibleTools.app")),
            _buildFavouriteList(context),
            _buildHistoryList(context),
            _buildBookList(context),
            _buildChapterList(context),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(this.interfaceApp[this.abbreviations][0]),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              //tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              tooltip: this.interfaceApp[this.abbreviations][1],
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
                delegate: BibleSearchDelegate(context, this.bibles.bible1, this.interfaceDialog, this.config, this.searchData),
              );
              if (selected != null) {
                this.searchData = selected[0];
                _newVerseSelected(this.searchData[selected[1]]);
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
      ),
      body: Container(
        color: Colors.white,
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
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(children: <Widget>[
          IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][1],
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              _loadTopics(context, _currentActiveVerse);
            },
          ),
          IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][0],
            icon: const Icon(Icons.layers),
            onPressed: () {
              showInterlinear(context, _currentActiveVerse);
            },
          ),
        ]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
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

  Widget _buildFavouriteList(BuildContext context) {
    List<Widget> favouriteRowList;
    if ((_currentActiveVerse.join(".") == "0.0.0") || (this.bibles?.bible1?.data == null)) {
      favouriteRowList = [_emptyRow(context)];
    } else {
      List favouriteList = this.config.favouriteVerse;
      favouriteRowList =
          favouriteList.map((i) => _buildFavouriteRow(context, i)).toList();
    }
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][6]),
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: favouriteRowList,
    );
  }

  Widget _buildFavouriteRow(BuildContext context, List hxBcvList) {
    var parser = BibleParser(this.abbreviations);
    String hxReference = parser.bcvToVerseReference(hxBcvList);
    return ListTile(
      title: Text(
        hxReference,
        //style: _verseFont,
      ),
      onTap: () {
        Navigator.pop(context);
        _scrollToCurrentActiveVerse();
        _newVerseSelected([hxBcvList, "", this.bibles.bible1.module]);
      },

      onLongPress: () {
        _removeFromFavouriteDialog(context, hxBcvList);
      },
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    List<Widget> historyRowList;
    if ((_currentActiveVerse.join(".") == "0.0.0") || (this.bibles?.bible1?.data == null)) {
      historyRowList = [_emptyRow(context)];
    } else {
      List historyList = this.config.historyActiveVerse;
      historyRowList =
          historyList.map((i) => _buildHistoryRow(context, i)).toList();
    }
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][7]),
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: historyRowList,
    );
  }

  Widget _buildHistoryRow(BuildContext context, List hxBcvList) {
    var parser = BibleParser(this.abbreviations);
    String hxReference = parser.bcvToVerseReference(hxBcvList);
    return ListTile(
      title: Text(
        hxReference,
        //style: _verseFont,
      ),
      onTap: () {
        Navigator.pop(context);
        _scrollToCurrentActiveVerse();
        _newVerseSelected([hxBcvList, "", this.bibles.bible1.module]);
      },
      onLongPress: () {
        _addToFavouriteDialog(context, hxBcvList);
      },
    );
  }

  Widget _buildBookList(BuildContext context) {
    List<Widget> bookRowList;
    if ((_currentActiveVerse.join(".") == "0.0.0") || (this.bibles?.bible1?.bookList == null)) {
      bookRowList = [_emptyRow(context)];
    } else {
      List bookList = this.bibles.bible1.bookList;
      bookRowList = bookList.map((i) => _buildBookRow(context, i)).toList();
    }
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][8]),
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: bookRowList,
    );
  }

  Widget _buildBookRow(BuildContext context, int book) {
    var parser = BibleParser(this.abbreviations);
    var abb = parser.standardAbbreviation[book.toString()];
    Widget bookText;
    (book == _currentActiveVerse[0]) ? bookText = Text(abb, style: _highlightStyle) : bookText = Text(abb);

    return ListTile(
      title: bookText,
      onTap: () {
        Navigator.pop(context);
        _scrollToCurrentActiveVerse();
        _newVerseSelected([
          [book, 1, 1],
          "",
          this.bibles.bible1.module
        ]);
      },
      onLongPress: () {
        var selectedBcvList = [book, 1, 1];
        _addToFavouriteDialog(context, selectedBcvList);
      },
    );
  }

  Widget _buildChapterList(BuildContext context) {
    List<Widget> chapterRowList;
    if ((_currentActiveVerse.join(".") == "0.0.0") || (this.bibles?.bible1?.bookList == null)) {
      chapterRowList = [_emptyRow(context)];
    } else {
      List chapterList =
          this.bibles.bible1.getChapterList(_currentActiveVerse[0]);
      chapterRowList =
          chapterList.map((i) => _buildChapterRow(context, i)).toList();
    }
    return ExpansionTile(
      title: Text(this.interfaceApp[this.abbreviations][9]),
      initiallyExpanded: true,
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: chapterRowList,
    );
  }

  Widget _buildChapterRow(BuildContext context, int chapter) {
    Widget chapterText;
    (chapter == _currentActiveVerse[1]) ? chapterText = Text(chapter.toString(), style: _highlightStyle) : chapterText = Text(chapter.toString());
    return ListTile(
      title: chapterText,
      onTap: () {
        Navigator.pop(context);
        _scrollToCurrentActiveVerse();
        _newVerseSelected([
          [_currentActiveVerse[0], chapter, 1],
          "",
          this.bibles.bible1.module
        ]);
      },
      onLongPress: () {
        List<int> selectedBcvList = [_currentActiveVerse[0], chapter, 1];
        _addToFavouriteDialog(context, selectedBcvList);
      },
    );
  }

  Widget _emptyRow(BuildContext context) {
    return ListTile(
      title: Text("... loading ..."),
      onTap: () {
        Navigator.pop(context);
      },
    );
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
        padding: const EdgeInsets.all(16.0),
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
      var verseData = _data[i];

      if ((this.config.hebrewBibles.contains(verseData[2])) && (verseData[0][0] < 40)) {
        verseFont = _verseFontHebrew;
        verseActiveFont = _activeVerseFontHebrew;
        verseDirection = TextDirection.rtl;
      } else if (this.config.greekBibles.contains(verseData[2])) {
        verseFont = _verseFontGreek;
        verseActiveFont = _activeVerseFontGreek;
      }
      (_parallelBibles) ? verseNo = "[${verseData[0][2]}] [${verseData[2]}] " : verseNo = "[${verseData[0][2]}] ";

      verseContent = verseData[1];
      List<TextSpan> wordSpans;

      // check if it is an active verse or not
      if (verseData[0][2] == _currentActiveVerse[2]) {
        if (this.config.interlinearBibles.contains(verseData[2])) {
          List<TextSpan> interlinearSpans = InterlinearHelper(this.config.verseTextStyle).getInterlinearSpan(verseContent, verseData[0][0], true);
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
            _tapActiveVerse(context, _data[i][0]);
          },
          onLongPress: () {
            _longPressedActiveVerse(context, _data[i]);
          },
        );
      } else {
        if (this.config.interlinearBibles.contains(verseData[2])) {
          List<TextSpan> interlinearSpans = InterlinearHelper(this.config.verseTextStyle).getInterlinearSpan(verseContent, verseData[0]);
          wordSpans = <TextSpan>[TextSpan(text: verseNo, style: _activeVerseNoFont), ...interlinearSpans];
        } else {
          wordSpans = <TextSpan>[TextSpan(text: verseNo, style: _activeVerseNoFont), TextSpan(text: verseContent, style: verseFont)];
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
            (verseData[2] == this.bibles.bible1.module) ? _scrollIndex = i : _scrollIndex = (i - 1);
            setActiveVerse(context, _data[i][0]);
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
            title: Text(this.interfaceDialog[this.abbreviations][0]),
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
    int bookNo = verseData[0][0];
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
            title: Text(this.interfaceDialog[this.abbreviations][0]),
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
        addToFavourite(context, verseData[0]);
        break;
      case DialogAction.crossReference:
        _loadXRef(context, verseData[0]);
        break;
      case DialogAction.compareAll:
        _loadCompare(context, verseData[0]);
        break;
      case DialogAction.interlinearOHGB:
        _loadInterlinearView(context, verseData[0], "OHGB");
        break;
      case DialogAction.morphologyOHGB:
        _loadMorphologyView(context, verseData[0], "OHGB");
        break;
      case DialogAction.interlinearLXX1:
        _loadInterlinearView(context, verseData[0], "LXX1");
        break;
      case DialogAction.morphologyLXX1:
        _loadMorphologyView(context, verseData[0], "LXX1");
        break;
      case DialogAction.interlinearLXX2:
        _loadInterlinearView(context, verseData[0], "LXX2");
        break;
      case DialogAction.morphologyLXX2:
        _loadMorphologyView(context, verseData[0], "LXX2");
        break;
      case DialogAction.interlinearABP:
        _loadInterlinearView(context, verseData[0], "ABP");
        break;
      default:
    }
  }

  // reference: https://github.com/flutter/flutter/blob/master/examples/flutter_gallery/lib/demo/material/dialog_demo.dart
  void _addToFavouriteDialog(BuildContext context, List bcvList) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle = theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
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
    final TextStyle dialogTextStyle = theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
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
        addToFavourite(context, bcvList);
      } else if (value == DialogAction.removeFavourite) {
        setState(() {
          removeFromFavourite(bcvList);
        });
      }
    });
  }

  Future getMorphology(List bcvList, String module) async {
    final Database db = await SqliteHelper(this.config).initMorphologyDb();
    var statement = "SELECT * FROM $module WHERE Book = ? AND Chapter = ? AND Verse = ?";
    List<Map> morphology = await db.rawQuery(statement, bcvList);
    db.close();
    return morphology;
  }

  Future getTools(List bcvList, String module) async {
    List bcvList2 = [...bcvList, bcvList[2]];
    final Database db = await SqliteHelper(this.config).initToolsDb();
    var statement = "SELECT Tool, Entry, Topic FROM $module WHERE Book = ? AND Chapter = ? AND Verse <= ? AND toVerse >= ?";
    List<Map> tools = await db.rawQuery(statement, bcvList2);
    db.close();

    List<String> entries = <String>[];
    List<Map> toolsFiltered = <Map>[];
    for (var tool in tools) {
      String entry = tool["Entry"];
      if (!(entries.contains(entry))) {
        entries.add(entry);
        toolsFiltered.add(tool);
      }
    }

    return toolsFiltered;
  }

}
