import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Bibles.dart';
import 'BibleParser.dart';
import 'config.dart';
import 'Helpers.dart';
import 'HtmlWrapper.dart';

class InterlinearView extends StatefulWidget {
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  final FlutterTts flutterTts;

  InterlinearView(
      this._data, this._firstOpened, this._module, this._config, this._bibles, this.flutterTts);

  @override
  InterlinearViewState createState() => InterlinearViewState(
      this._data, this._firstOpened, this._module, this._config, this._bibles, this.flutterTts);
}

class InterlinearViewState extends State<InterlinearView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  double _fontSize;
  bool _isHebrew;
  String abbreviations;
  final Map interface = {
    "ENG": ["Interlinear", "More", "Audio"],
    "TC": ["原文逐字翻譯", "更多", "語音功能"],
    "SC": ["原文逐字翻译", "更多", "语音功能"],
  };

  // Variables to work with TTS
  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  InterlinearViewState(
      this._data, this._firstOpened, this._module, this._config, this._bibles, this.flutterTts) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
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
  }*/

  /*initTts() {
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

  @override
  Widget build(BuildContext context) {
    var verseRef = "";
    if (_data.isNotEmpty)
      verseRef = BibleParser(this.abbreviations).bcvToVerseReference(
          [_data[0]["Book"], _data[0]["Chapter"], _data[0]["Verse"]]);
    final title = "${interface[this.abbreviations][0]} - $verseRef";
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              tooltip: interface[this.abbreviations][1],
              icon: const Icon(Icons.unfold_more),
              onPressed: () {
                _loadMorphologyView(context);
              },
            ),
          ],
        ),
        body: _buildCardList(context),
      ),
    );
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
                tooltip: interface[this.abbreviations][2],
                icon: Icon(
                  Icons.volume_up,
                  color: _config.myColors["black"],
                ),
                onPressed: () {
                  if (_config.plus) {
                    String wordText = ((_isHebrew) && (Platform.isAndroid))
                        ? TtsHelper().workaroundHebrew(wordData["Transliteration"])
                        : wordData["Word"];
                    _speak(wordText);
                  } else {
                    _nonPlusMessage(interface[this.abbreviations][2]);
                  }
                },
              ),
              title: word,
              subtitle: Text(wordData["Interlinear"], style: textStyle),
              onTap: () {
                _loadLexiconView(context, wordData["LexicalEntry"]);
              },
              trailing: IconButton(
                tooltip: interface[this.abbreviations][1],
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
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WordView(wordData, _module, _config, _bibles, this.flutterTts)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  Future _loadMorphologyView(BuildContext context) async {
    if ((_firstOpened) && (_module != "ABP")) {
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MorphologyView(_data, false, _module, _config, _bibles, this.flutterTts)),
      );
      if (selected != null) Navigator.pop(context, selected);
    } else {
      Navigator.pop(context, null);
    }
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

class MorphologyView extends StatefulWidget {
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  final FlutterTts flutterTts;

  MorphologyView(
      this._data, this._firstOpened, this._module, this._config, this._bibles, this.flutterTts);

  @override
  MorphologyViewState createState() => MorphologyViewState(
      this._data, this._firstOpened, this._module, this._config, this._bibles, this.flutterTts);
}

class MorphologyViewState extends State<MorphologyView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  double _fontSize;
  String abbreviations;
  bool _isHebrew;
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

  // Variables to work with TTS
  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  MorphologyViewState(
      this._data, this._firstOpened, this._module, this._config, this._bibles, this.flutterTts) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
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

  Future searchMorphology(BuildContext context, String lexicalEntry,
      List selectedMorphologyItems) async {
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
      _morphologySearchResults(context, morphology);
      db.close();
    }
  }

  Future _morphologySearchResults(BuildContext context, List morphology) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MorphologySearchResults(
              morphology, this._module, this._config, this._bibles, this.flutterTts)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    var verseRef = "";
    if (_data.isNotEmpty)
      verseRef = BibleParser(this.abbreviations).bcvToVerseReference(
          [_data[0]["Book"], _data[0]["Chapter"], _data[0]["Verse"]]);
    final title = "${interface[this.abbreviations][0]} - $verseRef";
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              tooltip: interface[this.abbreviations][1],
              icon: const Icon(Icons.unfold_less),
              onPressed: () {
                if (_firstOpened) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => InterlinearView(
                            _data, false, _module, _config, _bibles, this.flutterTts)),
                  );
                } else {
                  Navigator.pop(context, null);
                }
              },
            ),
          ],
        ),
        body: _buildCardList(context),
      ),
    );
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
    String lexicalEntry = (wordData["LexicalEntry"].isNotEmpty) ? wordData["LexicalEntry"].split(",").toList()[0] : "";
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
                  color: _config.myColors["black"],
                ),
                onPressed: () {
                  if (_config.plus) {
                    String wordText = ((_isHebrew) && (Platform.isAndroid))
                        ? TtsHelper().workaroundHebrew(wordData["Transliteration"])
                        : wordData["Word"];
                    _speak(wordText);
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
                  color: _config.myColors["black"],
                ),
                onPressed: () {
                  _loadWordView(context, wordData);
                },
              ),
            ),
            ListTile(
              leading: IconButton(
                tooltip: interface[this.abbreviations][5],
                icon: Icon(
                  Icons.label_outline,
                  color: _config.myColors["black"],
                ),
                onPressed: () {
                  searchMorphology(context, lexicalEntry, morphology.split(", "));
                },
              ),
              title: lexeme,
              subtitle: Text(morphology, style: textStyle),
              onTap: () {
                searchMorphology(context, lexicalEntry, morphology.split(", "));
              },
              trailing: IconButton(
                tooltip: interface[this.abbreviations][2],
                icon: Icon(
                  Icons.search,
                  color: _config.myColors["black"],
                ),
                onPressed: () {
                  _loadMorphologySearchView(context, lexemeText,
                      wordData["LexicalEntry"], morphology);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _loadWordView(BuildContext context, Map wordData) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WordView(wordData, _module, _config, _bibles, this.flutterTts)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  Future _loadMorphologySearchView(
      BuildContext context, lexemeText, lexicalEntry, morphology) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MorphologySearchView(lexemeText, lexicalEntry,
              morphology, this._module, this._config, this._bibles, this.flutterTts)),
    );
    if (selected != null) Navigator.pop(context, selected);
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

class MorphologySearchView extends StatefulWidget {
  final String _lexeme, _lexicalEntry, _morphology, _module;
  final Config _config;
  final Bibles _bibles;
  final FlutterTts flutterTts;

  MorphologySearchView(this._lexeme, this._lexicalEntry, this._morphology,
      this._module, this._config, this._bibles, this.flutterTts);

  @override
  MorphologySearchViewState createState() => MorphologySearchViewState(
      this._lexeme,
      this._lexicalEntry,
      this._morphology,
      this._module,
      this._config,
      this._bibles,
      this.flutterTts,
  );
}

class MorphologySearchViewState extends State<MorphologySearchView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final String _lexeme, _lexicalEntry, _morphology, _module;
  final Config _config;
  final Bibles _bibles;
  FlutterTts flutterTts;
  var lexicalEntry = "";
  List<String> morphologyItems, selectedMorphologyItems;

  final Map interface = {
    "ENG": ["Search", "Selective Morphology Search"],
    "TC": ["搜索", "選定形態搜索"],
    "SC": ["搜索", "选订形态搜索"],
  };

  MorphologySearchViewState(this._lexeme, this._lexicalEntry, this._morphology,
      this._module, this._config, this._bibles, this.flutterTts) {
    morphologyItems = _morphology.split(", ").toList();
    selectedMorphologyItems = List<String>.from(morphologyItems);
    if (_lexicalEntry.isNotEmpty)
      this.lexicalEntry = _lexicalEntry.split(",").toList()[0];
  }

  void _nonPlusMessage(String feature) {
    String message =
        "'$feature' ${_config.plusMessage[_config.abbreviations].first}";
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: _config.plusMessage[_config.abbreviations].last,
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
    _morphologySearchResults(context, morphology);
    db.close();
  }

  Future _morphologySearchResults(BuildContext context, List morphology) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MorphologySearchResults(
              morphology, this._module, this._config, this._bibles, this.flutterTts)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("Search"),
          actions: <Widget>[
            IconButton(
              tooltip: interface[_config.abbreviations][0],
              icon: const Icon(Icons.search),
              onPressed: () {
                (_config.plus)
                    ? searchMorphology(context)
                    : _nonPlusMessage(interface[_config.abbreviations][1]);
              },
            ),
          ],
        ),
        body: _buildMorphology(context),
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
}

class MorphologySearchResults extends StatefulWidget {
  final List<Map> _data;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  final FlutterTts flutterTts;

  MorphologySearchResults(this._data, this._module, this._config, this._bibles, this.flutterTts);

  @override
  MorphologySearchResultsState createState() => MorphologySearchResultsState(
      this._data, this._module, this._config, this._bibles, this.flutterTts);
}

class MorphologySearchResultsState extends State<MorphologySearchResults> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final String _module;
  final Config _config;
  final Bibles _bibles;

  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  double _fontSize;
  String abbreviations;
  bool _isHebrew;
  final Map interface = {
    "ENG": ["Found", "words", "More", "Audio"],
    "TC": ["找到", "個字", "更多", "語音功能"],
    "SC": ["找到", "个字", "更多", "语音功能"],
  };

  MorphologySearchResultsState(
      this._data, this._module, this._config, this._bibles, this.flutterTts) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
    this._isHebrew = ((_module == "OHGB") &&
        (_data != null) &&
        (_data.isNotEmpty) &&
        (_data.first["Book"] < 40));
  }

  @override
  Widget build(BuildContext context) {
    final title =
        "${interface[this.abbreviations][0]} ${_data.length} ${interface[this.abbreviations][1]}";
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(title),
        ),
        body: _buildCardList(context),
      ),
    );
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
                  tooltip: interface[this.abbreviations][3],
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
                      _nonPlusMessage(interface[this.abbreviations][3]);
                    }
                  },
                ),
                title: word,
                subtitle: Text(verseReference, style: textStyle),
                onTap: () {
                  Navigator.pop(context, [bcvList, "", _bibles.bible1.module]);
                },
                trailing: IconButton(
                  tooltip: interface[this.abbreviations][2],
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

  Future _loadWordView(BuildContext context, Map wordData) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WordView(wordData, _module, _config, _bibles, this.flutterTts)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }
}

class WordView extends StatefulWidget {
  final Map _data;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  final FlutterTts flutterTts;

  WordView(this._data, this._module, this._config, this._bibles, this.flutterTts);

  @override
  WordViewState createState() =>
      WordViewState(this._data, this._module, this._config, this._bibles, this.flutterTts);
}

class WordViewState extends State<WordView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map _data;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  bool _isHebrew;
  RegexHelper _regex;

  final Map interface = {
    "ENG": ["Lexicon", "Search", "Audio"],
    "TC": ["原文辭典", "搜索", "語音功能"],
    "SC": ["原文词典", "搜索", "语音功能"],
  };

  // Variables to work with TTS
  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  WordViewState(this._data, this._module, this._config, this._bibles, this.flutterTts) {
    this._isHebrew = ((_module == "OHGB") &&
        (_data != null) &&
        (_data.isNotEmpty) &&
        (_data["Book"] < 40));
    // setup regexHelper
    _regex = RegexHelper();
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
        "'$feature' ${_config.plusMessage[_config.abbreviations].first}";
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: _config.plusMessage[_config.abbreviations].last,
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

  @override
  Widget build(BuildContext context) {
    TextSpan originalWord = (_isHebrew)
        ? TextSpan(
            text: _data["Word"],
            style: TextStyle(fontFamily: "Ezra SIL", fontSize: 22.0))
        : TextSpan(text: _data["Word"], style: TextStyle(fontSize: 22.0));
    Widget title = RichText(
        text: TextSpan(children: <TextSpan>[
      TextSpan(
          text: "[${BibleParser(_config.abbreviations).bcvToVerseReference([
            _data["Book"],
            _data["Chapter"],
            _data["Verse"]
          ])}] ",
          style: TextStyle(fontSize: 18.0)),
      originalWord
    ]));
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: title,
        ),
        body: _buildKeys(context),
      ),
    );
  }

  Widget _buildKeys(BuildContext context) {
    Text originalWord = (_isHebrew)
        ? Text(_data["Word"], style: _config.verseTextStyle["verseFontHebrew"])
        : Text(_data["Word"], style: _config.verseTextStyle["verseFontGreek"]);

    List bcvList = [_data["Book"], _data["Chapter"], _data["Verse"]];

    List<Bible> bibleList = [_bibles.bible1, _bibles.bible2, _bibles.iBible];
    List<Widget> verseList = bibleList
        .map((bible) => _buildVerseRow(
            context, bible.openSingleVerse(bcvList), bible.module, bcvList))
        .toList();

    List<String> keys = _data.keys.toList();
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
    TextDirection verseDirection = ((_config.hebrewBibles.contains(module)) && (_isHebrew)) ? TextDirection.rtl : TextDirection.ltr;
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
    String data = _data[key].toString();
    if (data.contains(","))
      data = data.split(",").sublist(0, data.split(",").length - 1).join(", ");

    // add trailing icon & action where it is appropriate
    IconButton trailing;
    if (key == "Morphology") {
      trailing = IconButton(
        tooltip: interface[_config.abbreviations][1],
        icon: Icon(
          Icons.search,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          _loadMorphologySearchView(
              context, _data["Lexeme"], _data["LexicalEntry"], data);
        },
      );
    } else if (key == "LexicalEntry") {
      trailing = IconButton(
        tooltip: interface[_config.abbreviations][0],
        icon: Icon(
          Icons.translate,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          _loadLexiconView(context, _data["LexicalEntry"]);
        },
      );
    } else if (key == "Word") {
      trailing = IconButton(
        tooltip: interface[_config.abbreviations][2],
        icon: Icon(
          Icons.volume_up,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          if (_config.plus) {
            String wordText = ((_isHebrew) && (Platform.isAndroid))
                ? TtsHelper().workaroundHebrew(_data["Transliteration"])
                : _data["Word"];
            _speak(wordText);
          } else {
            _nonPlusMessage(interface[_config.abbreviations][2]);
          }
        },
      );
    }

    // add spacing to connected words in key
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

  Future _loadMorphologySearchView(
      BuildContext context, lexemeText, lexicalEntry, morphology) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MorphologySearchView(lexemeText, lexicalEntry,
              morphology, this._module, this._config, this._bibles, this.flutterTts)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }
}

/*
class LexiconView extends StatefulWidget {
  final List _lexicalEntries;
  final Config _config;
  final Bibles _bibles;

  LexiconView(this._config, this._lexicalEntries, this._bibles);

  @override
  LexiconViewState createState() => LexiconViewState(this._config, this._lexicalEntries, this._bibles);
}

class LexiconViewState extends State<LexiconView> {

  final List _lexicalEntries;
  final Config _config;
  final Bibles _bibles;

  Map interface = {
    "ENG": ["Lexicon"],
    "TC": ["原文辭典"],
    "SC": ["原文词典"],
  };

  LexiconViewState(this._config, this._lexicalEntries, this._bibles);
*/
class LexiconView extends StatelessWidget {
  final List _lexicalEntries;
  final Config _config;
  final Bibles _bibles;

  final Map interface = {
    "ENG": ["Lexicon"],
    "TC": ["原文辭典"],
    "SC": ["原文词典"],
  };

  LexiconView(this._config, this._lexicalEntries, this._bibles);

  List<Widget> formatItem(BuildContext context, Map item) {
    HtmlWrapper _wrapper = HtmlWrapper(_bibles, _config);

    //String _entry = item["Entry"];
    String _lexeme = item["Lexeme"];
    String _transliteration = item["Transliteration"];
    String _morphology = item["Morphology"];
    String _gloss = item["Gloss"];
    String _lexicon = item["Lexicon"];
    String _content = item["Content"];

    Widget headingRichText = Text(
      _lexicon,
      style: TextStyle(color: _config.myColors["grey"]),
    );

    String content =
        "<h>$_lexeme</h><p>Transliteration: $_transliteration<br>Morphology: $_morphology<br>Gloss: $_gloss</p><p>$_content</p>";
    Widget contentRichText = _wrapper.buildRichText(context, content);

    return [headingRichText, contentRichText];
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(interface[_config.abbreviations][0]),
        ),
        body: _buildCardList(context),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(15.0),
        itemCount: _lexicalEntries.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordItem = _lexicalEntries[i];
    final wordData = formatItem(context, wordItem);
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: wordData[1],
              subtitle: wordData[0],
            )
          ],
        ),
      ),
    );
  }
}
