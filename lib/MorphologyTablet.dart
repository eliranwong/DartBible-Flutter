import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Bibles.dart';
import 'BibleParser.dart';
import 'config.dart';
import 'Helpers.dart';
import 'Morphology.dart';

class OriginalWord extends StatefulWidget {
  final List<Map> _data;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  final FlutterTts flutterTts;
  final int _wordIndex;

  OriginalWord(this._data, this._module, this._config, this._bibles, this.flutterTts,
      [this._wordIndex]);

  @override
  OriginalWordState createState() => OriginalWordState(
      this._data, this._module, this._config, this._bibles, this._wordIndex, this.flutterTts);
}

class OriginalWordState extends State<OriginalWord> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  int _wordIndex;
  Map _wData;
  double _fontSize;
  bool _isHebrew;
  String abbreviations;
  final Map interface1 = {
    "ENG": ["Word Analysis", "More", "Audio"],
    "TC": ["原文分析", "更多", "語音功能"],
    "SC": ["原文分析", "更多", "语音功能"],
  };
  final Map interface2 = {
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
  final Map interface3 = {
    "ENG": ["Lexicon", "Search", "Audio"],
    "TC": ["原文辭典", "搜索", "語音功能"],
    "SC": ["原文词典", "搜索", "语音功能"],
  };

  // Variables to work with TTS
  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  OriginalWordState(
      this._data, this._module, this._config, this._bibles, this._wordIndex, this.flutterTts) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
    this._isHebrew = ((_module == "OHGB") &&
        (_data != null) &&
        (_data.isNotEmpty) &&
        (_data.first["Book"] < 40));
    //if ((_data.isNotEmpty) && (this._wordIndex == null)) this._wordIndex = 0;
    if (this._wordIndex != null) _wData = _data[this._wordIndex];
  }

  /*@override
  initState() {
    super.initState();
    initTts();
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  initTts() {
    flutterTts = FlutterTts();

    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }*/

  Future _speak(String message) async {
    if (isPlaying) await _stop();
    if ((message != null) && (message.isNotEmpty)) {
      if (_isHebrew) {
        (Platform.isAndroid)
            ? await flutterTts.setLanguage("el-GR")
            : await flutterTts.setLanguage("he-IL");
      } else if (_config.greekBibles.contains(_module)) {
        message = TtsHelper().removeGreekAccents(message);
        await flutterTts.setLanguage("el-GR");
      }
      var result = await flutterTts.speak(message);
      if (result == 1)
        setState(() {
          ttsState = TtsState.playing;
        });
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1)
      setState(() {
        ttsState = TtsState.stopped;
      });
  }

  void _nonPlusMessage(String feature) {
    String message =
        "'$feature' ${_config.plusMessage[this.abbreviations].first}";
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: _config.plusMessage[this.abbreviations].last,
        onPressed: () {
          _launchPlusPage();
        },
      ),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future _launchPlusPage() async {
    String url = _config.plusURL;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _wrap(Widget widget, int flex) {
    return Expanded(
      flex: flex,
      child: widget,
    );
  }

  @override
  Widget build(BuildContext context) {
    var verseRef = "";
    if (_data.isNotEmpty)
      verseRef = BibleParser(this.abbreviations).bcvToVerseReference(
          [_data[0]["Book"], _data[0]["Chapter"], _data[0]["Verse"]]);
    final title = "${interface1[this.abbreviations][0]} - $verseRef";
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(title),
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            List<Widget> layoutWidgets = _buildLayoutWidgets(context);
            return (orientation == Orientation.portrait)
                ? Column(children: layoutWidgets)
                : Row(children: layoutWidgets);
          },
        ),
      ),
    );
  }

  List<Widget> _buildLayoutWidgets(BuildContext context) {
    return <Widget>[
      _wrap(_buildInterlinearCardList(context), 1),
      (_module == "ABP") ? Container() : _buildDivider(),
      (_module == "ABP") ? Container() : _wrap(_buildMorphologyCardList(context), 1),
      (_wData == null) ? Container() : _buildDivider(),
      (_wData == null) ? Container() : _wrap(_buildWordList(context), 1),
    ];
  }

  Widget _buildDivider() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: _config.myColors["grey"])
      ),
    );
  }

  Widget _buildInterlinearCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(15.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildInterlinearCard(context, i);
        });
  }

  Widget _buildInterlinearCard(BuildContext context, int i) {
    final wordData = _data[i];
    final textStyle = TextStyle(
      fontSize: (_fontSize - 2),
      color: _config.myColors["grey"],
    );
    TextStyle originalStyle = (_isHebrew)
        ? _config.verseTextStyle["verseFontHebrew"]
        : _config.verseTextStyle["verseFontGreek"];
    Widget word;
    word = Text(wordData["Word"], style: originalStyle);
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: IconButton(
                tooltip: interface1[this.abbreviations][2],
                icon: Icon(
                  Icons.volume_up,
                  color: _config.myColors["black"],
                ),
                onPressed: () {
                  if (_config.plus) {
                    String wordText = ((_isHebrew) && (Platform.isAndroid))
                        ? TtsHelper()
                            .workaroundHebrew(wordData["Transliteration"])
                        : wordData["Word"];
                    _speak(wordText);
                  } else {
                    _nonPlusMessage(interface1[this.abbreviations][2]);
                  }
                },
              ),
              title: word,
              subtitle: Text(wordData["Interlinear"], style: textStyle),
              onTap: () {
                _loadLexiconView(context, wordData["LexicalEntry"]);
              },
              trailing: IconButton(
                tooltip: interface1[this.abbreviations][1],
                icon: Icon(
                  Icons.more_vert,
                  color: _config.myColors["black"],
                ),
                onPressed: () {
                  _loadWordView(context, wordData);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future _loadWordView(BuildContext context, Map wordData) async {
    /*final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WordView(wordData, _module, _config, _bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);*/
    setState(() {
      _wData = wordData;
    });
  }

  Future _loadLexiconView(BuildContext context, String lexicalEntries) async {
    List lexicons = await SqliteHelper(_config).getLexicons(lexicalEntries);
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => LexiconView(_config, lexicons, _bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  Widget _buildMorphologyCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(15.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildMorphologyCard(context, i);
        });
  }

  Widget _buildMorphologyCard(BuildContext context, int i) {
    final wordData = _data[i];
    String morphology = wordData["Morphology"].replaceAll(",", ", ");
    morphology = morphology.substring(0, (morphology.length - 2));
    final textStyle = TextStyle(
      fontSize: (_fontSize - 2),
      color: _config.myColors["grey"],
    );
    TextStyle originalStyle = (_isHebrew)
        ? _config.verseTextStyle["verseFontHebrew"]
        : _config.verseTextStyle["verseFontGreek"];
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
                tooltip: interface2[this.abbreviations][4],
                icon: Icon(
                  Icons.volume_up,
                  color: _config.myColors["black"],
                ),
                onPressed: () {
                  if (_config.plus) {
                    String wordText = ((_isHebrew) && (Platform.isAndroid))
                        ? TtsHelper()
                            .workaroundHebrew(wordData["Transliteration"])
                        : wordData["Word"];
                    _speak(wordText);
                  } else {
                    _nonPlusMessage(interface2[this.abbreviations][4]);
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
                tooltip: interface2[this.abbreviations][3],
                icon: Icon(
                  Icons.more_vert,
                  color: _config.myColors["black"],
                ),
                onPressed: () {
                  _loadWordView(context, wordData);
                },
              ),
            ),
            ListTile(
              leading: IconButton(
                tooltip: interface2[this.abbreviations][5],
                icon: Icon(
                  Icons.label_outline,
                  color: _config.myColors["black"],
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
                tooltip: interface2[this.abbreviations][2],
                icon: Icon(
                  Icons.search,
                  color: _config.myColors["black"],
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

  Future _loadMorphologySearchView(BuildContext context, lexemeText, lexicalEntry, morphology) async {
    List searchData = await searchMorphology(lexicalEntry.split(",").first, morphology.split(", "));
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MorphologySearchTablet(lexemeText, lexicalEntry,
              morphology, this._module, this._config, this._bibles, searchData, this.flutterTts)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  Future searchMorphology(String lexicalEntry, List selectedMorphologyItems) async {
    if (lexicalEntry.isNotEmpty) {
      final Database db = await SqliteHelper(this._config).initMorphologyDb();
      String statement;
      String prefix =
          "SELECT * FROM $_module WHERE LexicalEntry LIKE '%$lexicalEntry,%'";
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

  Widget _buildWordList(BuildContext context) {
    Text originalWord = (_isHebrew)
        ? Text(_wData["Word"], style: _config.verseTextStyle["verseFontHebrew"])
        : Text(_wData["Word"], style: _config.verseTextStyle["verseFontGreek"]);

    List bcvList = [_wData["Book"], _wData["Chapter"], _wData["Verse"]];

    List<Bible> bibleList = [_bibles.bible1, _bibles.bible2, _bibles.iBible];
    List<Widget> verseList = bibleList
        .map((bible) => _buildVerseRow(
            context, bible.openSingleVerse(bcvList), bible.module, bcvList))
        .toList();

    List<String> keys = _wData.keys.toList();
    List<Widget> dataList =
        keys.map((key) => _buildKeyRow(context, key)).toList();

    return ListView(children: <Widget>[
      ExpansionTile(
        title: Text(
          BibleParser(_config.abbreviations).bcvToVerseReference(bcvList),
          style: TextStyle(
            color: _config.myColors["black"],
          ),
        ),
        initiallyExpanded: false,
        backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
        children: verseList,
      ),
      ExpansionTile(
        title: originalWord,
        initiallyExpanded: true,
        backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
        children: dataList,
      ),
    ]);
  }

  Widget _buildVerseRow(
      BuildContext context, String text, String module, List bcvList) {
    int book = bcvList[0];
    TextDirection verseDirection =
        ((_config.hebrewBibles.contains(module)) && (_isHebrew))
            ? TextDirection.rtl
            : TextDirection.ltr;
    TextStyle verseFont;
    if ((_config.hebrewBibles.contains(module)) && (_isHebrew)) {
      verseFont = _config.verseTextStyle["verseFontHebrew"];
    } else if (_config.greekBibles.contains(module)) {
      verseFont = _config.verseTextStyle["verseFontGreek"];
    } else {
      verseFont = _config.verseTextStyle["verseFont"];
    }
    List<TextSpan> wordSpans = (_config.interlinearBibles.contains(module))
        ? InterlinearHelper(_config.verseTextStyle)
            .getInterlinearSpan(text, book)
        : <TextSpan>[TextSpan(text: text, style: verseFont)];
    return ListTile(
      title: RichText(
        text: TextSpan(
          //style: DefaultTextStyle.of(context).style,
          children: wordSpans,
        ),
        textDirection: verseDirection,
      ),
      subtitle: Text(
        "[$module]",
        style: TextStyle(
          color: _config.myColors["blue"],
        ),
      ),
      onTap: () {
        Navigator.pop(context, [bcvList, "", module]);
      },
    );
  }

  Widget _buildKeyRow(BuildContext context, String key) {
    TextStyle titleStyle =
        TextStyle(fontSize: (this._config.fontSize - 4), color: Colors.grey);
    TextStyle dataStyle = _config.verseTextStyle["verseFont"];
    if ((key == "Word") || (key == "Lexeme"))
      dataStyle = _config.verseTextStyle["verseFontGreek"];
    if ((_isHebrew) && ((key == "Word") || (key == "Lexeme")))
      dataStyle = _config.verseTextStyle["verseFontHebrew"];
    String data = _wData[key].toString();
    if (data.contains(","))
      data = data.split(",").sublist(0, data.split(",").length - 1).join(", ");

    // add trailing icon & action where it is appropriate
    IconButton trailing;
    if (key == "Morphology") {
      trailing = IconButton(
        tooltip: interface3[_config.abbreviations][1],
        icon: Icon(
          Icons.search,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          _loadMorphologySearchView(
              context, _wData["Lexeme"], _wData["LexicalEntry"], data);
        },
      );
    } else if (key == "LexicalEntry") {
      trailing = IconButton(
        tooltip: interface3[_config.abbreviations][0],
        icon: Icon(
          Icons.translate,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          _loadLexiconView(context, _wData["LexicalEntry"]);
        },
      );
    } else if (key == "Word") {
      trailing = IconButton(
        tooltip: interface3[_config.abbreviations][2],
        icon: Icon(
          Icons.volume_up,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          if (_config.plus) {
            String wordText = ((_isHebrew) && (Platform.isAndroid))
                ? TtsHelper().workaroundHebrew(_wData["Transliteration"])
                : _wData["Word"];
            _speak(wordText);
          } else {
            _nonPlusMessage(interface3[_config.abbreviations][2]);
          }
        },
      );
    }

    // add spacing to connected words in key
    RegexHelper _regex = RegexHelper();
    _regex.searchReplace = [
      ['([a-z])([A-Z])', r'\1 \2'],
    ];
    key = _regex.doSearchReplace(key);

    return ListTile(
      title: Text(key, style: titleStyle),
      subtitle: Text(data, style: dataStyle),
      trailing: trailing,
    );
  }
}

class MorphologySearchTablet extends StatefulWidget {
  final String _lexeme, _lexicalEntry, _morphology, _module;
  final Config _config;
  final Bibles _bibles;
  final List<Map> _data;
  final FlutterTts flutterTts;

  MorphologySearchTablet(this._lexeme, this._lexicalEntry, this._morphology,
      this._module, this._config, this._bibles, this._data, this.flutterTts);

  @override
  MorphologySearchTabletState createState() => MorphologySearchTabletState(
    this._lexeme,
    this._lexicalEntry,
    this._morphology,
    this._module,
    this._config,
    this._bibles,
    this._data,
    this.flutterTts,
  );
}

class MorphologySearchTabletState extends State<MorphologySearchTablet> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final String _lexeme, _lexicalEntry, _morphology, _module;
  final Config _config;
  final Bibles _bibles;
  String lexicalEntry = "";
  List<String> morphologyItems, selectedMorphologyItems;

  String abbreviations;
  double _fontSize;
  List<Map> _data;
  Map _wData;
  bool _isHebrew;

  final Map interface1 = {
    "ENG": ["Search", "Morphology Search"],
    "TC": ["搜索", "原文形態搜索"],
    "SC": ["搜索", "原文形态搜索"],
  };
  final Map interface2 = {
    "ENG": ["Found", "words", "More"],
    "TC": ["找到", "個字", "更多"],
    "SC": ["找到", "个字", "更多"],
  };
  final Map interface3 = {
    "ENG": ["Lexicon", "Search", "Audio"],
    "TC": ["原文辭典", "搜索", "語音功能"],
    "SC": ["原文词典", "搜索", "语音功能"],
  };

  // Variables to work with TTS
  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  MorphologySearchTabletState(this._lexeme, this._lexicalEntry,
      this._morphology, this._module, this._config, this._bibles, this._data, this.flutterTts) {
    morphologyItems = _morphology.split(", ");
    selectedMorphologyItems = List<String>.from(morphologyItems);
    if (_lexicalEntry.isNotEmpty)
      this.lexicalEntry = _lexicalEntry.split(",").first;
    this._fontSize = _config.fontSize;
    this.abbreviations = _config.abbreviations;
    this._isHebrew = ((_module == "OHGB") &&
        (_data != null) &&
        (_data.isNotEmpty) &&
        (_data.first["Book"] < 40));
  }

  /*@override
  initState() {
    super.initState();
    initTts();
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  initTts() {
    flutterTts = FlutterTts();

    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }*/

  Future _speak(String message) async {
    if (isPlaying) await _stop();
    if ((message != null) && (message.isNotEmpty)) {
      if (_isHebrew) {
        (Platform.isAndroid)
            ? await flutterTts.setLanguage("el-GR")
            : await flutterTts.setLanguage("he-IL");
      } else if (_config.greekBibles.contains(_module)) {
        message = TtsHelper().removeGreekAccents(message);
        await flutterTts.setLanguage("el-GR");
      }
      var result = await flutterTts.speak(message);
      if (result == 1)
        setState(() {
          ttsState = TtsState.playing;
        });
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1)
      setState(() {
        ttsState = TtsState.stopped;
      });
  }

  void _nonPlusMessage(String feature) {
    String message =
        "'$feature' ${_config.plusMessage[this.abbreviations].first}";
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: _config.plusMessage[this.abbreviations].last,
        onPressed: () {
          _launchPlusPage();
        },
      ),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future _launchPlusPage() async {
    String url = _config.plusURL;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }


  Future searchMorphology(BuildContext context) async {
    final Database db = await SqliteHelper(this._config).initMorphologyDb();
    String statement;
    String prefix =
        "SELECT * FROM $_module WHERE LexicalEntry LIKE '%$lexicalEntry,%'";
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

    setState(() {
      _data = morphology;
    });
  }

  Widget _wrap(Widget widget, int flex) {
    return Expanded(
      flex: flex,
      child: widget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("${interface1[_config.abbreviations][1]} (x ${_data.length})"),
          actions: <Widget>[
            IconButton(
              tooltip: interface1[_config.abbreviations][0],
              icon: const Icon(Icons.search),
              onPressed: () {
                (_config.plus)
                    ? searchMorphology(context)
                    : _nonPlusMessage(interface1[_config.abbreviations][1]);
              },
            ),
          ],
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            List<Widget> layoutWidgets = _buildLayoutWidgets(context);
            return (orientation == Orientation.portrait)
                ? Column(children: layoutWidgets)
                : Row(children: layoutWidgets);
          },
        ),
      ),
    );
  }

  List<Widget> _buildLayoutWidgets(BuildContext context) {
    return <Widget>[
      _wrap(_buildMorphology(context), 1),
      _buildDivider(),
      _wrap(_buildCardList(context), 1),
      (_wData == null) ? Container() : _buildDivider(),
      (_wData == null) ? Container() : _wrap(_buildWordList(context), 1),
    ];
  }

  Widget _buildDivider() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: _config.myColors["grey"])
      ),
    );
  }

  Widget _buildMorphology(BuildContext context) {
    List<Widget> morphologyItemList =
        morphologyItems.map((i) => _buildMorphologyRow(i)).toList();
    return ListView(children: <Widget>[
      ListTile(
        title: Text(
          _lexeme,
          style: (lexicalEntry.startsWith("E")) ? _config.verseTextStyle["verseFontHebrew"] : _config.verseTextStyle["verseFontGreek"],
        ),
        subtitle: Text(
          lexicalEntry,
          style: TextStyle(color: _config.myColors["grey"]),
        ),
      ),
      ExpansionTile(
        title: Text("+"),
        initiallyExpanded: true,
        backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
        children: morphologyItemList,
      ),
    ]);
  }

  Widget _buildMorphologyRow(String item) {
    return CheckboxListTile(
        title: Text(
          item,
          style: TextStyle(color: _config.myColors["black"]),
        ),
        value: (selectedMorphologyItems.contains(item)),
        onChanged: (bool value) {
          setState(() {
            if (value) {
              selectedMorphologyItems.add(item);
            } else {
              var index = selectedMorphologyItems.indexOf(item);
              selectedMorphologyItems.removeAt(index);
            }
          });
        });
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(15.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordData = _data[i];
    final textStyle = TextStyle(
      fontSize: (_fontSize - 2),
      color: _config.myColors["grey"],
    );
    TextStyle originalStyle = ((wordData["Book"] < 40) && (_module == "OHGB"))
        ? _config.verseTextStyle["verseFontHebrew"]
        : _config.verseTextStyle["verseFontGreek"];
    Widget word = Text(wordData["Word"], style: originalStyle);
    var bcvList = [wordData["Book"], wordData["Chapter"], wordData["Verse"]];
    String verseReference =
        BibleParser(this.abbreviations).bcvToVerseReference(bcvList);
    return Center(
      child: Card(
        child: Container(
          color: Colors.grey[_config.backgroundColor + 100],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: IconButton(
                  tooltip: interface3[this.abbreviations][2],
                  icon: Icon(
                    Icons.volume_up,
                    color: _config.myColors["black"],
                  ),
                  onPressed: () {
                    if (_config.plus) {
                      String wordText = ((_isHebrew) && (Platform.isAndroid))
                          ? TtsHelper()
                          .workaroundHebrew(wordData["Transliteration"])
                          : wordData["Word"];
                      _speak(wordText);
                    } else {
                      _nonPlusMessage(interface3[this.abbreviations][2]);
                    }
                  },
                ),
                title: word,
                subtitle: Text(verseReference, style: textStyle),
                onTap: () {
                  Navigator.pop(context, [bcvList, "", _bibles.bible1.module]);
                },
                trailing: IconButton(
                  tooltip: interface2[this.abbreviations][2],
                  icon: Icon(
                    Icons.more_vert,
                    color: _config.myColors["black"],
                  ),
                  onPressed: () {
                    _loadWordView(context, wordData);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _loadWordView(BuildContext context, Map wordData) async {
    /*final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WordView(wordData, _module, _config, _bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);*/
    setState(() {
      _wData = wordData;
    });
  }

  Widget _buildWordList(BuildContext context) {
    Text originalWord = (_isHebrew)
        ? Text(_wData["Word"], style: _config.verseTextStyle["verseFontHebrew"])
        : Text(_wData["Word"], style: _config.verseTextStyle["verseFontGreek"]);

    List bcvList = [_wData["Book"], _wData["Chapter"], _wData["Verse"]];

    List<Bible> bibleList = [_bibles.bible1, _bibles.bible2, _bibles.iBible];
    List<Widget> verseList = bibleList
        .map((bible) => _buildVerseRow(
        context, bible.openSingleVerse(bcvList), bible.module, bcvList))
        .toList();

    List<String> keys = _wData.keys.toList();
    List<Widget> dataList =
    keys.map((key) => _buildKeyRow(context, key)).toList();

    return ListView(children: <Widget>[
      ExpansionTile(
        title: Text(
          BibleParser(_config.abbreviations).bcvToVerseReference(bcvList),
          style: TextStyle(
            color: _config.myColors["black"],
          ),
        ),
        initiallyExpanded: false,
        backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
        children: verseList,
      ),
      ExpansionTile(
        title: originalWord,
        initiallyExpanded: true,
        backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
        children: dataList,
      ),
    ]);
  }

  Widget _buildVerseRow(
      BuildContext context, String text, String module, List bcvList) {
    int book = bcvList[0];
    TextDirection verseDirection =
    ((_config.hebrewBibles.contains(module)) && (_isHebrew))
        ? TextDirection.rtl
        : TextDirection.ltr;
    TextStyle verseFont;
    if ((_config.hebrewBibles.contains(module)) && (_isHebrew)) {
      verseFont = _config.verseTextStyle["verseFontHebrew"];
    } else if (_config.greekBibles.contains(module)) {
      verseFont = _config.verseTextStyle["verseFontGreek"];
    } else {
      verseFont = _config.verseTextStyle["verseFont"];
    }
    List<TextSpan> wordSpans = (_config.interlinearBibles.contains(module))
        ? InterlinearHelper(_config.verseTextStyle)
        .getInterlinearSpan(text, book)
        : <TextSpan>[TextSpan(text: text, style: verseFont)];
    return ListTile(
      title: RichText(
        text: TextSpan(
          //style: DefaultTextStyle.of(context).style,
          children: wordSpans,
        ),
        textDirection: verseDirection,
      ),
      subtitle: Text(
        "[$module]",
        style: TextStyle(
          color: _config.myColors["blue"],
        ),
      ),
      onTap: () {
        Navigator.pop(context, [bcvList, "", module]);
      },
    );
  }

  Widget _buildKeyRow(BuildContext context, String key) {
    TextStyle titleStyle =
    TextStyle(fontSize: (this._config.fontSize - 4), color: Colors.grey);
    TextStyle dataStyle = _config.verseTextStyle["verseFont"];
    if ((key == "Word") || (key == "Lexeme"))
      dataStyle = _config.verseTextStyle["verseFontGreek"];
    if ((_isHebrew) && ((key == "Word") || (key == "Lexeme")))
      dataStyle = _config.verseTextStyle["verseFontHebrew"];
    String data = _wData[key].toString();
    if (data.contains(","))
      data = data.split(",").sublist(0, data.split(",").length - 1).join(", ");

    // add trailing icon & action where it is appropriate
    IconButton trailing;
    if (key == "LexicalEntry") {
      trailing = IconButton(
        tooltip: interface3[_config.abbreviations][0],
        icon: Icon(
          Icons.translate,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          _loadLexiconView(context, _wData["LexicalEntry"]);
        },
      );
    } else if (key == "Word") {
      trailing = IconButton(
        tooltip: interface3[_config.abbreviations][2],
        icon: Icon(
          Icons.volume_up,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          if (_config.plus) {
            String wordText = ((_isHebrew) && (Platform.isAndroid))
                ? TtsHelper().workaroundHebrew(_wData["Transliteration"])
                : _wData["Word"];
            _speak(wordText);
          } else {
            _nonPlusMessage(interface3[_config.abbreviations][2]);
          }
        },
      );
    }

    // add spacing to connected words in key
    RegexHelper _regex = RegexHelper();
    _regex.searchReplace = [
      ['([a-z])([A-Z])', r'\1 \2'],
    ];
    key = _regex.doSearchReplace(key);

    return ListTile(
      title: Text(key, style: titleStyle),
      subtitle: Text(data, style: dataStyle),
      trailing: trailing,
    );
  }

  Future _loadLexiconView(BuildContext context, String lexicalEntries) async {
    List lexicons = await SqliteHelper(_config).getLexicons(lexicalEntries);
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => LexiconView(_config, lexicons, _bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }
}

