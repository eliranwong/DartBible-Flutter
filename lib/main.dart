// Copyright 2019 Eliran Wong. All rights reserved.

//import 'dart:as
import 'dart:io';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:indexed_list_view/indexed_list_view.dart';
import 'package:swipedetector/swipedetector.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:provider/provider.dart';
import 'config.dart';
import 'Bibles.dart';
import 'BibleSearchDelegate.dart';
import 'TopicSearchDelegate.dart';
import 'PeopleSearchDelegate.dart';
import 'LocationSearchDelegate.dart';
import 'BibleSettings.dart';
import 'BibleParser.dart';
import 'Morphology.dart';
import 'MorphologyTablet.dart';
import 'Helpers.dart';
import 'Tools.dart';
import 'MyDrawer.dart';
import 'TabletDrawer.dart';
import 'ToolsTablet.dart';

void main() => runApp(MyApp());

/*void main() {
  runApp(
    ChangeNotifierProvider(
      builder: (context) => UpdateCenter(),
      child: MyApp(),
    ),
  );
}

class UpdateCenter with ChangeNotifier {
  Config config;
}*/

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

  String query = '';
  bool _parallelBibles = false;
  List<dynamic> _data = [
    [
      [0, 0, 0],
      "... loading ...",
      ""
    ]
  ];
  List<int> _currentActiveVerse = [0, 0, 0];

  bool _drawer = false;
  bool _typing = false;
  bool _display = false;
  Bibles bibles;
  var scrollController;
  int _scrollIndex = 0;
  int _activeIndex = 0;
  Config config;
  var _verseNoFont, _verseFont, _verseFontHebrew, _verseFontGreek;
  var _activeVerseNoFont,
      _activeVerseFont,
      _activeVerseFontHebrew,
      _activeVerseFontGreek;
  var _interlinearStyle, _interlinearStyleDim;
  Color _appBarColor, _bottomAppBarColor, _backgroundColor;
  final _highlightStyle = TextStyle(
    fontWeight: FontWeight.bold,
    //fontStyle: FontStyle.italic,
    decoration: TextDecoration.underline,
    color: Colors.blue,
  );

  String abbreviations = "ENG";
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
      "Timelines"
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
      "時序圖"
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
      "时序图"
    ],
  };

  Map interfaceBottom = {
    "ENG": [
      "Instant Interlinear",
      "Bible Topics",
      "Bible Promises",
      "Harmonies & Parallels",
      "Bible People",
      "Bible Locations",
      "Share",
      "Bible Audio",
      "User Manual",
      "Add / Remove Secondary View",
    ],
    "TC": [
      "即時原文逐字翻譯",
      "聖經主題",
      "聖經應許",
      "對觀經文",
      "聖經人物",
      "聖經地點",
      "分享",
      "聖經語音",
      "使用手册",
      "加增／刪除輔助視窗",
    ],
    "SC": [
      "即时原文逐字翻译",
      "圣经主题",
      "圣经应许",
      "对观经文",
      "圣经人物",
      "圣经地点",
      "分享",
      "圣经语音",
      "使用手册",
      "加增／删除辅助视窗",
    ],
  };

  Map interfaceMessage = {
    "ENG": [
      "is selected.\n'Tap' it again to open your 'Favourite Action'.\nOr 'press' & 'hold' it for more actions.",
      "Loading cross-references ...",
      "Loading bibles for comparison ...",
      "Added to Favourites!"
    ],
    "TC": [
      "被點選。\n再'按'此節可啟動'設定'中的'常用功能'。\n或'長按'可選擇更多功能。",
      "啟動相關經文 ...",
      "啟動版本比較 ...",
      "已收藏"
    ],
    "SC": [
      "被点选。\n再'按'此节可启动'设定'中的'常用功能'。\n或'长按'可选择更多功能。",
      "启动相关经文 ...",
      "啟動版本比较 ...",
      "已收藏"
    ],
  };

  Map interfaceDialog = {
    "ENG": [
      "Select an action:",
      "Share",
      "Copy",
      "Add to Copied Text",
      "Add to Favourites",
      "Cross-references",
      "Version Comparison",
      "Interlinear",
      "Morphology"
    ],
    "TC": [
      "功能選項：",
      "分享",
      "複製",
      "增補複製內容",
      "收藏",
      "相關經文",
      "比較版本",
      "原文逐字翻譯",
      "原文形態學"
    ],
    "SC": [
      "功能选项：",
      "分享",
      "拷贝",
      "增补拷贝内容",
      "收藏",
      "相关经文",
      "比较版本",
      "原文逐字翻译",
      "原文形态学"
    ],
  };

  // Variables to work with TTS
  FlutterTts flutterTts;
  dynamic languages;
  dynamic voices;
  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  Icon _ttsIcon = Icon(Icons.volume_up);
  bool _speakOneVerse = false;

  // Variables to work with previous search interface
  final _pageSize = 20;
  List _displayData = [];
  List _rawData = [];
  Map interfaceBibleSearch = {
    "ENG": [
      "is not properly formatted for search. Please correct and try again.",
      "Clear",
      "More ...",
      "Search"
    ],
    "TC": ["組成的格式不正確，請更正然後再嘗試", "清空", "更多 …", "搜索"],
    "SC": ["组成的格式不正确，请更正然后再尝试", "清空", "更多 …", "搜索"],
  };

  @override
  initState() {
    super.initState();
    initTts();
    this.config = Config();
    _setup();
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  initTts() {
    flutterTts = FlutterTts();

    /*
    if (Platform.isAndroid) {
      flutterTts.ttsInitHandler(() {
        _getLanguages();
        _getVoices();
      });
    } else if (Platform.isIOS) {
      _getLanguages();
      _getVoices();
    }
    */

    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        //print("Complete");
        ttsState = TtsState.stopped;
        _ttsIcon = Icon(Icons.volume_up);
      });
      if (_speakOneVerse) {
        _speakOneVerse = false;
      } else {
        _scrollIndex += 1;
        _readVerse();
      }
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }

  /*
  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    //print(languages);
    if (languages != null) setState(() => languages);
  }

  Future _getVoices() async {
    voices = await flutterTts.getVoices;
    //print(voices);
    if (voices != null) setState(() => voices);
  }
  */

  Future _readVerse() async {
    if ((isStopped) && (_scrollIndex < _data.length)) {
      List item = _data[_scrollIndex];
      List bcvList = item.first;
      String module = item.last;
      String verse;
      if (((Platform.isAndroid) &&
              (this.config.hebrewBibles.contains(module)) &&
              (bcvList.first < 40)) ||
          ((this.config.ttsGreek != "modern") &&
              (this.config.hebrewBibles.contains(module)) &&
              (bcvList.first >= 40))) {
        verse = TtsHelper()
            .workaroundHebrew(this.bibles.tBible.openSingleVerse(bcvList));
      } else if (this.config.interlinearBibles.contains(module)) {
        verse = "$verse ｜";
        verse = verse.replaceAll(RegExp("｜＠.*? ｜"), "");
      } else {
        verse = item[1];
      }
      if (this.config.chineseBibles.contains(module)) {
        await flutterTts.setLanguage(this.config.ttsChinese);
        //zh-CN, yue-HK (Android), zh-HK (iOS)
      } else if ((item.first.first < 40) &&
          (this.config.hebrewBibles.contains(module))) {
        (Platform.isAndroid)
            ? await flutterTts.setLanguage("el-GR")
            : await flutterTts.setLanguage("he-IL");
      } else if (this.config.greekBibles.contains(module)) {
        if ((this.config.ttsGreek != "modern") &&
            (this.config.hebrewBibles.contains(module))) {
          await flutterTts.setLanguage(this.config.ttsEnglish);
        } else {
          verse = TtsHelper().removeGreekAccents(verse);
          await flutterTts.setLanguage("el-GR");
        }
      } else {
        await flutterTts.setLanguage(this.config.ttsEnglish);
        //en-GB, en-US
      }
      this.scrollController.jumpToIndex(_scrollIndex);
      _speak(verse);
    } else {
      _stop();
    }
  }

  Future _speak(String message) async {
    if (message != null) {
      if ((message.isNotEmpty) && (isAllBiblesReady())) {
        var result = await flutterTts.speak(message);
        if (result == 1)
          setState(() {
            ttsState = TtsState.playing;
            _ttsIcon = Icon(Icons.stop);
          });
      }
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1)
      setState(() {
        _speakOneVerse = false;
        ttsState = TtsState.stopped;
        _ttsIcon = Icon(Icons.volume_up);
        _scrollIndex = _activeIndex;
      });
  }

  Future _setup() async {
    await this.config.setDefault();
    await flutterTts.setSpeechRate(this.config.speechRate);

    this.abbreviations = this.config.abbreviations;
    this.bibles = Bibles(this.abbreviations);

    // pre-load bible1 data
    this.bibles.bible1 = Bible(this.config.bible1, this.abbreviations);
    await this.bibles.bible1.loadData();

    // pre-load bible headings
    await _loadHeadings();

    // pre-load bible2 data
    this.bibles.bible2 = Bible(this.config.bible2, this.abbreviations);
    this.bibles.bible2.loadData();

    // pre-load interlinear bible
    this.bibles.iBible = Bible("OHGBi", this.abbreviations);
    this.bibles.iBible.loadData();

    // pre-load transliteration bible
    this.bibles.tBible = Bible("OHGBt", this.abbreviations);
    this.bibles.tBible.loadData();

    setState(() {
      _currentActiveVerse =
          List<int>.from(this.config.historyActiveVerse.first);
      _data = this.bibles.bible1.openSingleChapter(_currentActiveVerse);
      _scrollIndex = getScrollIndex();
      _activeIndex = _scrollIndex;
    });
  }

  bool isAllBiblesReady() {
    return ((this.bibles?.bible1?.data != null) &&
        (this.bibles?.bible2?.data != null) &&
        (this.bibles?.iBible?.data != null) &&
        (this.bibles?.tBible?.data != null));
  }

  void _nonPlusMessage(String feature) {
    _stopRunningActions();
    String message =
        "'$feature' ${this.config.plusMessage[this.abbreviations].first}";
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: this.config.plusMessage[this.abbreviations].last,
        onPressed: () {
          _launchPlusPage();
        },
      ),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future _launchPlusPage() async {
    _stopRunningActions();
    String url = this.config.plusURL;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future _loadHeadings() async {
    Map headingModules = {
      "ENG": "HeadingKJV",
      "TC": "HeadingCUV",
      "SC": "HeadingCUVs",
    };
    String headingModule = headingModules[this.abbreviations];
    if ((this.bibles?.headings?.data == null) ||
        (headingModule != this.bibles?.headings?.module)) {
      this.bibles.headings = Bible(headingModule, this.abbreviations);
      await this.bibles.headings.loadData();
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
    if ((bcvList.isNotEmpty) &&
        (newBcvList.join(".") != _currentActiveVerse.join("."))) {
      _stopRunningActions();
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
    String verseReference =
        BibleParser(this.abbreviations).bcvToVerseReference(bcvList);
    String message =
        "'$verseReference' ${this.interfaceMessage[this.abbreviations].first}";
    _stopRunningActions();
    final snackBar = SnackBar(content: Text(message));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future showInterlinear(BuildContext context, List bcvList) async {
    if (this.config.plus) {
      if (this.bibles?.iBible?.data != null) {
        String verseReference =
            BibleParser(this.abbreviations).bcvToVerseReference(bcvList);

        var verseDirection = TextDirection.ltr;
        bool isHebrew = (bcvList.first < 40);
        if (isHebrew) verseDirection = TextDirection.rtl;

        String verseText = this.bibles.iBible.openSingleVerse(bcvList);
        List<TextSpan> textContent =
            InterlinearHelper(this.config.verseTextStyle).getInterlinearSpan(
                verseText, bcvList.first)
              ..insert(0, TextSpan(text: " "))
              ..insert(
                  0, TextSpan(text: "$verseReference", style: _highlightStyle))
              ..insert(0, TextSpan(text: " "));

        final selected = await showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
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
                    onLongPress: () async {
                      if (isPlaying) _stop();
                      (isHebrew)
                          ? await flutterTts.setLanguage("he-IL")
                          : await flutterTts.setLanguage("el-GR");
                      if ((isHebrew) && (Platform.isAndroid)) {
                        verseText = TtsHelper().workaroundHebrew(
                            this.bibles.tBible.openSingleVerse(bcvList));
                        //verseText = verseText.replaceAll("ʾ", "");
                        await flutterTts.setLanguage("el-GR");
                      } else {
                        verseText = "$verseText ｜";
                        verseText = verseText.replaceAll(RegExp("｜＠.*? ｜"), "");
                      }
                      _speakOneVerse = true;
                      _speak(verseText);
                    },
                  ),
                ),
              );
            });
        if (selected != null)
          (this.config.bigScreen)
              ? _loadOriginalWord(context, selected)
              : _loadInterlinearView(context, selected);
      }
    } else {
      _nonPlusMessage(this.interfaceBottom[this.abbreviations][0]);
    }
  }

  void _stopRunningActions() {
    _scaffoldKey.currentState.removeCurrentSnackBar();
    if (isPlaying) _stop();
  }

  Future _newVerseSelected(List selected) async {
    await _loadHeadings();
    setState(() {
      _scrollToCurrentActiveVerse();
    });

    List selectedBcvList = List<int>.from(selected.first);
    String selectedBible = selected.last;
    if (selectedBible.isEmpty) selectedBible = this.bibles.bible1.module;

    if ((selectedBible != this.bibles.bible1.module) &&
        (selectedBible == this.bibles.bible2.module)) _swapBibles();

    if (selectedBcvList != null && selectedBcvList.isNotEmpty) {
      bool sameVerse =
          (selectedBcvList.join(".") == _currentActiveVerse.join("."));
      if ((!sameVerse) ||
          ((sameVerse) && (selectedBible != this.bibles.bible1.module))) {
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
          _activeIndex = _scrollIndex;
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
      List verseList =
          this.bibles.bible1.getVerseList(currentBook, previousChapter);
      if (verseList.isNotEmpty)
        _newVerseSelected([
          [currentBook, previousChapter, verseList.first],
          "",
          this.bibles.bible1.module
        ]);
    } else {
      List bookList = this.bibles.bible1.bookList;
      int previousBook = currentBook - 1;
      if (bookList.contains(previousBook)) {
        chapterList = this.bibles.bible1.getChapterList(previousBook);
        if (chapterList.isNotEmpty) {
          previousChapter = chapterList[chapterList.length - 1];
          List verseList =
              this.bibles.bible1.getVerseList(previousBook, previousChapter);
          if (verseList.isNotEmpty)
            _newVerseSelected([
              [previousBook, previousChapter, verseList.first],
              "",
              this.bibles.bible1.module
            ]);
        }
      }
    }
  }

  goNextChapter() {
    int currentBook = _currentActiveVerse.first;
    int nextChapter = _currentActiveVerse[1] + 1;
    List chapterList = this.bibles.bible1.getChapterList(currentBook);

    if (chapterList.contains(nextChapter)) {
      List verseList =
          this.bibles.bible1.getVerseList(currentBook, nextChapter);
      if (verseList.isNotEmpty)
        _newVerseSelected([
          [currentBook, nextChapter, verseList.first],
          "",
          this.bibles.bible1.module
        ]);
    } else {
      List bookList = this.bibles.bible1.bookList;
      int nextBook = currentBook + 1;
      if (bookList.contains(nextBook)) {
        chapterList = this.bibles.bible1.getChapterList(nextBook);
        if (chapterList.isNotEmpty) {
          nextChapter = chapterList.first;
          List verseList =
              this.bibles.bible1.getVerseList(nextBook, nextChapter);
          if (verseList.isNotEmpty)
            _newVerseSelected([
              [nextBook, nextChapter, verseList.first],
              "",
              this.bibles.bible1.module
            ]);
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
    _stopRunningActions();
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
      // Big Screen Mode
      this.config.bigScreen = newBibleSettings.bigScreen;
      this.config.save("bigScreen", newBibleSettings.bigScreen);
      if ((_typing) && (!newBibleSettings.bigScreen)) _typing = !_typing;
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
      // TTS English
      this.config.ttsEnglish = newBibleSettings.ttsEnglish;
      this.config.save("ttsEnglish", newBibleSettings.ttsEnglish);
      // TTS Chinese
      this.config.ttsChinese = newBibleSettings.ttsChinese;
      this.config.save("ttsChinese", newBibleSettings.ttsChinese);
      // TTS Greek
      this.config.ttsGreek = newBibleSettings.ttsGreek;
      this.config.save("ttsGreek", newBibleSettings.ttsGreek);
      // TTS speech rate
      this.config.speechRate = newBibleSettings.speechRate;
      this.config.save("speechRate", newBibleSettings.speechRate);
      await flutterTts.setSpeechRate(newBibleSettings.speechRate);
      // update UpdateCenter
      //final state = Provider.of<UpdateCenter>(context);
      //state.config = this.config;
      // Newly selected verse
      var newVerse = [
        [
          newBibleSettings.book,
          newBibleSettings.chapter,
          newBibleSettings.verse,
        ],
        "",
        newBibleSettings.module
      ];
      _newVerseSelected(newVerse);
    }
  }

  void updateBibleAbbreviations(String abbreviations) {
    this.bibles.abbreviations = abbreviations;
    this.bibles.bible1.abbreviations = abbreviations;
    this.bibles.bible2.abbreviations = abbreviations;
  }

  Future _loadXRef(BuildContext context, List bcvList) async {
    _stopRunningActions();
    final snackBar =
        SnackBar(content: Text(this.interfaceMessage[this.abbreviations][1]));
    _scaffoldKey.currentState.showSnackBar(snackBar);

    var xRefData = await this.bibles.crossReference(bcvList);
    _scaffoldKey.currentState.removeCurrentSnackBar();

    if (this.config.bigScreen) {
      setState(() {
        if (!_display) _display = true;
        _rawData = [];
        _displayData = xRefData;
      });
    } else {
      final List selected = await showSearch(
          context: context,
          delegate: BibleSearchDelegate(context, this.bibles.bible1,
              this.interfaceDialog, this.config, xRefData));
      if (selected != null) {
        this._displayData = selected.first;
        _newVerseSelected(this._displayData[selected.last]);
      }
    }
  }

  Future _loadCompare(BuildContext context, List bcvList) async {
    _stopRunningActions();
    final snackBar =
        SnackBar(content: Text(this.interfaceMessage[this.abbreviations][2]));
    _scaffoldKey.currentState.showSnackBar(snackBar);

    var compareData =
        await this.bibles.compareBibles(this.config.compareBibleList, bcvList);
    _scaffoldKey.currentState.removeCurrentSnackBar();

    if (this.config.bigScreen) {
      setState(() {
        if (!_display) _display = true;
        _rawData = [];
        _displayData = compareData;
      });
    } else {
      final List selected = await showSearch(
          context: context,
          delegate: BibleSearchDelegate(
            context,
            this.bibles.bible1,
            this.interfaceDialog,
            this.config,
            compareData,
          ));
      if (selected != null) {
        this._displayData = selected.first;
        _newVerseSelected(this._displayData[selected.last]);
      }
    }
  }

  Future _loadOriginalWord(BuildContext context, List bcvList,
      [String module]) async {
    if (isAllBiblesReady()) {
      _stopRunningActions();
      String table = module ?? "OHGB";
      final List<Map> morphology =
          await SqliteHelper(this.config).getMorphology(bcvList, table);
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                OriginalWord(morphology, table, this.config, this.bibles)),
      );
      if (selected != null) _newVerseSelected(selected);
    }
  }

  Future _loadInterlinearView(BuildContext context, List bcvList,
      [String module]) async {
    if (isAllBiblesReady()) {
      _stopRunningActions();
      String table = module ?? "OHGB";
      final List<Map> morphology =
          await SqliteHelper(this.config).getMorphology(bcvList, table);
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => InterlinearView(
                morphology, true, table, this.config, this.bibles)),
      );
      if (selected != null) _newVerseSelected(selected);
    }
  }

  Future _loadMorphologyView(BuildContext context, List bcvList,
      [String module]) async {
    if (isAllBiblesReady()) {
      _stopRunningActions();
      String table = module ?? "OHGB";
      final List<Map> morphology =
          await SqliteHelper(this.config).getMorphology(bcvList, table);
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MorphologyView(
                morphology, true, table, this.config, this.bibles)),
      );
      if (selected != null) _newVerseSelected(selected);
    }
  }

  Future _loadTools(BuildContext context, Map title, String table, List menu,
      Icon icon) async {
    if (this.bibles?.bible1?.data != null) {
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => (this.config.bigScreen)
                ? Tool(title, table, menu, this.config, this.bibles.bible1, icon, this.interfaceDialog)
                : ToolMenu(title, table, menu, this.config, this.bibles.bible1, icon, this.interfaceDialog)
        ),
      );
      if (selected != null) {
        if (selected.last == "open") {
          _newVerseSelected(selected.first);
        } else {
          setState(() {
            if (!_display) _display = true;
            _rawData = [];
            _displayData = selected.first;
          });
        }
      }
    }
  }

  Future _loadLocation(BuildContext context, List bcvList,
      [String module]) async {
    if (this.bibles?.bible1?.data != null) {
      _stopRunningActions();
      String table = module ?? "EXLBL";
      final List<Map> tools =
          await SqliteHelper(this.config).getTools(bcvList, table);
      if (this.config.bigScreen) {
        final List<Map> tools2 = await SqliteHelper(this.config).getBookTools(bcvList, table);

        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LocationTablet(tools, tools2, this.config)
          ),
        );
        if ((selected != null) && (selected.isNotEmpty)) _loadLocationVerses(context, selected.first);
      } else {
        final List selected = await showSearch(
          context: context,
          delegate: LocationSearchDelegate(context, tools, this.config),
        );
        if ((selected != null) && (selected.isNotEmpty)) _loadLocationVerses(context, selected.first);
      }
    }
  }

  Future _loadLocationVerses(BuildContext context, String locationID) async {
    _stopRunningActions();
    final Database db = await SqliteHelper(this.config).initToolsDb();
    var statement =
        "SELECT Book, Chapter, Verse FROM EXLBL WHERE LocationID = ? ORDER BY Number";
    List<Map> tools = await db.rawQuery(statement, [locationID]);
    db.close();
    List<List> bcvLists =
        tools.map((i) => [i["Book"], i["Chapter"], i["Verse"]]).toList();
    if (this.config.bigScreen) {
      setState(() {
        if (!_display) _display = true;
        _loadRawData(bcvLists);
      });
    } else {
      final List selected = await showSearch(
          context: context,
          delegate: BibleSearchDelegate(context, this.bibles.bible1,
              this.interfaceDialog, this.config, [], bcvLists));
      if (selected != null) {
        this._displayData = selected.first;
        _newVerseSelected(this._displayData[selected.last]);
      }
    }
  }

  Future _loadPeople(BuildContext context, List bcvList,
      [String module]) async {
    if (this.bibles?.bible1?.data != null) {
      _stopRunningActions();
      String table = module ?? "PEOPLE";
      final List<Map> tools =
          await SqliteHelper(this.config).getTools(bcvList, table);

      if (this.config.bigScreen) {
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PeopleTablet(tools, this.config)
          ),
        );
        if (selected != null) _loadPeopleVerses(context, selected);
      } else {
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
  }

  Future _loadPeopleVerses(BuildContext context, int personID) async {
    _stopRunningActions();
    final Database db = await SqliteHelper(this.config).initToolsDb();
    var statement =
        "SELECT Book, Chapter, Verse FROM PEOPLE WHERE PersonID = ?";
    List<Map> tools = await db.rawQuery(statement, [personID]);
    db.close();
    List<List> bcvLists =
        tools.map((i) => [i["Book"], i["Chapter"], i["Verse"]]).toList();
    if (this.config.bigScreen) {
      setState(() {
        if (!_display) _display = true;
        _loadRawData(bcvLists);
      });
    } else {
      final List selected = await showSearch(
          context: context,
          delegate: BibleSearchDelegate(context, this.bibles.bible1,
              this.interfaceDialog, this.config, [], bcvLists));
      if (selected != null) {
        this._displayData = selected.first;
        _newVerseSelected(this._displayData[selected.last]);
      }
    }
  }

  Future _loadRelationship(
      BuildContext context, int personID, String name) async {
    _stopRunningActions();
    final Database db = await SqliteHelper(this.config).initToolsDb();
    var statement =
        "SELECT PersonID, Name, Sex, Relationship FROM PEOPLERELATIONSHIP WHERE RelatedPersonID = ? AND Relationship != '[Reference]' ORDER BY RelationshipOrder";
    List<Map> tools = await db.rawQuery(statement, [personID]);
    db.close();
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Relationship(name, tools, this.config,
              this.bibles.bible1, this.interfaceDialog, _currentActiveVerse)),
    );
    if (selected != null) {
      _loadPeopleVerses(context, selected);
    }
  }

  Future _loadTopics(BuildContext context, List bcvList,
      [String module]) async {
    if (this.bibles?.bible1?.data != null) {
      _stopRunningActions();
      String table = module ?? "EXLBT";
      final List<Map> tools = await SqliteHelper(this.config).getTopics(bcvList, table);

      if (this.config.bigScreen) {
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TopicTablet(tools, this.config, this.bibles)),
        );
        if ((selected != null) && (selected.isNotEmpty)) {
          (selected[1] == "search")
              ? _loadTopicVerses(context, selected.first)
              : _newVerseSelected(selected);
        }
      } else {
        final List selected = await showSearch(
          context: context,
          delegate: TopicSearchDelegate(context, tools, this.config),
        );
        if ((selected != null) && (selected.isNotEmpty)) {
          String entry = selected.first;
          (selected[1] == "open")
              ? _loadTopicView(context, entry)
              : _loadTopicVerses(context, entry);
        }
      }
    }
  }

  Future _loadTopicView(BuildContext context, String entry) async {
    _stopRunningActions();
    List topic = await SqliteHelper(this.config).getTopic(entry);
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => TopicView(this.config, topic, this.bibles)),
    );
    if (selected != null) _newVerseSelected(selected);
  }

  Future _loadTopicVerses(BuildContext context, String entry) async {
    _stopRunningActions();
    final Database db = await SqliteHelper(this.config).initToolsDb();
    var statement =
        "SELECT Book, Chapter, Verse, toVerse FROM EXLBT WHERE Entry = ?";
    List<Map> tools = await db.rawQuery(statement, [entry]);
    db.close();
    List<String> bcvStrings = tools
        .map((i) {
          if (i["Verse"] == i["toVerse"]) {
            return "${i["Book"]}.${i["Chapter"]}.${i["Verse"]}";
          } else {
            return "${i["Book"]}.${i["Chapter"]}.${i["Verse"]}.${i["Chapter"]}.${i["toVerse"]}";
          }
        })
        .toSet()
        .toList();
    List<List> bcvLists = bcvStrings
        .map((i) => i.split(".").map((i) => int.parse(i)).toList())
        .toList();
    if (this.config.bigScreen) {
      setState(() {
        if (!_display) _display = true;
        _loadRawData(bcvLists);
      });
    } else {
      final List selected = await showSearch(
          context: context,
          delegate: BibleSearchDelegate(context, this.bibles.bible1,
              this.interfaceDialog, this.config, [], bcvLists));
      if (selected != null) {
        this._displayData = selected.first;
        _newVerseSelected(this._displayData[selected.last]);
      }
    }
  }

  bool _toggleParallelBibles() {
    _stopRunningActions();
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
    _stopRunningActions();
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

  Future _reLoadBibles() async {
    await _loadHeadings();
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
    _verseNoFont =
        TextStyle(fontSize: (this.config.fontSize - 3), color: blueAccent);
    _verseFont = TextStyle(fontSize: this.config.fontSize, color: black);
    _verseFontHebrew = TextStyle(
        fontFamily: "Ezra SIL",
        fontSize: (this.config.fontSize + 4),
        color: black);
    _verseFontGreek =
        TextStyle(fontSize: (this.config.fontSize + 2), color: black);
    _activeVerseNoFont = TextStyle(
        fontSize: (this.config.fontSize - 3),
        color: blue,
        fontWeight: FontWeight.bold);
    _activeVerseFont = TextStyle(fontSize: this.config.fontSize, color: indigo);
    _activeVerseFontHebrew = TextStyle(
        fontFamily: "Ezra SIL",
        fontSize: (this.config.fontSize + 4),
        color: indigo);
    _activeVerseFontGreek =
        TextStyle(fontSize: (this.config.fontSize + 2), color: indigo);
    _interlinearStyle =
        TextStyle(fontSize: (this.config.fontSize - 3), color: deepOrange);
    _interlinearStyleDim = TextStyle(
        fontSize: (this.config.fontSize - 3),
        color: grey,
        fontStyle: FontStyle.italic);

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
        this.interfaceApp[this.abbreviations].first =
            BibleParser(this.abbreviations)
                .bcvToChapterReference(_currentActiveVerse);
      } else {
        this.interfaceApp[this.abbreviations].first =
            "${BibleParser(this.abbreviations).bcvToChapterReference(_currentActiveVerse)} [${this.bibles.bible1.module}]";
      }
    }
  }

  Widget _buildDrawer() {
    if ((this.bibles?.bible1?.data == null) ||
        (this.bibles?.headings?.data == null)) {
      return Drawer(
        child: Text(
          "\n\n... loading ...\n\n... try again later ...",
          style: TextStyle(fontSize: this.config.fontSize),
        ),
      );
    }
    return MyDrawer(this.config, this.bibles.bible1, this.bibles.headings,
        _currentActiveVerse, (List data) {
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
    _updateTextStyle();
    _updateAppBarTitle();

    return Scaffold(
      key: _scaffoldKey,
      drawer: (this.config.bigScreen) ? null : _buildDrawer(),
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
      appBar: _buildAppBar(context),
      body: Container(
        color: _backgroundColor,
        child: _buildLayout(context),
      ),
      bottomNavigationBar: _buildBottomAppBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _appBarColor,
        onPressed: () {
          setState(() {
            _parallelBibles = _toggleParallelBibles();
            _scrollIndex = getScrollIndex();
            _activeIndex = _scrollIndex;
          });
        },
        tooltip: this.interfaceApp[this.abbreviations][5],
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    if (this.config.bigScreen) {
      return Row(
        children: <Widget>[
          (_drawer) ? _buildTabletDrawer() : Container(),
          (_drawer) ? _buildDivider() : Container(),
          _wrap(
            OrientationBuilder(
              builder: (context, orientation) {
                List<Widget> layoutWidgets = _buildLayoutWidgets(context);
                return (orientation == Orientation.portrait)
                    ? Column(children: layoutWidgets)
                    : Row(children: layoutWidgets);
              },
            ),
            1,
          ),
        ],
      );
    }
    return _buildBibleChapter(context);
  }

  Widget _buildTabletDrawer() {
    if ((this.bibles?.bible1?.data == null) ||
        (this.bibles?.headings?.data == null)) {
      return Container();
    }
    return SizedBox(
      width: 250,
      child: TabletDrawer(this.config, this.bibles.bible1, this.bibles.headings,
          (List data) {
        Map actions = {
          "open": _newVerseSelected,
          "addFavourite": addToFavourite,
          "removeFavourite": removeFromFavourite,
        };
        actions[data.first](data.last);
      }),
    );
  }

  Widget _wrap(Widget widget, int flex) {
    return Expanded(
      flex: flex,
      child: widget,
    );
  }

  List<Widget> _buildLayoutWidgets(BuildContext context) {
    return <Widget>[
      _wrap(_buildBibleChapter(context), 2),
      (_display) ? _buildDivider() : Container(),
      (_display) ? _wrap(_buildDisplayVerses(context), 2) : Container(),
    ];
  }

  Widget _buildDivider() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: this.config.myColors["grey"])),
    );
  }

  Widget _buildBibleChapter(BuildContext context) {
    return SwipeDetector(
      child: _buildVerses(context),
      onSwipeLeft: () {
        goNextChapter();
      },
      onSwipeRight: () {
        goPreviousChapter();
      },
    );
  }

  Widget _buildSearchBox() {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        decoration:
            InputDecoration(border: InputBorder.none, hintText: interfaceApp[this.abbreviations][2]),
        onSubmitted: (String value) {
          if (value.isNotEmpty) {
            setState(() {
              query = value;
              if (!_display) _display = true;
              _rawData = [];
              _displayData = _fetch(query);
            });
          }
        },
        //onChanged: ,
        //onTap: ,
        //onEditingComplete: ,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    //original color: Theme.of(context).appBarTheme.color
    return AppBar(
      backgroundColor: _appBarColor,
      title: (_typing)
          ? _buildSearchBox()
          : Text(this.interfaceApp[this.abbreviations].first),
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            //tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            tooltip: this.interfaceApp[this.abbreviations][1],
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (this.config.bigScreen) {
                setState(() {
                  _drawer = !_drawer;
                });
              } else {
                _scaffoldKey.currentState.openDrawer();
              }
            },
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          tooltip: this.interfaceApp[this.abbreviations][2],
          icon: Icon((_typing) ? Icons.clear : Icons.search),
          onPressed: () async {
            if (this.config.bigScreen) {
              setState(() {
                _typing = !_typing;
              });
            } else {
              await _launchBibleSearch(context);
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

  Future _launchBibleSearch(BuildContext context) async {
    _stopRunningActions();
    final List selected = await showSearch(
      context: context,
      delegate: BibleSearchDelegate(
        context,
        this.bibles.bible1,
        this.interfaceDialog,
        this.config,
        this._displayData,
      ),
    );
    if (selected != null) {
      this._displayData = selected.first;
      _newVerseSelected(this._displayData[selected.last]);
    }
  }

  Widget _buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      // Container placed here is necessary for controlling the height of the ListView.
      child: Container(
        padding: EdgeInsets.only(right: 84.0),
        height: 48,
        color: _bottomAppBarColor,
        child: ListView(scrollDirection: Axis.horizontal, children: <Widget>[
          IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][0],
            icon: const Icon(Icons.layers),
            onPressed: () {
              showInterlinear(context, _currentActiveVerse);
            },
          ),
          IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][7],
            icon: _ttsIcon,
            onPressed: () {
              (this.config.plus)
                  ? _readVerse()
                  : _nonPlusMessage(
                  this.interfaceBottom[this.abbreviations][7]);
            },
          ),
          IconButton(
            tooltip: this.interfaceDialog[this.abbreviations][5],
            icon: const Icon(Icons.link),
            onPressed: () {
              _loadXRef(context, _currentActiveVerse);
            },
          ),
          IconButton(
            tooltip: this.interfaceDialog[this.abbreviations][6],
            icon: const Icon(Icons.compare_arrows),
            onPressed: () {
              _loadCompare(context, _currentActiveVerse);
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
            tooltip: this.interfaceBottom[this.abbreviations][1],
            icon: const Icon(Icons.title),
            onPressed: () {
              _loadTopics(context, _currentActiveVerse);
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
              _loadTools(
                  context,
                  title,
                  "PROMISES",
                  menu,
                  Icon(
                    Icons.games,
                    color: this.config.myColors["black"],
                  ));
            },
          ),
          IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][3],
            icon: const Icon(Icons.compare),
            onPressed: () {
              (this.config.plus)
                  ? _launchHarmonies(context)
                  : _nonPlusMessage(
                      this.interfaceBottom[this.abbreviations][3]);
            },
          ),
          IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][6],
            icon: const Icon(Icons.share),
            onPressed: () {
              String chapterReference = BibleParser(this.abbreviations)
                  .bcvToChapterReference(_data.first.first);
              String verses = _data
                  .map((i) => "${i.first.last.toString()} ${i[1]}")
                  .toList()
                  .join("\n");
              Share.share("$chapterReference\n$verses");
            },
          ),
          (!this.config.bigScreen)
              ? Container()
              : IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][9],
            icon: const Icon(Icons.add_to_home_screen),
            onPressed: () {
              setState(() {
                _display = !_display;
              });
            },
          ),
          IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][8],
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _launchUserManual();
            },
          ),
        ]),
      ),
    );
  }

  void _launchHarmonies(BuildContext context) {
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
    _loadTools(
        context,
        title,
        "PARALLEL",
        menu,
        Icon(
          Icons.compare,
          color: this.config.myColors["black"],
        ));
  }

  Future _launchUserManual() async {
    String url = 'https://www.uniquebible.app/mobile';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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
      (_parallelBibles)
          ? verseNo = "[${bcvList[2]}] [$module] "
          : verseNo = "[${bcvList[2]}] ";

      verseContent = verseData[1];
      List<TextSpan> wordSpans;

      // check if it is an active verse or not
      //if (i == _scrollIndex) {
      if (bcvList[2] == _currentActiveVerse[2]) {
        if (this.config.interlinearBibles.contains(module)) {
          List<TextSpan> interlinearSpans =
              InterlinearHelper(this.config.verseTextStyle)
                  .getInterlinearSpan(verseContent, book, true);
          wordSpans = <TextSpan>[
            TextSpan(text: verseNo, style: _activeVerseNoFont),
            ...interlinearSpans
          ];
        } else {
          wordSpans = <TextSpan>[
            TextSpan(text: verseNo, style: _activeVerseNoFont),
            TextSpan(text: verseContent, style: verseActiveFont)
          ];
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
          List<TextSpan> interlinearSpans =
              InterlinearHelper(this.config.verseTextStyle)
                  .getInterlinearSpan(verseContent, book);
          wordSpans = <TextSpan>[
            TextSpan(text: verseNo, style: _verseNoFont),
            ...interlinearSpans
          ];
        } else {
          wordSpans = <TextSpan>[
            TextSpan(text: verseNo, style: _verseNoFont),
            TextSpan(text: verseContent, style: verseFont)
          ];
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
            (module == this.bibles.bible1.module)
                ? _scrollIndex = i
                : _scrollIndex = (i - 1);
            _activeIndex = _scrollIndex;
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
    _stopRunningActions();
    if (this.config.favouriteAction != -1) {
      List favouriteActions = [
        addToFavourite,
        _loadXRef,
        _loadCompare,
        (this.config.bigScreen) ? _loadOriginalWord : _loadInterlinearView,
        (this.config.bigScreen) ? _loadOriginalWord : _loadMorphologyView,
      ];
      favouriteActions[this.config.favouriteAction](context, bcvList);
    }
  }

  // reference: https://api.flutter.dev/flutter/material/SimpleDialog-class.html
  Future<void> _longPressedVerse(BuildContext context, List verseData) async {
    _stopRunningActions();
    var copiedText = await Clipboard.getData('text/plain');
    switch (await showDialog<DialogAction>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(this.interfaceDialog[this.abbreviations].first),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, DialogAction.share);
                },
                child: Text(this.interfaceDialog[this.abbreviations][1]),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, DialogAction.copy);
                },
                child: Text(this.interfaceDialog[this.abbreviations][2]),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, DialogAction.addCopy);
                },
                child: Text(this.interfaceDialog[this.abbreviations][3]),
              ),
            ],
          );
        })) {
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

  Future<void> _longPressedActiveVerse(
      BuildContext context, List verseData) async {
    _stopRunningActions();
    var copiedText = await Clipboard.getData('text/plain');
    List<Widget> dialogOptions = [
      SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, DialogAction.share);
        },
        child: Text(this.interfaceDialog[this.abbreviations][1]),
      ),
      SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, DialogAction.copy);
        },
        child: Text(this.interfaceDialog[this.abbreviations][2]),
      ),
      SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, DialogAction.addCopy);
        },
        child: Text(this.interfaceDialog[this.abbreviations][3]),
      ),
      SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, DialogAction.addFavourite);
        },
        child: Text(this.interfaceDialog[this.abbreviations][4]),
      ),
      SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, DialogAction.crossReference);
        },
        child: Text(this.interfaceDialog[this.abbreviations][5]),
      ),
      SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, DialogAction.compareAll);
        },
        child: Text(this.interfaceDialog[this.abbreviations][6]),
      ),
      SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, DialogAction.interlinearOHGB);
        },
        child: Text("OHGB ${this.interfaceDialog[this.abbreviations][7]}"),
      ),
      SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, DialogAction.morphologyOHGB);
        },
        child: Text("OHGB ${this.interfaceDialog[this.abbreviations][8]}"),
      ),
      SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, DialogAction.interlinearABP);
        },
        child: Text("ABP ${this.interfaceDialog[this.abbreviations][7]}"),
      ),
    ];
    int bookNo = verseData.first.first;
    if ((bookNo < 40) || (bookNo > 66)) {
      List<Widget> lxxDialogOptions = [
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, DialogAction.interlinearLXX1);
          },
          child: Text("LXX1 ${this.interfaceDialog[this.abbreviations][7]}"),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, DialogAction.morphologyLXX1);
          },
          child: Text("LXX1 ${this.interfaceDialog[this.abbreviations][8]}"),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, DialogAction.interlinearLXX2);
          },
          child: Text("LXX2 ${this.interfaceDialog[this.abbreviations][7]}"),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, DialogAction.morphologyLXX2);
          },
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
        })) {
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
        (this.config.bigScreen)
            ? _loadOriginalWord(context, verseData.first, "OHGB")
            : _loadInterlinearView(context, verseData.first, "OHGB");
        break;
      case DialogAction.morphologyOHGB:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, verseData.first, "OHGB")
            : _loadMorphologyView(context, verseData.first, "OHGB");
        break;
      case DialogAction.interlinearLXX1:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, verseData.first, "LXX1")
            : _loadInterlinearView(context, verseData.first, "LXX1");
        break;
      case DialogAction.morphologyLXX1:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, verseData.first, "LXX1")
            : _loadMorphologyView(context, verseData.first, "LXX1");
        break;
      case DialogAction.interlinearLXX2:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, verseData.first, "LXX2")
            : _loadInterlinearView(context, verseData.first, "LXX2");
        break;
      case DialogAction.morphologyLXX2:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, verseData.first, "LXX2")
            : _loadMorphologyView(context, verseData.first, "LXX2");
        break;
      case DialogAction.interlinearABP:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, verseData.first, "ABP")
            : _loadInterlinearView(context, verseData.first, "ABP");
        break;
      default:
    }
  }

  // functions for display of verses

  // The option of lazy loading is achieved with "_loadData" & "_loadMoreData"
  Future _loadRawData(List rawData) async {
    _rawData = rawData;
    _displayData = (_rawData.length <= _pageSize)
        ? this.bibles.bible1.openMultipleVerses(_rawData)
        : this.bibles.bible1.openMultipleVerses(_rawData.sublist(0, _pageSize));
  }

  Future _loadMoreData(BuildContext context, int i) async {
    int start = i;
    int end = i + _pageSize;
    List newBcvList = (end > _rawData.length)
        ? _rawData.sublist(start)
        : _rawData.sublist(start, end);
    setState(() {
      if (!_display) _display = true;
      _displayData = [
        ..._displayData,
        ...this.bibles.bible1.openMultipleVerses(newBcvList)
      ];
    });
  }

  // This is the function which does the search.
  List _fetch(String query) {
    List<dynamic> fetchResults = [];

    try {
      // search in a book or books, e.g. John:::Jesus Christ or Matthew, John:::Jesus Christ
      if (query.contains(":::")) {
        List queryList = query.split(":::");
        if (queryList.length >= 2) {
          List bookReferenceList;
          if (queryList[0].isNotEmpty) {
            String bookString = "";
            var bookList = queryList[0].split(",");
            for (var book in bookList) {
              bookString += "${book.trim()} 0; ";
            }
            bookReferenceList = BibleParser(this.abbreviations)
                .extractAllReferences(bookString);
          } else {
            bookReferenceList = [_currentActiveVerse];
          }
          if (bookReferenceList.isNotEmpty) {
            String queryText = queryList.sublist(1).join(":::");
            if (queryText.isNotEmpty) {
              return this
                  .bibles
                  .bible1
                  .searchBooks(queryText, bookReferenceList);
            }
          }
        }
      }

      // check if the query contains verse references or not.
      var verseReferenceList =
          BibleParser(this.abbreviations).extractAllReferences(query);
      (verseReferenceList.isEmpty)
          ? fetchResults = this.bibles.bible1.search(query)
          : fetchResults =
              this.bibles.bible1.openMultipleVerses(verseReferenceList);
    } catch (e) {
      fetchResults = [
        [[], "['$query' ${interfaceBibleSearch[this.abbreviations][0]}", ""]
      ];
    }

    return fetchResults;
  }

  Widget _buildDisplayVerses(BuildContext context) {
    int count =
        ((_rawData.isNotEmpty) && (_rawData.length > _displayData.length))
            ? (_displayData.length + 1)
            : _displayData.length;
    return Container(
      color: Colors.blueGrey[this.config.backgroundColor],
      child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: count,
          itemBuilder: (context, i) {
            return (i == _displayData.length)
                ? _buildMoreDisplayVerseRow(context, i)
                : _buildDisplayVerseRow(context, i);
          }),
    );
  }

  Widget _buildMoreDisplayVerseRow(BuildContext context, int i) {
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

  Widget _buildDisplayVerseRow(BuildContext context, int i) {
    var verseData = _displayData[i];

    return ListTile(
      title: _buildVerseText(context, verseData),
      onTap: () {
        _newVerseSelected(verseData);
      },
      onLongPress: () {
        _longPressedVerse(context, _displayData[i]);
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

    if ((this.config.hebrewBibles.contains(verseModule)) &&
        (verseData[0][0] < 40)) {
      verseFont = _verseFontHebrew;
      activeVerseFont = _activeVerseFontHebrew;
      verseDirection = TextDirection.rtl;
    } else if (this.config.greekBibles.contains(verseModule)) {
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
      if (query.contains(":::"))
        searchEntry = query.split(":::").sublist(1).join(":::");
      if (this.config.interlinearBibles.contains(verseModule)) {
        List<TextSpan> interlinearSpan =
            InterlinearHelper(this.config.verseTextStyle)
                .getInterlinearSpan(verseContent, verseData[0][0]);
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
}
