// Copyright 2019 Eliran Wong. All rights reserved.

//import 'dart:as
import 'dart:io';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:share/share.dart';
import 'package:indexed_list_view/indexed_list_view.dart';
import 'package:swipedetector/swipedetector.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'config.dart';
import 'Bibles.dart';
import 'BibleSearchDelegate.dart';
import 'TopicSearchDelegate.dart';
import 'PeopleSearchDelegate.dart';
import 'LocationSearchDelegate.dart';
import 'VerseSelector.dart';
import 'ChapterSelector.dart';
import 'BibleSettings.dart';
import 'BibleParser.dart';
import 'Morphology.dart';
import 'MorphologyTablet.dart';
import 'Helpers.dart';
import 'Tools.dart';
import 'MyDrawer.dart';
import 'TabletDrawer.dart';
import 'ToolsTablet.dart';
import 'package:path_provider/path_provider.dart';

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

  Database noteDB;
  String noteDBPath;
  List _noteList = [];

  String query = '';
  bool _parallelBibles = false;
  List<dynamic> _data = [
    [
      [0, 0, 0],
      "... loading ...",
      ""
    ]
  ];
  List<dynamic> _activeVerseData;
  List<int> _currentActiveVerse = [0, 0, 0];
  List<Map> _morphology = [];


  bool _typing = false;
  bool _display = false;
  bool _selection = false;
  List _selectionIndexes = [];
  Bibles bibles;
  var scrollController;
  TabController _tabController;
  WebViewController _webViewController;
  int _tabIndex = 0;
  int _scrollIndex = 0;
  int _activeIndex = 0;
  Config config;
  var _verseNoFont, _verseFont, _verseFontHebrew, _verseFontGreek;
  var _activeVerseNoFont,
      _activeVerseFont,
      _activeVerseFontHebrew,
      _activeVerseFontGreek;
  var _interlinearStyle, _interlinearStyleDim;
  Color _appBarColor, _bottomAppBarColor, _backgroundColor, _floatingButtonColor;
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
      "Timelines",
      "Big Screen Layout",
      "Small Screen Layout",
      "Notes",
      "Contact",
      "New Note",
      "Edit Note",
      "Big Screen",
      "Small Screen",
      "Show ",
      "Hide ",
      "Menu",
      "Open '",
      "' Here",
      "New Verse",
      "Open a Chapter HERE",
      "Back up ",
      "Restore ",
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
      "大屏幕設定",
      "小屏幕設定",
      "筆記",
      "聯絡",
      "新增筆記",
      "修改筆記",
      "大屏幕設定",
      "小屏幕設定",
      "顯示",
      "隱藏",
      "菜單",
      "在這裡打開【",
      "】",
      "新章節",
      "在這裡打開經文",
      "備份",
      "還原",
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
      "大屏幕设定",
      "小屏幕设定",
      "笔记",
      "联络",
      "新增笔记",
      "修改笔记",
      "大屏幕设定",
      "小屏幕设定",
      "显示",
      "隐藏",
      "菜单",
      "在这里打开【",
      "】",
      "新章节",
      "在这里打开经文",
      "备份",
      "还原",
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
      "Workspace",
      "Back",
      "Multiple Selection",
      "Select / Clear All",
      "Text copied to clipboard.",
      "You have to select at least a verse for this action.",
      "Marvel.Bible",
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
      "工作間",
      "回去",
      "選擇經文",
      "選擇／清除所有",
      "文字已複製",
      "你必須選擇至少一節經文才能啟動此功能。",
      "Marvel.Bible",
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
      "工作间",
      "回去",
      "选择经文",
      "选择／清除所有",
      "文字已拷贝",
      "你必须选择至少一节经文才能启动此功能。",
      "Marvel.Bible",
    ],
  };

  Map interfaceMessage = {
    "ENG": [
      "is selected.\n'Tap' it again to open your 'Favourite Action'.\nOr 'press' & 'hold' it for more actions.",
      "Loading cross-references ...",
      "Loading bibles for comparison ...",
      "Added to Favourites!",
      "Migrating notes ...",
      "Notes were migrated!",
    ],
    "TC": [
      "被點選。\n再'按'此節可啟動'設定'中的'常用功能'。\n或'長按'可選擇更多功能。",
      "啟動相關經文 ...",
      "啟動版本比較 ...",
      "已收藏",
      "正在轉移筆記 ...",
      "筆記已經轉移到最新版本！",
    ],
    "SC": [
      "被点选。\n再'按'此节可启动'设定'中的'常用功能'。\n或'长按'可选择更多功能。",
      "启动相关经文 ...",
      "啟動版本比较 ...",
      "已收藏",
      "正在转移笔记 ...",
      "笔记已经转移到最新版本！",
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
      "Morphology",
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
      "原文形態學",
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
      "原文形态学",
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
  bool _toolOpened = false;

  // Variables to work with previous search interface
  final _pageSize = 20;
  List _displayData = [["", "[...]", ""]];
  List _displayChapter = [["", "[Open a Chapter HERE]", ""]];
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
    // Using hybrid composition for webview v1.0.7+; read https://pub.dev/packages/webview_flutter
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    this.config = Config();
    _setup();
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
    noteDB.close();
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
      } else if (!_toolOpened) {
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
      bool isHebrew = ((this.config.hebrewBibles.contains(module)) && (bcvList.first < 40));
      if ((Platform.isAndroid) && isHebrew) {
        verse = TtsHelper().workaroundHebrew(this.bibles.tBible.openSingleVerse(bcvList));
      } else if (this.config.interlinearBibles.contains(module)) {
        verse = "${item[1]} ｜";
        verse = verse.replaceAll(RegExp("｜＠.*? ｜"), "");
      } else {
        verse = item[1];
      }
      if (this.config.chineseBibles.contains(module)) {
        await flutterTts.setLanguage(this.config.ttsChinese);
        //zh-CN, yue-HK (Android), zh-HK (iOS)
      } else if (isHebrew) {
        (Platform.isAndroid)
            ? await flutterTts.setLanguage("el-GR")
            : await flutterTts.setLanguage("he-IL");
      } else if (this.config.greekBibles.contains(module)) {
        verse = TtsHelper().removeGreekAccents(verse);
        await flutterTts.setLanguage("el-GR");
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

  void _startSelection() {
    _stopRunningActions();
    setState(() {
      _selection = true;
      _selectionIndexes = List<int>.generate(_data.length, (i) => i);
    });
  }

  void _stopSelection() {
    setState(() {
      _selection = false;
    });
  }

  void _allSelection() {
    setState(() {
      if (_selectionIndexes.isNotEmpty) {
        _selectionIndexes = [];
      } else {
        _selectionIndexes = List<int>.generate(_data.length, (i) => i);
      }
    });
  }

  void _updateSelection(int i, bool value) {
    setState(() {
      if (value) {
        _selectionIndexes.add(i);
        _selectionIndexes.sort();
      } else {
        int index = _selectionIndexes.indexOf(i);
        _selectionIndexes.removeAt(index);
      }
    });
  }

  void _runSelection([bool share = false]) {
    if (_selectionIndexes.isNotEmpty) {
      String chapterReference = BibleParser(this.abbreviations)
          .bcvToChapterReference(_data.first.first);
      List copyList = _selectionIndexes
          .map((i) => (_parallelBibles)
              ? "[${_data[i].first.last}] [${_data[i].last}] ${_data[i][1]}"
              : "[${_data[i].first.last}] ${_data[i][1]}")
          .toList();
      String content = "$chapterReference\n${copyList.join("\n")}";
      if (share) {
        Share.share(content);
      } else {
        Clipboard.setData(ClipboardData(text: content));
        _scaffoldKey.currentState.removeCurrentSnackBar();
        String message = this.interfaceBottom[this.abbreviations][13];
        final snackBar = SnackBar(
          content: Text(message),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
      _stopSelection();
    } else {
      _scaffoldKey.currentState.removeCurrentSnackBar();
      String message = this.interfaceBottom[this.abbreviations][14];
      final snackBar = SnackBar(
        content: Text(message),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  Future _migrateOldNotes() async {
    // assign the path of user notes database in latest versions
    final userDirectory = (Platform.isAndroid) ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
    noteDBPath = join(userDirectory.path, "Notes.sqlite");
    //print("New path: ${noteDBPath}");

    // The path of user notes database in old versions
    final databasesPath = await getDatabasesPath();
    String oldNoteDBPath = join(databasesPath, "Notes.sqlite");
    //print("Old path: ${oldNoteDBPath}");

    // in tested iOS devices, oldNoteDBPath == noteDBPath
    // in tested Android devices, oldNoteDBPath != noteDBPath

    // Check if an older version of notes exists
    File oldNoteFile = File(oldNoteDBPath);
    if ((await oldNoteFile.exists()) && (oldNoteDBPath != noteDBPath)) {
      File newNoteFile = File(noteDBPath);
      if (await newNoteFile.exists()) {
        String alternateOldFilePath = "${noteDBPath}_old";
        File alternateOldFile = File(alternateOldFilePath);
        if (!await alternateOldFile.exists()) await _backupNotes(oldNoteDBPath, alternateOldFilePath);
      } else {
        await _backupNotes(oldNoteDBPath, noteDBPath);
      }
    }
    // backward compatibility to older version of user notes if permission is not granted by Android users.
    if (Platform.isAndroid) {
      PermissionStatus permissionResult = await SimplePermissions.requestPermission(Permission. WriteExternalStorage);
      if (permissionResult != PermissionStatus.authorized) {
        noteDBPath = oldNoteDBPath;
        _noPermissionMessage();
      }
    }
  }

  void _noPermissionMessage() {
    _stopRunningActions();
    Map noPermissionMessage = {
      "ENG": "You can back up your notes by granting permission.",
      "TC": "通過授予權限您可以備份您的個人筆記。",
      "SC": "通过授予权限您可以备份您的个人笔记。",
    };
    String message = noPermissionMessage[this.abbreviations];
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: this.config.plusMessage[this.abbreviations].last,
        onPressed: () {
          _launchNotesBackupPage();
        },
      ),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future _launchNotesBackupPage() async {
    _stopRunningActions();
    String url = "https://www.uniquebible.app/mobile/user-notes/back-up";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future _openNoteDB() async {
    noteDB = await openDatabase(noteDBPath, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              "CREATE TABLE Notes (id INTEGER PRIMARY KEY, book INTEGER, chapter INTEGER, verse INTEGER, content TEXT)");
        });
  }

  Future _setup() async {
    // migrate notes written with older versions
    await _migrateOldNotes();
    // open the database
    await _openNoteDB();

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
    ((this.config.bigScreen) && (this.config.instantAction == 1))
        ? await this.bibles.bible2.loadData()
        : this.bibles.bible2.loadData();

    // pre-load interlinear bible
    this.bibles.iBible = Bible(this.config.iBible, this.abbreviations);
    ((this.config.bigScreen) && (this.config.instantAction == 1))
        ? await this.bibles.iBible.loadData()
        : this.bibles.iBible.loadData();

    // pre-load transliteration bible
    this.bibles.tBible = Bible("OHGBt", this.abbreviations);
    ((this.config.bigScreen) && (this.config.instantAction == 1))
        ? await this.bibles.tBible.loadData()
        : this.bibles.tBible.loadData();

    _currentActiveVerse = List<int>.from(this.config.historyActiveVerse.first);
    _noteList = await noteDB.rawQuery(
        "SELECT verse FROM Notes WHERE book = ? AND chapter = ?",
        _currentActiveVerse.sublist(0, 2));
    _noteList = _noteList.map((i) => i["verse"]).toList();

    setState(() {
      _data = this.bibles.bible1.openSingleChapter(_currentActiveVerse);
      _scrollIndex = getScrollIndex();
      _activeIndex = _scrollIndex;
      if ((this.config.bigScreen) && (this.config.instantAction == 1)) {
        if (!_display) _display = true;
        showInterlinear(_currentActiveVerse);
      }
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
        instantActions[this.config.instantAction](bcvList, context);
      }
    }
  }

  showTip(List bcvList, [BuildContext context]) {
    String verseReference =
        BibleParser(this.abbreviations).bcvToVerseReference(bcvList);
    String message =
        "'$verseReference' ${this.interfaceMessage[this.abbreviations].first}";
    _stopRunningActions();
    final snackBar = SnackBar(content: Text(message));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future _getMorphology(List bcvList, [String module]) async {
    String table = module ?? "OHGB";
    _morphology = await SqliteHelper(this.config).getMorphology(bcvList, table);
    setState(() {
      if (!_display) _display = true;
      _changeWorkspace(2);
    });
  }

  Widget _interlinearTile(BuildContext context, List bcvList) {
    String verseReference =
    BibleParser(this.abbreviations).bcvToVerseReference(bcvList);

    var verseDirection = TextDirection.ltr;
    bool isHebrew = ((bcvList.isNotEmpty) && (bcvList.first < 40) && (this.bibles.iBible.module == "OHGBi"));
    if (isHebrew) verseDirection = TextDirection.rtl;

    String verseText = this.bibles.iBible.openSingleVerse(bcvList);

    List<TextSpan> textContent = this.getInterlinearSpan(context, verseText, bcvList);
    if (!this.config.bigScreen) textContent.insert(0, TextSpan(text: verseReference, style: _highlightStyle));

    return ListTile(
      title: RichText(
        text: TextSpan(
          //style: DefaultTextStyle.of(context).style,
          children: textContent,
        ),
        textDirection: verseDirection,
      ),
      //subtitle: Text(verseReference, style: _highlightStyle),
      onTap: (this.config.bigScreen) ? null : () => Navigator.pop(context, bcvList),
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
          verseText = TtsHelper().removeGreekAccents(verseText);
        }
        _speakOneVerse = true;
        _speak(verseText);
      },
    );
  }

  Future _selectInterlinear(BuildContext context) async {
    _stopRunningActions();
    final BibleSettingsParser newBibleSettings = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => VerseSelector(
            this.bibles.bible1,
            _currentActiveVerse,
            this.interfaceDialog,
            this.config,
            false,
          )),
    );
    if (newBibleSettings != null) {
      var newVerse = [
          newBibleSettings.book,
          newBibleSettings.chapter,
          newBibleSettings.verse,
        ];
      showInterlinear(newVerse);
    }
  }

  Future showInterlinear(List bcvList, [BuildContext context]) async {
    if (this.config.plus) {
      if (this.bibles?.iBible?.data != null) {
        bool isLXX1 = ((this.bibles.iBible.module != "OHGBi") && ((bcvList.first > 66) || (bcvList.first < 40)));
        _stopRunningActions();
        if (this.config.bigScreen) {
          await _getMorphology(bcvList, (isLXX1) ? "LXX1" : "OHGB");
        } else {
          final selected = await showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  color: config.myColors["background"],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: _interlinearTile(context, bcvList),
                  ),
                );
              });
          if (selected != null) _loadInterlinearView(context, selected, (isLXX1) ? "LXX1" : "OHGB");
        }
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
    if (selected.first.isNotEmpty) {
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
          _noteList = await noteDB.rawQuery(
              "SELECT verse FROM Notes WHERE book = ? AND chapter = ?",
              _currentActiveVerse.sublist(0, 2));
          _noteList = _noteList.map((i) => i["verse"]).toList();
          if (selectedBible != this.bibles.bible1.module) {
            this.bibles.bible1 = Bible(selectedBible, this.abbreviations);
            await this.bibles.bible1.loadData();
            this.config.bible1 = selectedBible;
            this.config.save("bible1", selectedBible);
          }
          setState(() {
            _selection = false;
            _currentActiveVerse = selectedBcvList;
            updateHistoryActiveVerse();
            (_parallelBibles) ? _parallelBibles = false : _parallelBibles = true;
            _parallelBibles = _toggleParallelBibles();
            _scrollIndex = getScrollIndex();
            _activeIndex = _scrollIndex;
            if ((this.config.bigScreen) && (this.config.instantAction == 1)) {
              if (!_display) _display = true;
              showInterlinear(_currentActiveVerse);
            }
          });
        }
      }
    }
  }

  Future reloadSecondaryBible(String module) async {
    // reload bible2 in memory
    this.bibles.bible2 = Bible(module, this.abbreviations);
    await this.bibles.bible2.loadData();
    // save config
    this.config.bible2 = module;
    this.config.save("bible2", module);
    // reload parallel bibles
    if (_parallelBibles) _reLoadBibles();
  }

  Future reloadInterlinearBible(String module) async {
    // reload iBible in memory
    this.bibles.iBible = Bible(module, this.abbreviations);
    await this.bibles.iBible.loadData();
    // save config
    this.config.iBible = module;
    this.config.save("iBible", module);
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

  Future _openVerseSelector(BuildContext context) async {
    _stopRunningActions();
    final BibleSettingsParser newBibleSettings = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => VerseSelector(
                this.bibles.bible1,
                _currentActiveVerse,
                this.interfaceDialog,
                this.config,
              )),
    );
    if (newBibleSettings != null) {
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

  Future _openChapterSelector(BuildContext context) async {
    _stopRunningActions();
    final BibleSettingsParser newBibleSettings = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ChapterSelector(
            this.bibles.bible1,
            _currentActiveVerse,
            this.interfaceDialog,
            this.config,
          )),
    );
    if (newBibleSettings != null) {
      List newChapter = [
          newBibleSettings.book,
          newBibleSettings.chapter,
          newBibleSettings.verse,
        ];
      String newModule = newBibleSettings.module;
      _openHere(newChapter, newModule);
    }
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
      // default marvel bible
      this.config.marvelBible = newBibleSettings.marvelBible;
      this.config.save("marvelBible", newBibleSettings.marvelBible);
      // secondary bible
      if (newBibleSettings.module2 != this.bibles.bible2.module)
        await reloadSecondaryBible(newBibleSettings.module2);
      // instant interlinear bible
      if (newBibleSettings.iBible != this.bibles.iBible.module)
        await reloadInterlinearBible(newBibleSettings.iBible);
      // Big Screen Mode
      //this.config.bigScreen = newBibleSettings.bigScreen;
      //this.config.save("bigScreen", newBibleSettings.bigScreen);
      //if ((_typing) && (!newBibleSettings.bigScreen)) _typing = !_typing;
      // Font size
      this.config.fontSize = newBibleSettings.fontSize;
      this.config.save("fontSize", newBibleSettings.fontSize);
      // Abbreviations
      this.abbreviations = newBibleSettings.abbreviations;
      this.config.abbreviations = newBibleSettings.abbreviations;
      updateBibleAbbreviations(newBibleSettings.abbreviations);
      this.config.save("abbreviations", newBibleSettings.abbreviations);
      // Show heading verse no
      this.config.showHeadingVerseNo = newBibleSettings.showHeadingVerseNo;
      this.config.save("showHeadingVerseNo", newBibleSettings.showHeadingVerseNo);
      // Always open Marvel Bible with external browser
      this.config.alwaysOpenMarvelBibleExternally = newBibleSettings.alwaysOpenMarvelBibleExternally;
      this.config.save("alwaysOpenMarvelBibleExternally", newBibleSettings.alwaysOpenMarvelBibleExternally);
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
        _changeWorkspace(1);
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
        _changeWorkspace(1);
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
      [String module, int wordIndex]) async {
    if (isAllBiblesReady()) {
      _toolOpened = true;
      _stopRunningActions();
      String table = module ?? "OHGB";
      final List<Map> morphology =
          await SqliteHelper(this.config).getMorphology(bcvList, table);
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                OriginalWord(morphology, table, this.config, this.bibles, this.flutterTts, wordIndex)),
      );
      if (selected != null) _newVerseSelected(selected);
      _toolOpened = false;
    }
  }

  Future _loadInterlinearView(BuildContext context, List bcvList,
      [String module]) async {
    if (isAllBiblesReady()) {
      _toolOpened = true;
      _stopRunningActions();
      String table = module ?? "OHGB";
      final List<Map> morphology =
          await SqliteHelper(this.config).getMorphology(bcvList, table);
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => InterlinearView(
                morphology, true, table, this.config, this.bibles, this.flutterTts)),
      );
      if (selected != null) _newVerseSelected(selected);
      _toolOpened = false;
    }
  }

  Future _loadMorphologyView(BuildContext context, List bcvList,
      [String module]) async {
    if (isAllBiblesReady()) {
      _toolOpened = true;
      _stopRunningActions();
      String table = module ?? "OHGB";
      final List<Map> morphology =
          await SqliteHelper(this.config).getMorphology(bcvList, table);
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MorphologyView(
                morphology, true, table, this.config, this.bibles, this.flutterTts)),
      );
      if (selected != null) _newVerseSelected(selected);
      _toolOpened = false;
    }
  }

  Future _launchNotePad(BuildContext context, List bcvList) async {
    if (isAllBiblesReady()) {
      _stopRunningActions();

      if (bcvList.length > 3) bcvList = bcvList.sublist(0, 3);

      List<Map> savedContent = await noteDB.rawQuery(
          "SELECT * FROM Notes WHERE book = ? AND chapter = ? AND verse = ?",
          bcvList);
      String content =
          (savedContent.isEmpty) ? "" : savedContent.first["content"];

      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NotePad(this.config, this.bibles, bcvList, noteDB, content),
        ),
      );
      if (selected != null) _newVerseSelected(selected);
      _noteList = await noteDB.rawQuery(
          "SELECT verse FROM Notes WHERE book = ? AND chapter = ?",
          _currentActiveVerse.sublist(0, 2));
      setState(() {
        _noteList = _noteList.map((i) => i["verse"]).toList();
      });
    }
  }

  void _launchPromises(BuildContext context) {
    Map title = {
      "ENG": this.interfaceBottom["ENG"][2],
      "TC": this.interfaceBottom["TC"][2],
      "SC": this.interfaceBottom["SC"][2],
    };
    List menuENG = [
      "Precious Bible Promises I",
      "Precious Bible Promises II",
      "Precious Bible Promises III",
      "Precious Bible Promises IV",
      "Take Words with You",
      "Index",
      "When you ...",
    ];
    List menuZh = [
      "當你 ……",
      "当你 ……",
    ];
    List menu = (this.config.abbreviations == "ENG") ? menuENG : [...menuENG, ...menuZh];
    _loadTools(
        context,
        title,
        "PROMISES",
        menu,
        Icon(
          Icons.games,
          color: this.config.myColors["black"],
        ));
  }

  void _launchHarmonies(BuildContext context) {
    Map title = {
      "ENG": this.interfaceBottom["ENG"][3],
      "TC": this.interfaceBottom["TC"][3],
      "SC": this.interfaceBottom["SC"][3],
    };
    List menuENG = [
      "History of Israel I",
      "History of Israel II",
      "Gospels I",
      "Gospels II",
      "Book of Moses",
      "Samuel, Kings, Chronicles",
      "Psalms",
      "Gospels - (Mark, Matthew, Luke [ordered] + John) x 54",
      "Gospels - (Mark, Matthew, Luke [unordered]) x 14",
      "Gospels - (Mark & Matthew ONLY) x 11",
      "Gospels - (Mark, Matthew & John ONLY) x 4",
      "Gospels - (Mark & Luke ONLY) x 7",
      "Gospels - (Mathhew & Luke ONLY) x 32",
      "Gospels - (Mark ONLY) x 5",
      "Gospels - (Matthew ONLY) x 30",
      "Gospels - (Luke ONLY) x 39",
      "Gospels - (John ONLY) x 61",
    ];
    List menuZh = [
      "摩西五經",
      "撒母耳記，列王紀，歷代志",
      "詩篇",
      "福音書（可，太，路〔順序〕＋ 約） x 54",
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
    List menu = (this.config.abbreviations == "ENG") ? menuENG : [...menuENG, ...menuZh];
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

  Future _loadTools(BuildContext context, Map title, String table, List menu,
      Icon icon) async {
    if (this.bibles?.bible1?.data != null) {
      _stopRunningActions();
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => (this.config.bigScreen)
                ? Tool(title, table, menu, this.config, this.bibles.bible1,
                    icon, this.interfaceDialog)
                : ToolMenu(title, table, menu, this.config, this.bibles.bible1,
                    icon, this.interfaceDialog)),
      );
      if (selected != null) {
        if (this.config.bigScreen) {
          if (selected.last == "open") {
            _newVerseSelected(selected.first);
          } else {
            setState(() {
              if (!_display) _display = true;
              _rawData = [];
              _displayData = selected.first;
              _changeWorkspace(1);
            });
          }
        } else {
          _rawData = [];
          _displayData = selected.first;
          _newVerseSelected(selected.first[selected.last]);
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
        final List<Map> tools2 =
            await SqliteHelper(this.config).getBookTools(bcvList, table);

        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LocationTablet(tools, tools2, this.config)),
        );
        if ((selected != null) && (selected.isNotEmpty))
          _loadLocationVerses(context, selected.first);
      } else {
        final List selected = await showSearch(
          context: context,
          delegate: LocationSearchDelegate(context, tools, this.config),
        );
        if ((selected != null) && (selected.isNotEmpty))
          _loadLocationVerses(context, selected.first);
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
        _changeWorkspace(1);
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
              builder: (context) => PeopleTablet(tools, this.config)),
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
        _changeWorkspace(1);
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
      final List<Map> tools =
          await SqliteHelper(this.config).getTopics(bcvList, table);

      if (this.config.bigScreen) {
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  TopicTablet(tools, this.config, this.bibles)),
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
        _changeWorkspace(1);
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
      _floatingButtonColor = Colors.blueGrey[this.config.backgroundColor - 300];
      _bottomAppBarColor = Colors.grey[500];
    } else {
      blueAccent = Colors.blue[700];
      indigo = Colors.indigo[700];
      black = Colors.black;
      blue = Colors.blueAccent[700];
      deepOrange = Colors.deepOrange[700];
      grey = Colors.grey[700];
      //_appBarColor = Theme.of(context).appBarTheme.color;
      _appBarColor = Colors.blue[600];
      _floatingButtonColor = Colors.blue[600];
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

    return Theme(
      data: ThemeData(
        unselectedWidgetColor: this.config.myColors["blue"],
      ),
      child: Scaffold(
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
          backgroundColor: _floatingButtonColor,
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
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    if (this.config.bigScreen) {
      return Row(
        children: <Widget>[
          (this.config.showDrawer) ? _buildTabletDrawer() : Container(),
          (this.config.showDrawer) ? _buildDivider() : Container(),
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
      child: TabletDrawer(this.config, this.bibles, (List data) {
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
      (_display) ? _wrap(_buildWorkspace(context), 2) : Container(),
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
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: interfaceApp[this.abbreviations][2]),
        onSubmitted: (String value) {
          if (value.isNotEmpty) {
            setState(() {
              query = value;
              if (!_display) _display = true;
              _rawData = [];
              _displayData = _fetch(query);
              _changeWorkspace(1);
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
    List<PopupMenuEntry<String>> popupMenu = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: "Verse",
        child: ListTile(
          leading: Icon(Icons.directions),
          title: Text(this.interfaceApp[this.abbreviations][24]),
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: "Big",
        child: ListTile(
          leading: Icon((this.config.bigScreen)
              ? Icons.phone_android
              : Icons.laptop),
          title: Text((this.config.bigScreen)
              ? this.interfaceApp[this.abbreviations][18]
              : this.interfaceApp[this.abbreviations][17]),
        ),
      ),
      PopupMenuItem<String>(
        value: "Workspace",
        child: ListTile(
          leading: Icon((_display)
              ? Icons.visibility_off
              : Icons.visibility),
          title: Text(
              "${(_display) ? this.interfaceApp[this.abbreviations][20] : this.interfaceApp[this.abbreviations][19]}${this.interfaceBottom[this.abbreviations][9]}"),
        ),
      ),
      PopupMenuItem<String>(
        value: "Notes",
        child: ListTile(
          leading: Icon((this.config.showNotes)
              ? Icons.visibility_off
              : Icons.visibility),
          title: Text(
              "${(this.config.showNotes) ? this.interfaceApp[this.abbreviations][20] : this.interfaceApp[this.abbreviations][19]}${this.interfaceApp[this.abbreviations][13]}"),
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: "Settings",
        child: ListTile(
          leading: Icon(Icons.settings),
          title: Text(this.interfaceApp[this.abbreviations][4]),
        ),
      ),
      /*
      PopupMenuItem<String>(
        value: "BackupNotes",
        child: ListTile(
          leading: Icon(Icons.file_download),
          title: Text("${this.interfaceApp[this.abbreviations][26]}${this.interfaceApp[this.abbreviations][13]}"),
        ),
      ),
      PopupMenuItem<String>(
        value: "RestoreNotes",
        child: ListTile(
          leading: Icon(Icons.restore_page),
          title: Text("${this.interfaceApp[this.abbreviations][27]}${this.interfaceApp[this.abbreviations][13]}"),
        ),
      ),*/
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: "Manual",
        child: ListTile(
          leading: Icon(Icons.help_outline),
          title: Text(this.interfaceBottom[this.abbreviations][8]),
        ),
      ),
      //const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: "Contact",
        child: ListTile(
          leading: Icon(Icons.alternate_email),
          title: Text(this.interfaceApp[this.abbreviations][14]),
        ),
      ),
    ];
    if (!this.config.bigScreen) popupMenu.removeAt(3);
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
                  this.config.showDrawer = !this.config.showDrawer;
                  this.config.save("showDrawer", this.config.showDrawer);
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
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          tooltip: interfaceApp[this.abbreviations][21],
          padding: EdgeInsets.zero,
          onSelected: (String value) {
            switch (value) {
              case "Big":
                if (this.config.plus) {
                  setState(() {
                    this.config.bigScreen = !this.config.bigScreen;
                    this.config.save("bigScreen", this.config.bigScreen);
                    if ((_typing) && (!this.config.bigScreen))
                      _typing = !_typing;
                  });
                } else {
                  _nonPlusMessage(this.interfaceApp[this.abbreviations][11]);
                }
                break;
              case "Workspace":
                if (this.config.plus) {
                  if (!this.config.bigScreen) {
                    this.config.bigScreen = !this.config.bigScreen;
                    this.config.save("bigScreen", this.config.bigScreen);
                  }
                  setState(() {
                    _display = !_display;
                  });
                } else {
                  _nonPlusMessage(this.interfaceBottom[this.abbreviations][9]);
                }
                break;
              case "Notes":
                if (this.config.plus) {
                  setState(() {
                    this.config.showNotes = !this.config.showNotes;
                    this.config.save("showNotes", this.config.showNotes);
                  });
                } else {
                  _nonPlusMessage(this.interfaceApp[this.abbreviations][13]);
                }
                break;
              case "Verse":
                _openVerseSelector(context);
                break;
              case "Settings":
                _openBibleSettings(context);
                break;
              /*case "BackupNotes":
                _backupNotes();
                break;
              case "RestoreNotes":
                _restoreNotes();
                break;*/
              case "Manual":
                _launchUserManual();
                break;
              case "Contact":
                _launchContact();
                break;
              default:
                break;
            }
          },
          itemBuilder: (BuildContext context) => popupMenu,
        ),
      ],
    );
  }

  Future _backupNotes(String sourceFilePath, String backupPath) async {
    // references:
    // https://api.flutter.dev/flutter/dart-io/File/writeAsBytes.html
    // https://stackoverflow.com/questions/59501445/flutter-how-to-save-a-file-on-ios
    // https://github.com/tekartik/sqflite/issues/264
    // https://stackoverflow.com/questions/50561737/getting-permission-to-the-external-storage-file-provider-plugin
    // https://pub.dev/packages/simple_permissions
    // https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html
    // https://stackoverflow.com/questions/55220612/how-to-save-a-text-file-in-external-storage-in-ios-using-flutter
    // https://www.evertop.pl/en/how-to-write-a-simple-downloading-app-with-flutter/
    // https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html#//apple_ref/doc/uid/TP40009252-SW10

    bool goAhead = true;
    if (Platform.isAndroid) {
      PermissionStatus permissionResult = await SimplePermissions.requestPermission(Permission. WriteExternalStorage);
      goAhead = (permissionResult == PermissionStatus.authorized);
    }

    if (goAhead) {
      // Notify user to wait for the backup
      _stopRunningActions();
      SnackBar snackBar = SnackBar(
        content: Text(this.interfaceMessage[this.abbreviations][4]),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);

      // Close noteDB before backup
      //await noteDB.execute("VACUUM");
      //await noteDB.close();

      // Source File: Note Database file
      File noteDBFile = File(sourceFilePath);
      List noteDBFileContent = await noteDBFile.readAsBytes();

      // Writing Backup file
      File backupFile = File(backupPath);
      await backupFile.writeAsBytes(noteDBFileContent, flush: true);

      // Delete old database
      await deleteDatabase(sourceFilePath);

      // Open noteDB after backup
      //await _openNoteDB();

      // Notify user when backup is done.
      _scaffoldKey.currentState.removeCurrentSnackBar();
      snackBar = SnackBar(
        content: Text(this.interfaceMessage[this.abbreviations][5]),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  /*Future _restoreNotes() async {
    // references:
    // https://api.flutter.dev/flutter/dart-io/File/writeAsBytes.html
    // https://stackoverflow.com/questions/59501445/flutter-how-to-save-a-file-on-ios
    // https://github.com/tekartik/sqflite/issues/264
    // https://stackoverflow.com/questions/50561737/getting-permission-to-the-external-storage-file-provider-plugin
    // https://pub.dev/packages/simple_permissions
    // https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html
    // https://stackoverflow.com/questions/55220612/how-to-save-a-text-file-in-external-storage-in-ios-using-flutter
    // https://www.evertop.pl/en/how-to-write-a-simple-downloading-app-with-flutter/
    // https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html#//apple_ref/doc/uid/TP40009252-SW10

    bool goAhead;
    if (Platform.isAndroid) {
      PermissionStatus permissionResult = await SimplePermissions.requestPermission(Permission. WriteExternalStorage);
      goAhead = (permissionResult == PermissionStatus.authorized);
    } else {
      goAhead = true;
    }

    if (goAhead){
      // code of read or write file in external storage (SD card)

      // Backup file
      // Check first if the backup file exists
      final backupDirectory = (Platform.isAndroid) ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
      String backupPath = join(backupDirectory.path, "Notes.sqlite");
      File backupFile = File(backupPath);
      if (await backupFile.exists()) {
        // Notify user to wait for the restoration
        _scaffoldKey.currentState.removeCurrentSnackBar();
        SnackBar snackBar = SnackBar(
          content: Text(this.interfaceMessage[this.abbreviations][6]),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);

        // Close noteDB before restoration
        await noteDB.close();

        // Read backup file
        List backupFileContent = await backupFile.readAsBytes();

        // Write Database file
        File noteDBFile = File(noteDBPath);
        await noteDBFile.writeAsBytes(backupFileContent, flush: true);

        // Open noteDB after restoration
        await _openNoteDB();

        // Update the list of available notes for the opened chapter
        _noteList = await noteDB.rawQuery(
            "SELECT verse FROM Notes WHERE book = ? AND chapter = ?",
            _currentActiveVerse.sublist(0, 2));
        setState(() {
          _noteList = _noteList.map((i) => i["verse"]).toList();
        });

        // Notify user when restoration is done.
        _scaffoldKey.currentState.removeCurrentSnackBar();
        snackBar = SnackBar(
          content: Text(this.interfaceMessage[this.abbreviations][7]),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      } else {
        _scaffoldKey.currentState.removeCurrentSnackBar();
        final snackBar = SnackBar(
          content: Text(this.interfaceMessage[this.abbreviations][8]),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    } else {
      print("You have to grant permission!");
    }
  }*/

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
          (_selection)
              ? IconButton(
                  tooltip: this.interfaceBottom[this.abbreviations][10],
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _stopSelection(),
                )
              : IconButton(
                  tooltip: this.interfaceBottom[this.abbreviations][0],
                  icon: const Icon(Icons.layers),
                  onPressed: () {
                    showInterlinear(_currentActiveVerse, context);
                  },
                ),
          (_selection)
              ? Container()
              : IconButton(
                  tooltip: this.interfaceBottom[this.abbreviations][7],
                  icon: _ttsIcon,
                  onPressed: () {
                    (this.config.plus)
                        ? _readVerse()
                        : _nonPlusMessage(
                            this.interfaceBottom[this.abbreviations][7]);
                  },
                ),
          (_selection)
              ? Container()
              : IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][2],
            icon: const Icon(Icons.games),
            onPressed: () => _launchPromises(context),
          ),
          (_selection)
              ? Container()
              : IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][3],
            icon: const Icon(Icons.compare),
            onPressed: () => _launchHarmonies(context),
          ),
          (_selection)
              ? Container()
              : IconButton(
                  tooltip: this.interfaceDialog[this.abbreviations][5],
                  icon: const Icon(Icons.link),
                  onPressed: () {
                    _loadXRef(context, _currentActiveVerse);
                  },
                ),
          (_selection)
              ? Container()
              : IconButton(
                  tooltip: this.interfaceDialog[this.abbreviations][6],
                  icon: const Icon(Icons.compare_arrows),
                  onPressed: () {
                    _loadCompare(context, _currentActiveVerse);
                  },
                ),
          (_selection)
              ? Container()
              : IconButton(
                  tooltip: this.interfaceBottom[this.abbreviations][4],
                  icon: const Icon(Icons.people),
                  onPressed: () {
                    _loadPeople(context, _currentActiveVerse);
                  },
                ),
          (_selection)
              ? Container()
              : IconButton(
                  tooltip: this.interfaceBottom[this.abbreviations][5],
                  icon: const Icon(Icons.pin_drop),
                  onPressed: () {
                    _loadLocation(context, _currentActiveVerse);
                  },
                ),
          (_selection)
              ? Container()
              : IconButton(
                  tooltip: this.interfaceBottom[this.abbreviations][1],
                  icon: const Icon(Icons.title),
                  onPressed: () {
                    _loadTopics(context, _currentActiveVerse);
                  },
                ),
          (_selection)
              ? Container()
              : IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][15],
            icon: const Icon(Icons.call_made),
            onPressed: () => _launchMarvelBible(),
          ),
          (_selection)
              ? Container()
              : IconButton(
            tooltip: this.interfaceBottom[this.abbreviations][11],
            icon: const Icon(Icons.check_circle),
            onPressed: () {
              (this.config.plus)
                  ? _startSelection()
                  : _nonPlusMessage(
                  this.interfaceBottom[this.abbreviations][11]);
            },
          ),
          (_selection)
              ? IconButton(
                  tooltip: this.interfaceBottom[this.abbreviations][12],
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _allSelection(),
                )
              : Container(),
          (_selection)
              ? IconButton(
                  tooltip: this.interfaceDialog[this.abbreviations][2],
                  icon: const Icon(Icons.content_copy),
                  onPressed: () => _runSelection(),
                )
              : Container(),
          (_selection)
              ? IconButton(
                  tooltip: this.interfaceDialog[this.abbreviations][1],
                  icon: const Icon(Icons.share),
                  onPressed: () => _runSelection(true),
                )
              : Container(),
        ]),
      ),
    );
  }

  Future _launchUserManual() async {
    String url = 'https://www.uniquebible.app/mobile';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future _launchMarvelBible() async {
    String marvelLink = 'https://marvel.bible/index.php?text=${this.config.marvelBible}&b=${_currentActiveVerse[0]}&c=${_currentActiveVerse[1]}&v=${_currentActiveVerse[2]}';
    if ((!this.config.alwaysOpenMarvelBibleExternally) && (this.config.bigScreen)) {
      setState(() {
        if (!_display) _display = true;
        _changeWorkspace(3);
        if (_webViewController != null) _webViewController.loadUrl(marvelLink);
      });
    } else {
      String url = marvelLink;
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  Future _launchContact() async {
    String url = 'https://marvel.bible/contact/contactform.php';
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
        }
        );
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
      RichText richText;
      if (bcvList[2] == _currentActiveVerse[2]) {
        _activeVerseData = verseData;
        if (this.config.interlinearBibles.contains(module)) {
          List<TextSpan> interlinearSpans =
              InterlinearHelper(this.config.verseTextStyle)
                  .getInterlinearSpan(module, verseContent, book, true);
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
        richText = RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: wordSpans,
          ),
          textDirection: verseDirection,
        );
        return (_selection)
            ? CheckboxListTile(
                title: richText,
                value: (_selectionIndexes.contains(i)),
                onChanged: (bool value) => _updateSelection(i, value),
              )
            : ListTile(
                title: richText,
                onTap: () {
                  _tapActiveVerse(context, _data[i].first);
                },
                onLongPress: () {
                  _longPressedActiveVerse(context, _data[i]);
                },
                trailing: (!this.config.showNotes)
                    ? null
                    : IconButton(
                        tooltip: (_noteList.contains(bcvList[2]))
                            ? interfaceApp[this.abbreviations][16]
                            : interfaceApp[this.abbreviations][15],
                        icon: Icon(
                          (_noteList.contains(bcvList[2]))
                              ? Icons.edit
                              : Icons.note_add,
                          color: this.config.myColors["blue"],
                        ),
                        onPressed: () {
                          _launchNotePad(context, bcvList);
                        }),
              );
      } else {
        if (this.config.interlinearBibles.contains(module)) {
          List<TextSpan> interlinearSpans =
              InterlinearHelper(this.config.verseTextStyle)
                  .getInterlinearSpan(module, verseContent, book);
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
        richText = RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: wordSpans,
          ),
          textDirection: verseDirection,
        );
        return (_selection)
            ? CheckboxListTile(
                title: richText,
                value: (_selectionIndexes.contains(i)),
                onChanged: (bool value) => _updateSelection(i, value),
              )
            : ListTile(
                title: richText,
                trailing: (!this.config.showNotes)
                    ? null
                    : IconButton(
                        tooltip: (_noteList.contains(bcvList[2]))
                            ? interfaceApp[this.abbreviations][16]
                            : interfaceApp[this.abbreviations][15],
                        icon: Icon(
                          (_noteList.contains(bcvList[2]))
                              ? Icons.edit
                              : Icons.note_add,
                          color: this.config.myColors["blueAccent"],
                        ),
                        onPressed: () {
                          _launchNotePad(context, bcvList);
                        }),
                onTap: () {
                  (module == this.bibles.bible1.module)
                      ? _scrollIndex = i
                      : _scrollIndex = (i - 1);
                  _activeIndex = _scrollIndex;
                  setActiveVerse(context, _data[i].first);
                },
                onLongPress: () {
                  _longPressedActiveVerse(context, _data[i]);
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

  Future _openHere(List bcvList, String module) async {
    if (module == this.bibles.bible1.module) {
      (this.config.bigScreen)
          ? _displayChapter = this.bibles.bible1.openSingleChapter(bcvList, true)
          : _displayData = this.bibles.bible1.openSingleChapter(bcvList, true);
    } else if (module == this.bibles.bible2.module) {
      (this.config.bigScreen)
          ? _displayChapter = this.bibles.bible2.openSingleChapter(bcvList, true)
          : _displayData = this.bibles.bible2.openSingleChapter(bcvList, true);
    } else if (module == this.bibles.iBible.module) {
      (this.config.bigScreen)
          ? _displayChapter = this.bibles.iBible.openSingleChapter(bcvList, true)
          : _displayData = this.bibles.iBible.openSingleChapter(bcvList, true);
    } else {
      Bible bible = Bible(module, this.abbreviations);
      await bible.loadData();
      (this.config.bigScreen)
          ? _displayChapter = bible.openSingleChapter(bcvList, true)
          : _displayData = bible.openSingleChapter(bcvList, true);
    }
    setState(() {
      if (this.config.bigScreen) {
        _changeWorkspace(0);
      } else {
        _rawData = [];
      }
    });
  }

  void _changeWorkspace(int i) {
    _tabIndex = i;
    if ((_tabController != null) && (!_tabController.indexIsChanging)) _tabController.animateTo(i);
  }

  Future<void> _longPressedActiveVerse(BuildContext context, List verseData,
      [bool openHere = false]) async {
    _stopRunningActions();

    List bcvList = verseData.first;
    String ref = BibleParser(this.abbreviations).bcvToVerseReference(bcvList);
    String refCh =
        BibleParser(this.abbreviations).bcvToChapterReference(bcvList);

    var copiedText = await Clipboard.getData('text/plain');
    List<Widget> dialogOptions = [
      (openHere)
          ? ListTile(
              leading: Icon(Icons.open_in_browser),
              title: Text(
                  "${interfaceApp[this.abbreviations][22]}$refCh${interfaceApp[this.abbreviations][23]}"),
              onTap: () => Navigator.pop(context, DialogAction.openHere),
            )
          : Container(),
      ListTile(
        leading: Icon(Icons.share),
        title: Text(this.interfaceDialog[this.abbreviations][1]),
        onTap: () => Navigator.pop(context, DialogAction.share),
      ),
      ListTile(
        leading: Icon(Icons.content_copy),
        title: Text(this.interfaceDialog[this.abbreviations][2]),
        onTap: () => Navigator.pop(context, DialogAction.copy),
      ),
      ListTile(
        leading: Icon(Icons.playlist_add),
        title: Text(this.interfaceDialog[this.abbreviations][3]),
        onTap: () => Navigator.pop(context, DialogAction.addCopy),
      ),
      ListTile(
        leading: Icon(Icons.favorite_border),
        title: Text(this.interfaceDialog[this.abbreviations][4]),
        onTap: () => Navigator.pop(context, DialogAction.addFavourite),
      ),
      ListTile(
        leading: Icon(Icons.link),
        title: Text(this.interfaceDialog[this.abbreviations][5]),
        onTap: () => Navigator.pop(context, DialogAction.crossReference),
      ),
      ListTile(
        leading: Icon(Icons.compare_arrows),
        title: Text(this.interfaceDialog[this.abbreviations][6]),
        onTap: () => Navigator.pop(context, DialogAction.compareAll),
      ),
      ListTile(
        leading: Icon(Icons.people),
        title: Text(this.interfaceBottom[this.abbreviations][4]),
        onTap: () => Navigator.pop(context, DialogAction.people),
      ),
      ListTile(
        leading: Icon(Icons.pin_drop),
        title: Text(this.interfaceBottom[this.abbreviations][5]),
        onTap: () => Navigator.pop(context, DialogAction.locations),
      ),
      ListTile(
        leading: Icon(Icons.title),
        title: Text(this.interfaceBottom[this.abbreviations][1]),
        onTap: () => Navigator.pop(context, DialogAction.topics),
      ),
      ListTile(
        leading: Icon(Icons.layers),
        title: Text("OHGB ${this.interfaceDialog[this.abbreviations][7]}"),
        onTap: () => Navigator.pop(context, DialogAction.interlinearOHGB),
      ),
      ListTile(
        leading: Icon(Icons.art_track),
        title: Text("OHGB ${this.interfaceDialog[this.abbreviations][8]}"),
        onTap: () => Navigator.pop(context, DialogAction.morphologyOHGB),
      ),
      ListTile(
        leading: Icon(Icons.layers),
        title: Text("ABP ${this.interfaceDialog[this.abbreviations][7]}"),
        onTap: () => Navigator.pop(context, DialogAction.interlinearABP),
      ),
      /*SimpleDialogOption(
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
      ),*/
    ];
    int bookNo = bcvList.first;
    if ((bookNo < 40) || (bookNo > 66)) {
      List<Widget> lxxDialogOptions = [
        ListTile(
          leading: Icon(Icons.layers),
          title: Text("LXX1 ${this.interfaceDialog[this.abbreviations][7]}"),
          onTap: () => Navigator.pop(context, DialogAction.interlinearLXX1),
        ),
        ListTile(
          leading: Icon(Icons.art_track),
          title: Text("LXX1 ${this.interfaceDialog[this.abbreviations][8]}"),
          onTap: () => Navigator.pop(context, DialogAction.morphologyLXX1),
        ),
        ListTile(
          leading: Icon(Icons.layers),
          title: Text("LXX2 ${this.interfaceDialog[this.abbreviations][7]}"),
          onTap: () => Navigator.pop(context, DialogAction.interlinearLXX2),
        ),
        ListTile(
          leading: Icon(Icons.art_track),
          title: Text("LXX2 ${this.interfaceDialog[this.abbreviations][8]}"),
          onTap: () => Navigator.pop(context, DialogAction.morphologyLXX2),
        ),
        /*SimpleDialogOption(
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
        ),*/
      ];
      dialogOptions = [...dialogOptions, ...lxxDialogOptions];
    }
    switch (await showDialog<DialogAction>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(ref),
            children: dialogOptions,
          );
        })) {
      case DialogAction.share:
        Share.share("${verseData[1]} ($ref, ${verseData.last})");
        break;
      case DialogAction.copy:
        Clipboard.setData(
            ClipboardData(text: "${verseData[1]} ($ref, ${verseData.last})"));
        break;
      case DialogAction.addCopy:
        var combinedText = copiedText.text;
        combinedText += "\n${verseData[1]} ($ref, ${verseData.last})";
        Clipboard.setData(ClipboardData(text: combinedText));
        break;
      case DialogAction.addFavourite:
        addToFavourite(bcvList);
        break;
      case DialogAction.crossReference:
        _loadXRef(context, bcvList);
        break;
      case DialogAction.compareAll:
        _loadCompare(context, bcvList);
        break;
      case DialogAction.people:
        _loadPeople(context, bcvList);
        break;
      case DialogAction.locations:
        _loadLocation(context, bcvList);
        break;
      case DialogAction.topics:
        _loadTopics(context, bcvList);
        break;
      case DialogAction.interlinearOHGB:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, bcvList, "OHGB")
            : _loadInterlinearView(context, bcvList, "OHGB");
        break;
      case DialogAction.morphologyOHGB:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, bcvList, "OHGB")
            : _loadMorphologyView(context, bcvList, "OHGB");
        break;
      case DialogAction.interlinearLXX1:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, bcvList, "LXX1")
            : _loadInterlinearView(context, bcvList, "LXX1");
        break;
      case DialogAction.morphologyLXX1:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, bcvList, "LXX1")
            : _loadMorphologyView(context, bcvList, "LXX1");
        break;
      case DialogAction.interlinearLXX2:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, bcvList, "LXX2")
            : _loadInterlinearView(context, bcvList, "LXX2");
        break;
      case DialogAction.morphologyLXX2:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, bcvList, "LXX2")
            : _loadMorphologyView(context, bcvList, "LXX2");
        break;
      case DialogAction.interlinearABP:
        (this.config.bigScreen)
            ? _loadOriginalWord(context, bcvList, "ABP")
            : _loadInterlinearView(context, bcvList, "ABP");
        break;
      case DialogAction.openHere:
        _openHere(bcvList, verseData.last);
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
      _changeWorkspace(1);
    });
  }

  // This is the function which does the search.
  List _fetch(String query) {
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
              bookString += config.bookCollection[bookTrim] ?? "$bookTrim 0; ";
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
      String possibleReference = (query.contains("：")) ? query.replaceAll("：", ":") : query;
      RegExp irregularHyphen = new RegExp(r"[－─]");
      if (irregularHyphen.hasMatch(possibleReference)) possibleReference = possibleReference.replaceAll(irregularHyphen, "-");
      var verseReferenceList =
          BibleParser(this.abbreviations).extractAllReferences(possibleReference);
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

  Widget _buildWorkspace(BuildContext context) {
    int count =
    ((_rawData.isNotEmpty) && (_rawData.length > _displayData.length))
        ? (_displayData.length + 1)
        : _displayData.length;

    /*final _tabs = <Tab>[
      Tab(text: "1",),
      Tab(text: "2",),
      Tab(text: "3",),
      Tab(text: "4",),
    ];*/
    List<Widget> pages = <Widget>[
      ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _displayChapter.length,
          itemBuilder: (context, i) {
            _tabController = DefaultTabController.of(context);
            if (i == 0) return _buildDisplayChapterRow(context, i);
            return _buildDisplayVerseRow(context, i, true);
          }),
      ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: count,
          itemBuilder: (context, i) {
            _tabController = DefaultTabController.of(context);
            return (i == _displayData.length)
                ? _buildMoreDisplayVerseRow(context, i)
                : _buildDisplayVerseRow(context, i);
          }),
      ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: (_morphology.isEmpty) ? (_morphology.length + 1) : (_morphology.length + 2),
          itemBuilder: (context, i) {
            _tabController = DefaultTabController.of(context);
            Map item1;
            List bcvList;
            if (_morphology.isNotEmpty) {
              item1 = _morphology.first;
              bcvList = [item1["Book"], item1["Chapter"], item1["Verse"]];
            }
            if (i == 0) {
              if (_morphology.isEmpty) {
                Map captions = {
                  "ENG": "[Open Interlinear & Morphology HERE]",
                  "TC": "[在這裡開啟聖經原文資料]",
                  "SC": "[在这里开启圣经原文资料]",
                };
                return ListTile(
                  title: Text(captions[this.abbreviations], style: _verseNoFont,),
                  onTap: () => _selectInterlinear(context),
                  trailing: IconButton(
                    icon: Icon(Icons.more_vert, color: this.config.myColors["blueAccent"],),
                    onPressed: () => _selectInterlinear(context),
                  ),
                );
              } else {
                String verseReference = BibleParser(this.abbreviations).bcvToVerseReference(bcvList);
                return ListTile(
                  title: Text("[$verseReference]", style: _verseNoFont,),
                  onTap: () => _newVerseSelected([bcvList, "", this.bibles.bible1.module]),
                  trailing: IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () => _selectInterlinear(context),
                  ),
                );
              }
            } else if (i == 1) {
              return _interlinearTile(context, bcvList);
            }
            return _buildMorphologyCard(context, (i - 2));
          }),
      WebView(
        initialUrl: 'https://marvel.bible/index.php?text=${this.config.marvelBible}&b=${_currentActiveVerse[0]}&c=${_currentActiveVerse[1]}&v=${_currentActiveVerse[2]}',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _webViewController = webViewController;
        },
      ),
    ];
    return DefaultTabController(
      initialIndex: _tabIndex,
      length: pages.length,
      child: Builder(
        builder: (BuildContext context) => Padding(
          padding: EdgeInsets.zero,
          child: Theme(
            data: this.config.mainTheme,
            child: Column(
              children: <Widget>[
                TabPageSelector(),
                /*TabBar(
                  labelColor: this.config.myColors["blueAccent"],
                  unselectedLabelColor: this.config.myColors["blue"],
                  tabs: _tabs,
                ),*/
                Expanded(
                  child: IconTheme(
                    data: IconThemeData(
                      color: Colors.blueGrey[this.config.backgroundColor],
                    ),
                    child: TabBarView(children: pages,),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMorphologyCard(BuildContext context, int i) {
    final Map wordData = _morphology[i];
    final bool _isHebrew = (wordData["Book"] < 40) && (this.bibles.iBible.module == "OHGBi");
    final List bcvList = [wordData["Book"], wordData["Chapter"], wordData["Verse"]];
    final Map interface = {
      "ENG": [
        "Morphology",
        "Less",
        "Search",
        "More",
        "Audio",
        "Search this morphology"
      ],
      "TC": ["原文形態學", "翻譯", "搜索", "更多", "語音功能", "搜索此形態"],
      "SC": ["原文形态学", "翻译", "搜索", "更多", "语音功能", "搜索此形态"],
    };

    String morphology = wordData["Morphology"].replaceAll(",", ", ");
    morphology = morphology.substring(0, (morphology.length - 2));
    final textStyle = TextStyle(
      fontSize: (this.config.fontSize - 2),
      color: this.config.myColors["grey"],
    );
    TextStyle originalStyle = (_isHebrew)
        ? this.config.verseTextStyle["verseFontHebrew"]
        : this.config.verseTextStyle["verseFontGreek"];
    Widget word = Text(wordData["Word"], style: originalStyle);
    String lexemeText = wordData["Lexeme"];
    Widget lexeme = Text(lexemeText, style: originalStyle);
    //String lexicalEntry = (wordData["LexicalEntry"].isNotEmpty) ? wordData["LexicalEntry"].split(",").toList()[0] : "";
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: IconButton(
                tooltip: interface[this.abbreviations][4],
                icon: Icon(
                  Icons.volume_up,
                  color: this.config.myColors["black"],
                ),
                onPressed: () {
                  if (this.config.plus) {
                    String wordText = ((_isHebrew) && (Platform.isAndroid))
                        ? TtsHelper().workaroundHebrew(wordData["Transliteration"])
                        : wordData["Word"];
                    _speakWord(wordText, _isHebrew);
                  } else {
                    _nonPlusMessage(interface[this.abbreviations][4]);
                  }
                },
              ),
              title: word,
              subtitle: Text(
                  "${wordData["Transliteration"]} [${wordData["Pronunciation"]}]",
                  style: textStyle),
              onTap: () {
                _loadLexiconView(context, wordData["LexicalEntry"]);
              },
              trailing: IconButton(
                tooltip: interface[this.abbreviations][3],
                icon: Icon(
                  Icons.more_vert,
                  color: this.config.myColors["black"],
                ),
                onPressed: () {
                  _loadOriginalWord(context, bcvList, "OHGB", i);
                },
              ),
            ),
            ListTile(
              leading: IconButton(
                tooltip: interface[this.abbreviations][5],
                icon: Icon(
                  Icons.label_outline,
                  color: this.config.myColors["black"],
                ),
                onPressed: () {
                  _loadMorphologySearchView(context, lexemeText, wordData["LexicalEntry"], morphology);
                },
              ),
              title: lexeme,
              subtitle: Text(morphology, style: textStyle),
              onTap: () {
                _loadMorphologySearchView(context, lexemeText, wordData["LexicalEntry"], morphology);
              },
              trailing: IconButton(
                tooltip: interface[this.abbreviations][2],
                icon: Icon(
                  Icons.search,
                  color: this.config.myColors["black"],
                ),
                onPressed: () {
                  _loadMorphologySearchView(context, lexemeText, wordData["LexicalEntry"], morphology);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _loadLexiconView(BuildContext context, String lexicalEntries) async {
    List lexicons = await SqliteHelper(this.config).getLexicons(lexicalEntries);
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => LexiconView(this.config, lexicons, this.bibles)),
    );
    if (selected != null) _newVerseSelected(selected);
  }

  Future _loadMorphologySearchView(BuildContext context, lexemeText, lexicalEntry, morphology) async {
    _toolOpened = true;
    List searchData = await searchMorphology(lexicalEntry.split(",").first, morphology.split(", "));
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MorphologySearchTablet(lexemeText, lexicalEntry,
              morphology, "OHGB", this.config, this.bibles, searchData, this.flutterTts)),
    );
    if (selected != null) _newVerseSelected(selected);
    _toolOpened = false;
  }

  Future searchMorphology(String lexicalEntry, List selectedMorphologyItems) async {
    if (lexicalEntry.isNotEmpty) {
      final Database db = await SqliteHelper(this.config).initMorphologyDb();
      String statement;
      String prefix =
          "SELECT * FROM OHGB WHERE LexicalEntry LIKE '%$lexicalEntry,%'";
      if (selectedMorphologyItems.isEmpty) {
        statement = prefix;
      } else {
        List<String> statementItems = selectedMorphologyItems
            .map<String>((i) => "AND Morphology LIKE '%$i,%'")
            .toList()
          ..insert(0, prefix);
        statement = statementItems.join(" ");
      }
      List<Map> morphology = await db.rawQuery(statement);
      //_morphologySearchResults(context, morphology);
      db.close();
      return morphology;
    }
    return [];
  }

  Future _speakWord(String message, bool isHebrew) async {
    if (isPlaying) await _stop();
    if ((message != null) && (message.isNotEmpty)) {
      if (isHebrew) {
        (Platform.isAndroid)
            ? await flutterTts.setLanguage("el-GR")
            : await flutterTts.setLanguage("he-IL");
      } else {
        message = TtsHelper().removeGreekAccents(message);
        await flutterTts.setLanguage("el-GR");
      }
      var result = await flutterTts.speak(message);
      if (result == 1)
        setState(() {
          _speakOneVerse = true;
          ttsState = TtsState.playing;
        });
    }
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

  Widget _buildDisplayVerseRow(BuildContext context, int i, [bool chapter = false]) {
    var verseData = (chapter) ? _displayChapter[i] : _displayData[i];

    return ListTile(
      title: _buildVerseText(context, verseData),
      onTap: () {
        if (verseData.first.isNotEmpty) {
          _newVerseSelected(verseData);
        } else {
          _longPressedActiveVerse(context, _activeVerseData ?? [_currentActiveVerse, "[...]", ""], true);
        }
      },
      onLongPress: () {
        if (verseData.first.isNotEmpty) {
          _longPressedActiveVerse(context, verseData, true);
        } else {
          _longPressedActiveVerse(context, _activeVerseData ?? [_currentActiveVerse, "[...]", ""], true);
        }
      },
    );
  }

  Widget _buildDisplayChapterRow(BuildContext context, int i) {
    Map captions = {
      "ENG": ["", "[Open a Chapter HERE]", ""],
      "TC": ["", "[在這裡開啟經文]", ""],
      "SC": ["", "[在这里开启经文]", ""],
    };
    var verseData = captions[this.abbreviations];
    return ListTile(
      title: _buildVerseText(context, verseData),
      onTap: () {
        _openChapterSelector(context);
      },
      trailing: IconButton(
        tooltip: interfaceApp[this.config.abbreviations][25],
        icon: Icon(Icons.more_vert, color: this.config.myColors["blueAccent"],),
        onPressed: () async {
          _openChapterSelector(context);
        },
      ),
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

    if ((verseData.first.isNotEmpty) && (this.config.hebrewBibles.contains(verseModule)) &&
        (verseData.first.first < 40)) {
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

  List<TextSpan> getInterlinearSpan(BuildContext context, String text, List bcvList, [bool isActive = false]) {
    int book = bcvList.first;
    bool isHebrewBible = ((book < 40) && (this.bibles.iBible.module == "OHGBi"));

    var originalStyle;
    if (!isActive) {
      originalStyle = _verseFontGreek;
      if (isHebrewBible) originalStyle = _verseFontHebrew;
    } else {
      originalStyle = _activeVerseFontGreek;
      if (isHebrewBible) originalStyle = _activeVerseFontHebrew;
    }
    List<TextSpan> words = <TextSpan>[];
    List<String> wordList = text.split("｜");

    wordList.asMap().forEach((index, word) {
      if (word.startsWith("＠")) {
        if (isHebrewBible) {
          List<String> glossList = word.substring(1).split(" ");
          for (var gloss in glossList) {
            if ((gloss.startsWith("[")) || (gloss.endsWith("]"))) {
              gloss = gloss.replaceAll(RegExp(r"[\[\]\+\.]"), "");
              words.add(TextSpan(text: "$gloss ", style: _interlinearStyleDim));
            } else {
              words.add(TextSpan(text: "$gloss ", style: _interlinearStyle));
            }
          }
        } else {
          words
              .add(TextSpan(text: word.substring(1), style: _interlinearStyle));
        }
      } else {
        (this.config.bigScreen)
            ? words.add(
            TextSpan(
              text: word,
              style: originalStyle,
              recognizer: TapGestureRecognizer()..onTap = () {
                //Navigator.pop(context, [bcvList, (index ~/ 2)]);
                _loadOriginalWord(context, bcvList, ((this.bibles.iBible.module != "OHGBi") && ((bcvList.first > 66) || (bcvList.first < 40))) ? "LXX1" : "OHGB", (index ~/ 2));
              },
            )
        )
            : words.add(
            TextSpan(
              text: word,
              style: originalStyle,
            )
        );
      }
    });

    return words;
  }

}
